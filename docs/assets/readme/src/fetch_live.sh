#!/bin/zsh
# Fetch the live numbers the README pictures use: API responses and server-side latency.
# Needs proto/deploy/ssh_config (see proto/README.md). Output: docs/assets/readme/src/live/
set -e
cd "${0:A:h}/../../../.."
L=docs/assets/readme/src/live; mkdir -p $L
for e in health readiness board epoch assurance policies; do curl -sf --max-time 30 https://148.100.99.205/api/$e -o $L/$e.json; done
proto/deploy/remote.sh 'python3 - <<PY
import json, statistics, time, urllib.request
eps = ["readiness", "board", "epoch", "assurance", "policies", "twin/TJ107", "issues/TJ107-HYD-101", "workbench/TJ107-HYD-101"]
ms = []
for _ in range(20):
    for e in eps:
        t = time.perf_counter(); urllib.request.urlopen("http://127.0.0.1:8700/api/" + e).read(); ms.append((time.perf_counter() - t) * 1000)
ms.sort()
print(json.dumps({"calls": len(ms), "median_ms": statistics.median(ms), "p95_ms": ms[int(len(ms) * .95)],
                  "when": time.strftime("%d %b %Y %H:%M UTC", time.gmtime())}))
PY' > $L/latency.json
cat $L/latency.json
