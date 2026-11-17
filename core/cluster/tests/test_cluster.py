"""Tests für den SS-CCC-Server-Teil (ohne GPU, ohne echtes Sprachmodell).

Aufruf:  /Users/Shared/ssccc/venv/bin/python -m pytest core/cluster/tests -q
"""

import asyncio
import importlib
import json
import os
import sys
from pathlib import Path

import httpx
import pytest

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))

import gemini_adapter  # noqa: E402
import image_queue  # noqa: E402
import request_guard  # noqa: E402


# ── Speicherwarnung ──────────────────────────────────────────────────────────
def _body(chars: int, max_tokens=None):
    b = {"model": "x", "messages": [{"role": "user", "content": "a" * chars}]}
    if max_tokens:
        b["max_tokens"] = max_tokens
    return b


def test_guard_accepts_normal_request():
    lim = request_guard.Limits(context=1000)
    ok, err, info = request_guard.check(_body(100), 100, lim)
    assert ok and err is None and not info["large"]


def test_guard_rejects_prompt_over_context():
    lim = request_guard.Limits(context=1000)
    ok, err, _ = request_guard.check(_body(10), 1200, lim)
    assert not ok and err["status"] == 400
    assert err["body"]["error"]["code"] == "context_length_exceeded"


def test_guard_clamps_output_to_remaining_context():
    lim = request_guard.Limits(context=1000)
    ok, _, info = request_guard.check(_body(10, max_tokens=900), 600, lim)
    assert ok and info["clamped_output"] == 400


def test_guard_rejects_when_gpu_memory_too_small():
    lim = request_guard.Limits(context=100000, kv_bytes_per_token=100_000, headroom_bytes=0)
    ok, err, info = request_guard.check(_body(10, max_tokens=10), 50000, lim, free_gpu_bytes=1 << 30)
    assert not ok and err["status"] == 503 and err["body"]["error"]["code"] == "insufficient_memory"


def test_guard_marks_large_requests():
    lim = request_guard.Limits(context=200000, large_prompt=32768)
    assert request_guard.check(_body(10), 40000, lim)[2]["large"]


def test_estimate_tokens_counts_tools_and_messages():
    body = {"messages": [{"role": "user", "content": "x" * 3600}],
            "tools": [{"type": "function", "function": {"name": "f", "description": "y" * 360}}]}
    assert 1000 <= request_guard.estimate_tokens(body) <= 1200


def test_kv_bytes_hybrid_model():
    conf = {"text_config": {"num_hidden_layers": 64, "full_attention_interval": 4, "num_key_value_heads": 4,
                            "head_dim": 256, "num_attention_heads": 24, "hidden_size": 5120}}
    # 16 volle Attention-Schichten * 4 KV-Köpfe * 256 * (K+V) * 1 Byte (8 Bit)
    assert request_guard.kv_bytes_per_token(conf, 8) == 16 * 4 * 256 * 2 * 1


# ── Bild-Warteschlange ───────────────────────────────────────────────────────
class FakeClock:
    def __init__(self):
        self.t = 1000.0

    def __call__(self):
        return self.t


def test_queue_waits_for_idle():
    clk = FakeClock()
    q = image_queue.ImageScheduler(idle_s=30, max_wait_s=300, clock=clk)
    q.chat_started()
    assert not q.may_start(0)          # Chat läuft
    q.chat_finished()
    clk.t += 10
    assert not q.may_start(10)         # erst 10 s Leerlauf
    clk.t += 25
    assert q.may_start(35)             # 35 s Leerlauf


def test_queue_max_wait_overrides_busy_chat():
    clk = FakeClock()
    q = image_queue.ImageScheduler(idle_s=30, max_wait_s=300, clock=clk)
    q.chat_started()
    assert q.may_start(301)


def test_queue_urgent_does_not_wait():
    q = image_queue.ImageScheduler(idle_s=3600, max_wait_s=3600)
    q.chat_started()
    waited = asyncio.run(q.wait_turn(poll=0.01, urgent=True))
    assert waited < 1 and q.waiting == 0


# ── Gemini-Übersetzung (Antigravity) ─────────────────────────────────────────
def test_gemini_function_response_with_model_role():
    """Antigravity schickt Werkzeugergebnisse mit Rolle "model" (im Betrieb gefunden)."""
    body = {"systemInstruction": {"parts": [{"text": "SYS"}]},
            "contents": [
                {"role": "user", "parts": [{"text": "Lies notiz.txt"}]},
                {"role": "model", "parts": [{"functionCall": {"name": "read_file", "args": {"Path": "/x"}, "id": "c1"}}]},
                {"role": "model", "parts": [{"functionResponse": {"name": "read_file", "id": "c1",
                                                                   "response": {"output": "Testinhalt"}}}]}],
            "tools": [{"functionDeclarations": [{"name": "read_file", "parametersJsonSchema": {
                "$schema": "x", "type": "object", "properties": {"Path": {"type": "string"}}}}]}],
            "generationConfig": {"maxOutputTokens": 65536, "thinkingConfig": {"includeThoughts": True, "thinkingBudget": -1}}}
    out = gemini_adapter.gemini_to_openai(body)
    roles = [m["role"] for m in out["messages"]]
    assert roles == ["system", "user", "assistant", "tool"]
    assert out["messages"][2]["tool_calls"][0]["id"] == "c1"
    assert out["messages"][3]["tool_call_id"] == "c1" and "Testinhalt" in out["messages"][3]["content"]
    assert "$schema" not in out["tools"][0]["function"]["parameters"]
    assert out["max_tokens"] == 32768 and out["chat_template_kwargs"]["enable_thinking"] is True


def test_gemini_uppercase_schema_types():
    body = {"contents": [{"role": "user", "parts": [{"text": "hi"}]}],
            "tools": [{"functionDeclarations": [{"name": "f", "parameters": {"type": "OBJECT",
                                                                               "properties": {"a": {"type": "STRING"}}}}]}]}
    p = gemini_adapter.gemini_to_openai(body)["tools"][0]["function"]["parameters"]
    assert p["type"] == "object" and p["properties"]["a"]["type"] == "string"


def test_gemini_stream_events_with_tool_call():
    async def fake_stream(req):
        yield {"choices": [{"delta": {"content": "Hallo"}}]}
        yield {"choices": [{"delta": {"tool_calls": [{"index": 0, "id": "t1", "function": {"name": "f", "arguments": '{"a":'}}]}}]}
        yield {"choices": [{"delta": {"tool_calls": [{"index": 0, "function": {"arguments": ' 1}'}}]}, "finish_reason": "tool_calls"}],
               "usage": {"prompt_tokens": 5, "completion_tokens": 3, "total_tokens": 8}}

    gemini_adapter.configure(model_name="test")
    orig = gemini_adapter._openai_stream
    gemini_adapter._openai_stream = fake_stream
    try:
        async def collect():
            return [ev async for ev in gemini_adapter._gemini_events({"contents": [{"role": "user", "parts": [{"text": "x"}]}]})]
        events = asyncio.run(collect())
    finally:
        gemini_adapter._openai_stream = orig
    assert events[0]["candidates"][0]["content"]["parts"][0]["text"] == "Hallo"
    last = events[-1]
    assert last["candidates"][0]["finishReason"] == "STOP"
    assert last["candidates"][0]["content"]["parts"][0]["functionCall"] == {"name": "f", "args": {"a": 1}, "id": "t1"}
    assert last["usageMetadata"]["totalTokenCount"] == 8


# ── Gateway mit gefälschtem Sprachmodell ─────────────────────────────────────
@pytest.fixture()
def gateway(tmp_path, monkeypatch):
    (tmp_path / "cluster.json").write_text(json.dumps({
        "api_key": "geheim", "image": {"enabled": False}, "reserve": {"enabled": False},
        "llm": {"repo": "test/modell", "draft_repo": "", "context": 1000}}))
    monkeypatch.setenv("SSCCC_HOME", str(tmp_path))
    monkeypatch.setenv("SSCCC_LLM_MODEL", str(tmp_path / "modell"))
    import ssccc_config
    importlib.reload(ssccc_config)
    gw = importlib.import_module("ssccc_gateway")
    gw = importlib.reload(gw)
    seen = []

    def upstream(request: httpx.Request):
        body = json.loads(request.content or b"{}")
        seen.append(body)
        return httpx.Response(200, json={"choices": [{"message": {"content": "ok"}}],
                                         "usage": {"completion_tokens": 1}, "model": body.get("model")})

    async def fake_start():
        gw._llm_ready.set()

    monkeypatch.setattr(gw, "start_llm", fake_start)
    monkeypatch.setattr(gw, "_status_loop", lambda: asyncio.sleep(0))
    monkeypatch.setattr(gw, "_watchdog", lambda: asyncio.sleep(0))
    monkeypatch.setattr(gw, "_load_tokenizer", lambda: None)
    gw._client = httpx.AsyncClient(transport=httpx.MockTransport(upstream))
    gw.gemini_adapter.configure(client=gw._client)
    from fastapi.testclient import TestClient
    with TestClient(gw.app) as c:
        yield c, seen, gw


AUTH = {"Authorization": "Bearer geheim"}


def test_gateway_health_needs_no_key(gateway):
    c, _, _ = gateway
    assert c.get("/health").status_code == 200


def test_gateway_rejects_missing_key(gateway):
    c, _, _ = gateway
    r = c.post("/v1/chat/completions", json={"model": "x", "messages": [{"role": "user", "content": "hi"}]})
    assert r.status_code == 401 and r.json()["error"]["code"] == "invalid_api_key"


def test_gateway_accepts_all_key_headers(gateway):
    c, _, _ = gateway
    for h in (AUTH, {"x-api-key": "geheim"}, {"x-goog-api-key": "geheim"}):
        assert c.get("/v1/models", headers=h).status_code == 200


def test_gateway_models_have_context_window(gateway):
    c, _, _ = gateway
    m = c.get("/v1/models", headers=AUTH).json()["data"][0]
    assert m["context_window"] == 1000 and m["max_output_tokens"] > 0


def test_gateway_pins_model_name(gateway):
    c, seen, gw = gateway
    r = c.post("/v1/chat/completions", headers=AUTH,
               json={"model": "irgendwas", "messages": [{"role": "user", "content": "hi"}]})
    assert r.status_code == 200 and seen[-1]["model"] == gw.LLM_MODEL


def test_gateway_rejects_too_large_request(gateway):
    c, seen, _ = gateway
    n = len(seen)
    r = c.post("/v1/chat/completions", headers=AUTH,
               json={"model": "x", "messages": [{"role": "user", "content": "w" * 20000}]})
    assert r.status_code == 400 and r.json()["error"]["code"] == "context_length_exceeded"
    assert len(seen) == n            # nicht an das Modell weitergereicht


def test_gateway_metrics_count_requests(gateway):
    c, _, _ = gateway
    c.post("/v1/chat/completions", headers=AUTH, json={"model": "x", "messages": [{"role": "user", "content": "hi"}]})
    m = c.get("/ssccc/metrics", headers=AUTH).json()
    assert m["counters"]["requests"] >= 1 and m["queue"]["active_chats"] == 0 and "memory" in m


def test_gateway_gemini_endpoint(gateway):
    c, seen, _ = gateway

    async def fake_stream(req):
        yield {"choices": [{"delta": {"content": "Antwort"}}]}
    orig = gateway[2].gemini_adapter._openai_stream
    gateway[2].gemini_adapter._openai_stream = fake_stream
    try:
        r = c.post("/v1beta/models/ssccc:streamGenerateContent?alt=sse", headers={"x-goog-api-key": "geheim"},
                   json={"contents": [{"role": "user", "parts": [{"text": "hi"}]}]})
    finally:
        gateway[2].gemini_adapter._openai_stream = orig
    assert r.status_code == 200 and "Antwort" in r.text


def test_gateway_mode_rejects_verbund_without_worker(gateway):
    c, _, _ = gateway
    assert c.post("/ssccc/mode", headers=AUTH, json={"mode": "verbund"}).status_code == 400
    assert c.post("/ssccc/mode", headers=AUTH, json={"mode": "unsinn"}).status_code == 400


# ── Konfiguration und Einrichtung ────────────────────────────────────────────
def test_config_merges_defaults(tmp_path, monkeypatch):
    (tmp_path / "cluster.json").write_text(json.dumps({"worker": {"ssh": "w"}, "llm": {"context": 5}}))
    monkeypatch.setenv("SSCCC_HOME", str(tmp_path))
    import ssccc_config
    importlib.reload(ssccc_config)
    c = ssccc_config.load()
    assert c["worker"]["ssh"] == "w" and c["llm"]["context"] == 5
    assert c["llm"]["repo"] and c["gateway_port"] == 8000
    assert "SSCCC_WORKER_SSH='w'" in ssccc_config.shell_env(c)


def test_setup_recommended_wired_limit():
    import ssccc_setup
    assert ssccc_setup.recommended_wired_mb(16) == 12 * 1024
    assert ssccc_setup.recommended_wired_mb(36) == 30 * 1024
    assert ssccc_setup.recommended_wired_mb(128) == 120 * 1024
