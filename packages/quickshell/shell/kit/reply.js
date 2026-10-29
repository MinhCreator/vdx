.pragma library

// The reply of a backend script: one JSON object (scripts/backend.py). A reply
// that is not a JSON object becomes {ok: false, error} naming the script, unless the
// caller gives its own `fallback` (null, for a reply that may be missing).
function parse(text, script, fallback) {
  try {
    const reply = JSON.parse(text);
    if (reply !== null && typeof reply === "object" && !Array.isArray(reply)) return reply;
  } catch (e) {}
  return fallback === undefined ? { ok: false, error: "bad reply from " + script } : fallback;
}
