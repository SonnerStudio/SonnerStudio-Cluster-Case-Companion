import json, sys, time, urllib.request
def run(n=256):
    body = {"model":"qwen3.8","stream":True,"max_tokens":n,"temperature":0,
            "chat_template_kwargs":{"enable_thinking":False},
            "messages":[{"role":"user","content":"Schreibe einen ausführlichen Text über die Geschichte der Astronomie."}]}
    req = urllib.request.Request("http://127.0.0.1:8000/v1/chat/completions", json.dumps(body).encode(), {"Content-Type":"application/json"})
    t0=time.time(); first=None; k=0
    with urllib.request.urlopen(req, timeout=900) as r:
        for line in r:
            line=line.decode().strip()
            if not line.startswith("data:") or line.endswith("[DONE]"): continue
            d=json.loads(line[5:])
            if d["choices"] and d["choices"][0]["delta"].get("content"):
                k+=1; first = first or time.time()
    t1=time.time(); return first-t0, (k-1)/(t1-first)
runs=[run() for _ in range(2)]
print("TTFT %.2fs | Decode %.2f tok/s (Mittel aus 2 Läufen: %s)" % (runs[-1][0], sum(r[1] for r in runs)/2, [round(r[1],2) for r in runs]))
