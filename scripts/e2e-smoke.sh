#!/usr/bin/env bash
# End-to-end smoke test against a running backend and Mailpit.
# Usage: scripts/e2e-smoke.sh   (env: API_BASE_URL, MAILPIT_URL)
set -euo pipefail

API="${API_BASE_URL:-http://localhost:3000}"
MAILPIT="${MAILPIT_URL:-http://localhost:8025}"
failures=0

pass() { printf '  \033[32m✔\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✘\033[0m %s\n' "$1"; failures=$((failures + 1)); }

# Evaluates a JS expression against JSON on stdin (`d` is the parsed body).
json() { node -e "let s='';process.stdin.on('data',c=>s+=c).on('end',()=>{const d=JSON.parse(s);console.log($1)})"; }
status() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
check() { if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected $3, got $2)"; fi; }

echo "Backend: $API   Mailpit: $MAILPIT"

check "GET /health" "$(status "$API/health")" 200

featured=$(curl -sf "$API/api/products/featured")
check "home shows 5 featured products" "$(echo "$featured" | json 'd.products.length')" 5

slug=$(curl -sf "$API/api/categories" | json 'd.categories[0].slug')
page=$(curl -sf "$API/api/categories/$slug")
check "category '$slug' has top rated products" "$(echo "$page" | json 'd.topRated.length > 0')" true
check "category '$slug' has additional products" "$(echo "$page" | json 'd.others.length > 0')" true
check "unknown category is 404" "$(status "$API/api/categories/no-such-category")" 404

search=$(curl -sf "$API/api/products?q=backpack")
check "search returns matches" "$(echo "$search" | json 'd.products.length > 0')" true
check "search returns only matches" \
  "$(echo "$search" | json "d.products.every(p => (p.title+p.description+p.category.name).toLowerCase().includes('backpack'))")" true
check "search with no matches is empty" "$(curl -sf "$API/api/products?q=zzzqqq" | json 'd.products.length')" 0

id=$(echo "$featured" | json 'd.products[0].id')
check "product page loads" "$(curl -sf "$API/api/products/$id" | json 'd.product.id')" "$id"

check "invalid enquiry is rejected" "$(status -X POST "$API/api/enquiries" \
  -H 'content-type: application/json' -d "{\"productId\":\"$id\",\"name\":\"\",\"email\":\"nope\"}")" 400

marker="E2E$(date +%s)"  # no hyphen: Mailpit treats "-term" as exclusion
check "valid enquiry is accepted" "$(status -X POST "$API/api/enquiries" -H 'content-type: application/json' \
  -d "{\"productId\":\"$id\",\"name\":\"$marker\",\"email\":\"e2e@example.com\",\"message\":\"Smoke test\"}")" 202

found=0
for _ in 1 2 3 4 5; do
  found=$(curl -sf "$MAILPIT/api/v1/search?query=$marker" | json 'd.messages_count' || echo 0)
  [ "$found" -gt 0 ] && break
  sleep 1
done
check "sales inbox received the enquiry email" "$found" 1

echo
if [ "$failures" -eq 0 ]; then echo "All checks passed."; else echo "$failures check(s) failed."; exit 1; fi
