"""Speicherwarnung vor großen Anfragen.

Schätzt vor dem Weiterreichen, wie viele Token eine Chat-Anfrage braucht und wie viel
GPU-Speicher ihr KV-Cache belegt. Damit lässt sich eine Anfrage, die nicht passen
kann, mit einer klaren Fehlermeldung ablehnen (OpenAI-Fehlercode
`context_length_exceeded` – Clients wie Hermes/OpenCode verdichten dann den Verlauf),
statt das Sprachmodell in einen GPU-Speicherfehler laufen zu lassen.

Große Anfragen werden zusätzlich nacheinander statt parallel verarbeitet (im Betrieb
lief der Speicher über, als eine 89k-Token-Anfrage parallel zu weiteren lief).
"""

import json
from dataclasses import dataclass


@dataclass
class Limits:
    context: int = 131072            # maximale Tokenzahl (Prompt + Antwort)
    default_output: int = 4096       # angenommene Antwortlänge ohne max_tokens
    large_prompt: int = 32768        # ab hier: „große Anfrage“ – nur eine gleichzeitig
    kv_bytes_per_token: float = 0.0  # 0 = Speicherprüfung aus
    headroom_bytes: int = 2 << 30    # Sicherheitsreserve im GPU-Speicher


def _text_of(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        out = []
        for part in content:
            if isinstance(part, dict):
                if part.get("type") == "text":
                    out.append(part.get("text", ""))
                elif part.get("type") in ("image_url", "input_image"):
                    out.append(" " * 4000)          # Bild ≈ 1000 Token
            elif isinstance(part, str):
                out.append(part)
        return "\n".join(out)
    return "" if content is None else json.dumps(content, ensure_ascii=False)


def prompt_text(body: dict) -> str:
    """Gesamter Text, den das Modell als Prompt sieht (Nachrichten + Werkzeuge)."""
    parts = []
    for m in body.get("messages") or []:
        parts.append(_text_of(m.get("content")))
        for tc in m.get("tool_calls") or []:
            parts.append(json.dumps(tc.get("function", {}), ensure_ascii=False))
    if isinstance(body.get("input"), (str, list)):          # /v1/responses
        parts.append(_text_of(body["input"]))
    if body.get("instructions"):
        parts.append(str(body["instructions"]))
    if body.get("tools"):
        parts.append(json.dumps(body["tools"], ensure_ascii=False))
    return "\n".join(parts)


def estimate_tokens(body: dict, tokenizer=None) -> int:
    """Token des Prompts – exakt mit Tokenizer, sonst ~3,6 Zeichen pro Token."""
    text = prompt_text(body)
    if tokenizer is not None:
        try:
            return len(tokenizer.encode(text))
        except Exception:
            pass
    return int(len(text) / 3.6) + 16 * len(body.get("messages") or [])


def requested_output(body: dict, limits: Limits) -> int:
    for key in ("max_tokens", "max_completion_tokens", "max_output_tokens"):
        if body.get(key):
            return int(body[key])
    return limits.default_output


def check(body: dict, prompt_tokens: int, limits: Limits, free_gpu_bytes: int | None = None):
    """Gibt (ok, fehler_dict | None, info) zurück."""
    out = requested_output(body, limits)
    total = prompt_tokens + out
    info = {"prompt_tokens": prompt_tokens, "max_output": out, "total": total,
            "large": prompt_tokens >= limits.large_prompt}
    if prompt_tokens >= limits.context:
        return False, _error(
            f"Die Anfrage hat etwa {prompt_tokens} Token, das lokale Modell verarbeitet höchstens "
            f"{limits.context}. Bitte den Verlauf verdichten oder kürzen.", "context_length_exceeded"), info
    if total > limits.context:
        # Antwortlänge an den verbleibenden Platz anpassen statt abzulehnen
        info["clamped_output"] = max(256, limits.context - prompt_tokens)
    if free_gpu_bytes is not None and limits.kv_bytes_per_token > 0:
        need = int(min(total, limits.context) * limits.kv_bytes_per_token) + limits.headroom_bytes
        info["kv_need_bytes"] = need
        info["gpu_free_bytes"] = free_gpu_bytes
        if need > free_gpu_bytes:
            return False, _error(
                f"Für diese Anfrage (~{prompt_tokens} Token) reicht der freie GPU-Speicher gerade nicht "
                f"({free_gpu_bytes / 2**30:.1f} GB frei, ~{need / 2**30:.1f} GB nötig). Bitte kürzen oder später erneut versuchen.",
                "insufficient_memory", status=503), info
    return True, None, info


def _error(message: str, code: str, status: int = 400) -> dict:
    return {"status": status, "body": {"error": {"message": message, "type": "invalid_request_error"
                                                 if status == 400 else "server_error", "code": code}}}


def kv_bytes_per_token(config: dict, kv_bits: int) -> float:
    """KV-Cache-Bytes je Token aus der Modellkonfiguration (Hybridmodelle: nur volle Attention)."""
    c = config.get("text_config", config)
    layers = int(c.get("num_hidden_layers", 0))
    interval = int(c.get("full_attention_interval", 1) or 1)
    full = layers // interval if interval > 1 else layers
    kv_heads = int(c.get("num_key_value_heads", c.get("num_attention_heads", 0)))
    head_dim = int(c.get("head_dim") or (c.get("hidden_size", 0) // max(1, c.get("num_attention_heads", 1))))
    bytes_per_val = kv_bits / 8 if kv_bits else 2
    return full * kv_heads * head_dim * 2 * bytes_per_val
