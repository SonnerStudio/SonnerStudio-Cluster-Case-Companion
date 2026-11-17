import json, sys, time, urllib.request
n = int(sys.argv[1]) if len(sys.argv) > 1 else 1600
txt = ("Die Sterne leuchten über dem Atelier von SonnerStudio, und jede Nacht entstehen neue Entwürfe. " * n)
body = {"model":"qwen3.8","max_tokens":30,"temperature":0,"chat_template_kwargs":{"enable_thinking":False},
        "messages":[{"role":"user","content":txt + "\nFasse den Text in einem Satz zusammen."}]}
t=time.time()
try:
    r = json.load(urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:8000/v1/chat/completions", json.dumps(body).encode(), {"Content-Type":"application/json"}), timeout=900))
    print(f"OK: {r['usage']['prompt_tokens']} Prompt-Token in {time.time()-t:.0f}s")
except Exception as e:
    print("ABBRUCH:", type(e).__name__)
