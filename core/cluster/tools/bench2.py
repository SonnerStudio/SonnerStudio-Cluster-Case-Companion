import json, sys, time, urllib.request
URL, MODEL = sys.argv[1], sys.argv[2]
def run(n=256):
    body = {"model": MODEL, "stream": True, "max_tokens": n, "temperature": 0,
            "chat_template_kwargs": {"enable_thinking": False},
            "messages": [{"role": "user", "content": "Schreibe einen ausführlichen Text über die Geschichte der Astronomie."}]}
    req = urllib.request.Request(URL + "/v1/chat/completions", json.dumps(body).encode(), {"Content-Type": "application/json"})
    t0 = time.time(); first = None; text = ""
    with urllib.request.urlopen(req, timeout=900) as r:
        for line in r:
            line = line.decode().strip()
            if not line.startswith("data:") or line.endswith("[DONE]"): continue
            d = json.loads(line[5:])
            c = d["choices"][0]["delta"].get("content") if d.get("choices") else None
            if c:
                text += c; first = first or time.time()
    t1 = time.time()
    return first - t0, t1 - first, text
ttft, dt, text = run()
ntok = len(text) / 3.6  # Näherung; genaue Zählung unten
try:
    from transformers import AutoTokenizer
except Exception:
    AutoTokenizer = None
print(f"TTFT {ttft:.2f}s | {len(text)} Zeichen in {dt:.1f}s -> {len(text)/dt:.0f} Zeichen/s")
