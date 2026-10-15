#!/usr/bin/env python3
"""VirusTotal for the scanner (apps/virustotal and its bar module). One JSON
object per command.

    virustotal.py scan <target>     a sha256, a URL or a file path: what VirusTotal knows
                                    {"ok", "known", "kind", "target", "sha256", "name", "size",
                                     "stats", "reputation", "detections", "link"}
                                    a file it has never seen: {"ok", "known": false, "sha256", "size"}
    virustotal.py upload <path>     sends a file (up to 32 MB) and waits for the verdict; same reply

The key comes from VIRUSTOTAL_API_KEY or ~/.config/secrets/env. Only
`upload` sends a file's contents, and the shell asks before it does.
Errors: {"ok": false, "error": "..."}."""
import base64, hashlib, json, os, re, sys, time, urllib.error, urllib.parse, urllib.request, uuid
from pathlib import Path

API = "https://www.virustotal.com/api/v3"
GUI = "https://www.virustotal.com/gui"
SECRETS = Path.home() / ".config/secrets/env"
MAX_UPLOAD = 32 * 1024 * 1024
WAIT = 90                                   # seconds a fresh analysis may take
STATS = ("malicious", "suspicious", "undetected", "harmless", "timeout")

KEY = ""


class NotFound(Exception):
    pass


def out(obj):
    print(json.dumps(obj))
    sys.exit(0 if obj.get("ok") else 1)


def fail(msg):
    out({"ok": False, "error": msg})


def key():
    if os.environ.get("VIRUSTOTAL_API_KEY"):
        return os.environ["VIRUSTOTAL_API_KEY"]
    try:
        m = re.search(r'^(?:export\s+)?VIRUSTOTAL_API_KEY=["\']?([^"\'\n]+)', SECRETS.read_text(), re.M)
    except OSError:
        m = None
    if not m:
        fail("no VIRUSTOTAL_API_KEY in ~/.config/secrets/env")
    return m.group(1).strip()


def call(method, path, body=None, headers=None):
    req = urllib.request.Request(API + path, data=body, method=method)
    req.add_header("x-apikey", KEY)
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            raise NotFound()
        if e.code in (401, 403):
            raise RuntimeError("VirusTotal refuses the API key")
        if e.code == 429:
            raise RuntimeError("too many requests: the free key allows 4 a minute")
        try:
            msg = json.loads(e.read())["error"]["message"]
        except Exception:
            msg = f"HTTP {e.code}"
        raise RuntimeError(msg)
    except urllib.error.URLError as e:
        raise RuntimeError(f"no connection to VirusTotal: {e.reason}")


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def wait_analysis(aid):
    end = time.time() + WAIT
    while True:
        attrs = call("GET", f"/analyses/{aid}")["data"]["attributes"]
        if attrs.get("status") == "completed":
            return attrs
        if time.time() > end:
            raise RuntimeError("VirusTotal is still analysing: look again in a minute")
        time.sleep(3)


def report(kind, target, sha, attrs, link):
    stats = attrs.get("last_analysis_stats") or attrs.get("stats") or {}
    results = attrs.get("last_analysis_results") or attrs.get("results") or {}
    found = [{"engine": e, "category": r.get("category"), "result": r.get("result") or ""}
             for e, r in results.items() if r.get("category") in ("malicious", "suspicious")]
    found.sort(key=lambda d: (d["category"] != "malicious", d["engine"]))
    return {"ok": True, "known": True, "kind": kind, "target": target, "sha256": sha,
            "name": attrs.get("meaningful_name") or attrs.get("url") or target,
            "size": attrs.get("size"), "stats": {k: stats.get(k, 0) for k in STATS},
            "reputation": attrs.get("reputation"), "detections": found[:50], "link": link}


def file_lookup(sha, target, size):
    try:
        attrs = call("GET", f"/files/{sha}")["data"]["attributes"]
    except NotFound:
        return {"ok": True, "known": False, "kind": "file", "target": target, "sha256": sha, "size": size}
    return report("file", target, sha, attrs, f"{GUI}/file/{sha}")


def url_scan(url):
    uid = base64.urlsafe_b64encode(url.encode()).decode().rstrip("=")
    link = f"{GUI}/url/{hashlib.sha256(url.encode()).hexdigest()}"
    try:
        attrs = call("GET", f"/urls/{uid}")["data"]["attributes"]
    except NotFound:
        body = urllib.parse.urlencode({"url": url}).encode()
        aid = call("POST", "/urls", body, {"Content-Type": "application/x-www-form-urlencoded"})["data"]["id"]
        attrs = wait_analysis(aid)
    return report("url", url, None, attrs, link)


def scan(target):
    t = target.strip()
    if re.fullmatch(r"[0-9a-fA-F]{64}", t):
        return file_lookup(t.lower(), t.lower(), None)
    if re.match(r"https?://", t, re.I):
        return url_scan(t)
    path = Path(os.path.expanduser(t))
    if not path.is_file():
        fail(f"no file, URL or hash: {t}")
    return file_lookup(sha256_file(path), str(path), path.stat().st_size)


def upload(target):
    path = Path(os.path.expanduser(target))
    if not path.is_file():
        fail(f"no such file: {target}")
    size = path.stat().st_size
    if size > MAX_UPLOAD:
        fail("over 32 MB: the upload limit here")
    boundary = uuid.uuid4().hex
    name = path.name.replace('"', "")
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{name}"\r\n'
            f"Content-Type: application/octet-stream\r\n\r\n").encode() + path.read_bytes() \
           + f"\r\n--{boundary}--\r\n".encode()
    aid = call("POST", "/files", body, {"Content-Type": f"multipart/form-data; boundary={boundary}"})["data"]["id"]
    sha = sha256_file(path)
    return report("file", str(path), sha, wait_analysis(aid), f"{GUI}/file/{sha}")


def main():
    global KEY
    if len(sys.argv) != 3 or sys.argv[1] not in ("scan", "upload"):
        fail("usage: virustotal.py scan|upload <target>")
    KEY = key()
    try:
        out(scan(sys.argv[2]) if sys.argv[1] == "scan" else upload(sys.argv[2]))
    except (RuntimeError, OSError) as e:
        fail(str(e))


if __name__ == "__main__":
    main()
