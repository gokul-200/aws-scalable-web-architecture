#!/usr/bin/env bash
# Usage: ./scripts/loadtest.sh <alb-dns-name> [seconds] [concurrency]
# Modest load to push average CPU over the scaling target. Stop with Ctrl+C.
# Requires "hey": https://github.com/rakyll/hey  (sudo apt install hey)
set -euo pipefail
ALB="${1:?usage: $0 <alb-dns-name> [seconds] [concurrency]}"
hey -z "${2:-300}s" -c "${3:-20}" "http://$ALB/api/info"
