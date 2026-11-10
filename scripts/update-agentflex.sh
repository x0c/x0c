#!/bin/bash
# Weekly update: render the agentflex card PNG locally and push it to the
# GitHub profile README (x0c/x0c). Must run on the Mac that holds the
# coding-agent histories — GitHub Actions cannot do this (no history there).
#
#   ./scripts/update-agentflex.sh            # render + update README + push
#   ./scripts/update-agentflex.sh --no-push  # render + update README only
#   ./scripts/update-agentflex.sh --if-stale 6  # only run if the PNG is older than 6 days
#                                              # (used by the catch-up timer)
#
# Scheduled via launchd (see launchd/*.plist). Note: launchd's
# StartCalendarInterval does NOT compensate a missed run — if the Mac is
# asleep at Monday 09:00, that occurrence is silently skipped. The
# com.x0c.agentflex-catchup timer (RunAtLoad + every 6h) covers this by
# calling this script with --if-stale 6.
set -euo pipefail

NO_PUSH=0
IF_STALE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push) NO_PUSH=1; shift ;;
    --if-stale) IF_STALE="${2:-}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASSETS="$ROOT/assets"
PNG="$ASSETS/agentflex-week.png"
README="$ROOT/README.md"
LOG_PREFIX="agentflex-weekly"

if [[ -n "$IF_STALE" && -f "$PNG" ]]; then
  AGE_DAYS=$(( ($(date +%s) - $(stat -f %m "$PNG")) / 86400 ))
  if [[ "$AGE_DAYS" -lt "$IF_STALE" ]]; then
    echo "[$LOG_PREFIX] card is fresh (${AGE_DAYS}d < ${IF_STALE}d), skipping."
    exit 0
  fi
  echo "[$LOG_PREFIX] card is stale (${AGE_DAYS}d >= ${IF_STALE}d), refreshing."
fi

mkdir -p "$ASSETS"

TMP="$(mktemp /tmp/agentflex-week-XXXXXX.png)"
trap 'rm -f "$TMP"' EXIT

echo "[$LOG_PREFIX] rendering card..."
npx -y agentflex@latest --png "$TMP"
test -s "$TMP"
mv -f "$TMP" "$PNG"
echo "[$LOG_PREFIX] wrote $PNG ($(du -h "$PNG" | cut -f1))"

echo "[$LOG_PREFIX] reading stats..."
STATS_JSON="$(npx -y agentflex@latest --json)"

read -r SESSIONS TOKENS_COMPACT PEAK PEAK_AT < <(printf '%s' "$STATS_JSON" | python3 -c "
import json, sys, datetime
d = json.load(sys.stdin)
t = d.get('tokens', 0)
def compact(n):
    n = float(n)
    for unit in ('', 'K', 'M', 'B', 'T'):
        if abs(n) < 1000 or unit == 'T':
            s = f'{n:.2f}'.rstrip('0').rstrip('.')
            return s + unit
        n /= 1000.0
peak_at = d.get('peak_at')
peak_str = ''
if peak_at:
    peak_str = datetime.datetime.fromtimestamp(peak_at).strftime('%m-%d %H:%M')
print(d.get('sessions', 0), compact(t), d.get('peak_parallel', 0), peak_str)
")
TODAY="$(date +%Y-%m-%d)"
CAPTION="Week of $TODAY · $SESSIONS sessions · $TOKENS_COMPACT tokens · peak $PEAK parallel ($PEAK_AT)"

echo "[$LOG_PREFIX] $CAPTION"

python3 - "$README" "$CAPTION" <<'EOF'
import sys
readme_path, caption = sys.argv[1], sys.argv[2]
with open(readme_path) as f:
    content = f.read()

block = (
    "#### \U0001f4ca Coding Week\n"
    "<!-- agentflex-start -->\n"
    f"![coding-agent week](./assets/agentflex-week.png)\n"
    f"*{caption} — auto-updated weekly by [agentflex](https://github.com/corral-dev/agentflex).*\n"
    "<!-- agentflex-end -->\n"
)

start, end = "<!-- agentflex-start -->", "<!-- agentflex-end -->"
if start in content and end in content:
    pre, _, rest = content.partition(start)
    _, _, post = rest.partition(end)
    # keep everything before the old header line of the block: drop the
    # previous "#### 📊 Coding Week" line that directly precedes the marker
    header = "#### \U0001f4ca Coding Week\n"
    if pre.endswith(header):
        pre = pre[: -len(header)]
    # normalize trailing blank lines around the block
    content = pre.rstrip() + "\n\n" + block + post.lstrip()
else:
    # insert before the trailing star-line, else append at the end
    tail = "*If something here saves you time or tokens, star the repos so you can find them again later.*"
    if tail in content:
        content = content.replace(tail, block + "\n" + tail)
    else:
        content = content.rstrip() + "\n\n" + block

with open(readme_path, "w") as f:
    f.write(content)
print("README block updated")
EOF

cd "$ROOT"
git add assets/agentflex-week.png README.md
if git diff --cached --quiet; then
  echo "[$LOG_PREFIX] no changes, nothing to push."
  exit 0
fi
git commit -m "chore: weekly agentflex card ($TODAY, $SESSIONS sessions, $TOKENS_COMPACT tokens)"
if [[ "$NO_PUSH" == "1" ]]; then
  echo "[$LOG_PREFIX] --no-push: committed locally, skipping push."
  exit 0
fi
git push origin HEAD
echo "[$LOG_PREFIX] pushed."
