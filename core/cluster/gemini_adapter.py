"""Gemini-API-Schnittstelle für das SS-CCC-Gateway (für Google Antigravity).

Antigravity spricht für eigene Modelle nur das Gemini-Protokoll
(POST /v1beta/models/<modell>:streamGenerateContent?alt=sse). Dieses Modul übersetzt
Gemini-Anfragen in OpenAI-Chat-Anfragen an das SS-CCC-Sprachmodell und die Antworten
(Text, Denkschritte, Werkzeugaufrufe, Token-Zählung) zurück ins Gemini-Format.
"""

import json
import os
import time
import uuid

import httpx
from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse, StreamingResponse

router = APIRouter()
_cfg: dict = {}   # wird vom Gateway gesetzt: pick_target (async), client, log, model_name


def configure(**kw):
    _cfg.update(kw)


# ── Gemini → OpenAI ──────────────────────────────────────────────────────────
def _schema(s):
    """Gemini-OpenAPI-Schema (Typen in Großbuchstaben) in JSON-Schema umwandeln."""
    if isinstance(s, dict):
        out = {}
        for k, v in s.items():
            if k == "type" and isinstance(v, str):
                out[k] = v.lower()
            elif k in ("$schema",):
                continue
            else:
                out[k] = _schema(v)
        return out
    if isinstance(s, list):
        return [_schema(x) for x in s]
    return s


def gemini_to_openai(body: dict) -> dict:
    msgs = []
    sys_parts = (body.get("systemInstruction") or body.get("system_instruction") or {}).get("parts", [])
    sys_text = "\n".join(p.get("text", "") for p in sys_parts if p.get("text"))
    if sys_text:
        msgs.append({"role": "system", "content": sys_text})

    pending_ids: dict[str, list[str]] = {}   # Funktionsname -> offene Aufruf-IDs
    for c in body.get("contents", []):
        role = c.get("role", "user")
        parts = c.get("parts", [])
        # Antigravity schickt Werkzeugergebnisse (functionResponse) mit Rolle "model"
        # → solche Inhalte wie Nutzer-/Werkzeugteile behandeln.
        if role == "model" and not any(p.get("functionResponse") or p.get("function_response") for p in parts):
            text = "".join(p.get("text", "") for p in parts if p.get("text") and not p.get("thought"))
            calls = []
            for p in parts:
                fc = p.get("functionCall") or p.get("function_call")
                if fc:
                    cid = fc.get("id") or f"call_{uuid.uuid4().hex[:12]}"
                    pending_ids.setdefault(fc["name"], []).append(cid)
                    calls.append({"id": cid, "type": "function", "function": {
                        "name": fc["name"], "arguments": json.dumps(fc.get("args") or {}, ensure_ascii=False)}})
            m = {"role": "assistant", "content": text or None}
            if calls:
                m["tool_calls"] = calls
            msgs.append(m)
            continue
        # Nutzer- bzw. Funktionsantwort-Teile
        content = []
        for p in parts:
            fr = p.get("functionResponse") or p.get("function_response")
            if fr:
                ids = pending_ids.get(fr.get("name"), [])
                cid = fr.get("id") or (ids.pop(0) if ids else f"call_{uuid.uuid4().hex[:12]}")
                resp = fr.get("response")
                msgs.append({"role": "tool", "tool_call_id": cid,
                             "content": resp if isinstance(resp, str) else json.dumps(resp, ensure_ascii=False)})
            elif p.get("text") and not p.get("thought"):
                content.append({"type": "text", "text": p["text"]})
            elif p.get("inlineData") or p.get("inline_data"):
                d = p.get("inlineData") or p.get("inline_data")
                mime = d.get("mimeType") or d.get("mime_type") or ""
                if mime.startswith("image/"):
                    content.append({"type": "image_url", "image_url": {"url": f"data:{mime};base64,{d.get('data', '')}"}})
                else:
                    content.append({"type": "text", "text": f"[Anhang {mime} wird vom lokalen Modell nicht gelesen]"})
        if content:
            if all(x["type"] == "text" for x in content):
                msgs.append({"role": "user", "content": "\n".join(x["text"] for x in content)})
            else:
                msgs.append({"role": "user", "content": content})

    out = {"model": _cfg.get("model_name", "ssccc"), "messages": msgs}
    tools = []
    for t in body.get("tools") or []:
        for f in t.get("functionDeclarations") or t.get("function_declarations") or []:
            params = f.get("parametersJsonSchema") or f.get("parameters") or {"type": "object", "properties": {}}
            tools.append({"type": "function", "function": {
                "name": f["name"], "description": f.get("description", ""), "parameters": _schema(params)}})
    if tools:
        out["tools"] = tools
    g = body.get("generationConfig") or {}
    if g.get("maxOutputTokens"):
        out["max_tokens"] = min(int(g["maxOutputTokens"]), 32768)
    for a, b in (("temperature", "temperature"), ("topP", "top_p")):
        if a in g:
            out[b] = g[a]
    if g.get("stopSequences"):
        out["stop"] = g["stopSequences"]
    th = g.get("thinkingConfig") or {}
    think = bool(th.get("includeThoughts")) and th.get("thinkingBudget", -1) != 0
    out["chat_template_kwargs"] = {"enable_thinking": think}
    return out


# ── OpenAI → Gemini ──────────────────────────────────────────────────────────
def _chunk(parts=None, finish=None, usage=None, model=""):
    cand = {"content": {"role": "model", "parts": parts or []}, "index": 0}
    if finish:
        cand["finishReason"] = finish
    out = {"candidates": [cand], "modelVersion": model, "responseId": uuid.uuid4().hex[:16]}
    if usage:
        out["usageMetadata"] = {"promptTokenCount": usage.get("prompt_tokens", 0),
                                "candidatesTokenCount": usage.get("completion_tokens", 0),
                                "totalTokenCount": usage.get("total_tokens", 0)}
    return out


def _calls_to_parts(calls: dict) -> list:
    parts = []
    for c in sorted(calls.values(), key=lambda x: x["i"]):
        try:
            args = json.loads(c["args"] or "{}")
        except json.JSONDecodeError:
            args = {"_raw": c["args"]}
        parts.append({"functionCall": {"name": c["name"], "args": args, "id": c["id"]}})
    return parts


async def _openai_stream(req_body: dict):
    target, target_model = await _cfg["pick_target"]()
    req_body = dict(req_body, model=target_model, stream=True, stream_options={"include_usage": True})
    client: httpx.AsyncClient = _cfg["client"]
    async with client.stream("POST", f"{target}/v1/chat/completions", json=req_body) as r:
        if r.status_code != 200:
            err = (await r.aread()).decode(errors="ignore")[:500]
            raise RuntimeError(f"Sprachmodell antwortet mit {r.status_code}: {err}")
        async for line in r.aiter_lines():
            line = line.strip()
            if line.startswith("data:") and not line.endswith("[DONE]"):
                try:
                    yield json.loads(line[5:])
                except json.JSONDecodeError:
                    continue


class GuardRejected(Exception):
    def __init__(self, message: str):
        super().__init__(message)


async def _gemini_events(body: dict):
    req = gemini_to_openai(body)
    guard = _cfg.get("guard")
    if guard:
        rejected, _info = guard(req)
        if rejected is not None:
            raise GuardRejected(json.loads(rejected.body)["error"]["message"])
    if _cfg.get("on_start"):
        _cfg["on_start"]()
    try:
        async for ev in _gemini_events_inner(req):
            yield ev
    finally:
        if _cfg.get("on_finish"):
            _cfg["on_finish"]()


async def _gemini_events_inner(req: dict):
    model = _cfg.get("model_name", "ssccc")
    calls: dict = {}
    usage = None
    finish = "STOP"
    async for d in _openai_stream(req):
        if d.get("usage"):
            usage = d["usage"]
        for ch in d.get("choices") or []:
            delta = ch.get("delta") or {}
            r = delta.get("reasoning") or delta.get("reasoning_content")
            if r:
                yield _chunk([{"text": r, "thought": True}], model=model)
            if delta.get("content"):
                yield _chunk([{"text": delta["content"]}], model=model)
            for tc in delta.get("tool_calls") or []:
                i = tc.get("index", 0)
                c = calls.setdefault(i, {"i": i, "id": tc.get("id") or f"call_{uuid.uuid4().hex[:12]}",
                                         "name": "", "args": ""})
                f = tc.get("function") or {}
                c["name"] += f.get("name") or ""
                c["args"] += f.get("arguments") or ""
            if ch.get("finish_reason") == "length":
                finish = "MAX_TOKENS"
    yield _chunk(_calls_to_parts(calls), finish=finish, usage=usage or {}, model=model)


def _model_from_path(path: str) -> tuple[str, str]:
    name, _, action = path.rpartition(":")
    return name, action


@router.post("/v1beta/models/{path:path}")
@router.post("/v1/models/{path:path}")
async def gemini_models(path: str, request: Request):
    _, action = _model_from_path(path)
    body = await request.json()
    log = _cfg.get("log", print)
    if action == "countTokens":
        text = json.dumps(body, ensure_ascii=False)
        return {"totalTokens": max(1, len(text) // 4)}
    if os.environ.get("SSCCC_GEMINI_DEBUG"):
        open("/Users/Shared/ssccc/last_gemini.json", "w").write(json.dumps(body, ensure_ascii=False))
    if action == "streamGenerateContent":
        n_tools = sum(len(t.get("functionDeclarations") or []) for t in body.get("tools") or [])
        log(f"Gemini-Anfrage (Antigravity) mit {len(body.get('contents', []))} Nachrichten, {n_tools} Werkzeugen")

        async def sse():
            try:
                async for ev in _gemini_events(body):
                    yield f"data: {json.dumps(ev, ensure_ascii=False)}\r\n\r\n"
            except Exception as e:
                log(f"Gemini-Fehler: {e}")
                err = {"error": {"code": 500, "message": str(e)[:500], "status": "INTERNAL"}}
                yield f"data: {json.dumps(err)}\r\n\r\n"
        return StreamingResponse(sse(), media_type="text/event-stream")
    if action == "generateContent":
        parts, usage, finish = [], {}, "STOP"
        text = ""
        async for ev in _gemini_events(body):
            c = ev["candidates"][0]
            for p in c["content"]["parts"]:
                if "text" in p and not p.get("thought"):
                    text += p["text"]
                elif "functionCall" in p:
                    parts.append(p)
            finish = c.get("finishReason", finish)
            if ev.get("usageMetadata"):
                usage = ev["usageMetadata"]
        if text:
            parts.insert(0, {"text": text})
        return {"candidates": [{"content": {"role": "model", "parts": parts}, "finishReason": finish, "index": 0}],
                "usageMetadata": usage, "modelVersion": _cfg.get("model_name", "")}
    return JSONResponse({"error": {"code": 404, "message": f"Unbekannte Aktion {action}", "status": "NOT_FOUND"}}, 404)


@router.get("/v1beta/models")
async def gemini_list():
    m = _cfg.get("model_name", "ssccc")
    return {"models": [{"name": "models/ssccc", "displayName": f"SS-CCC ({m})",
                        "supportedGenerationMethods": ["generateContent", "streamGenerateContent", "countTokens"],
                        "inputTokenLimit": 65536, "outputTokenLimit": 32768}]}
