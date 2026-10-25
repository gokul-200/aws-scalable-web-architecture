#!/usr/bin/env bash
# Usage: ./scripts/verify.sh <alb-dns-name> [requests]
# Sends requests through the ALB and counts which instance answered.
set -euo pipefail
ALB="${1:?usage: $0 <alb-dns-name> [requests]}"
N="${2:-20}"
echo "Health:"; curl -s -o /dev/null -w "  /health -> HTTP %{http_code}\n" "http://$ALB/health"
echo "Distribution over $N requests:"
for _ in $(seq "$N"); do curl -s "http://$ALB/api/info"; echo; done \
  | python3 -c 'import sys,json,collections as c
t=c.Counter()
for l in sys.stdin:
    l=l.strip()
    if l:
        d=json.loads(l); t[(d["instance_id"],d["availability_zone"])]+=1
for (i,az),n in t.most_common(): print(f"  {i} ({az}): {n}")'
