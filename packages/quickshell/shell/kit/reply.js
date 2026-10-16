.pragma library

// The reply of a backend script: one JSON object (scripts/backend.py). A reply
// that is not JSON becomes {ok: false, error} naming the script, unless the
// caller gives its own `fallback` (null, for a reply that may be missing).
function parse(text, script, fallback) {
  try {
    return JSON.parse(text);
  } catch (e) {
    return fallback === undefined ? { ok: false, error: "bad reply from " + script } : fallback;
  }
}
