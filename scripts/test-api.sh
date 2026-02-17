#!/usr/bin/env bash
# Test the app: start (if needed), add a book, then verify with curl.

set -e
BASE_URL="${BASE_URL:-http://localhost:8080}"
API="${BASE_URL}/api/v1/book"

echo "=== Starting app (Docker Compose) if not running ==="
cd "$(dirname "$0")/.."
docker compose up -d --build 2>/dev/null || true

echo "=== Waiting for API to be ready ==="
for i in {1..30}; do
  if curl -sf "$API/all" > /dev/null 2>&1; then
    echo "API is up."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Timeout waiting for API. Is the app running on $BASE_URL?"
    exit 1
  fi
  sleep 2
done

echo ""
echo "=== 1. List books (before add) ==="
curl -s "$API/all" | jq . 2>/dev/null || curl -s "$API/all"
echo ""

echo "=== 2. Add a book ==="
curl -s -X POST "$API/save" \
  -H "Content-Type: application/json" \
  -d '{"name":"The Pragmatic Programmer","author":"Hunt & Thomas","price":44.99,"totalPage":352}' \
  | jq . 2>/dev/null || curl -s -X POST "$API/save" \
  -H "Content-Type: application/json" \
  -d '{"name":"The Pragmatic Programmer","author":"Hunt & Thomas","price":44.99,"totalPage":352}'
echo ""

echo "=== 3. List books (after add) ==="
curl -s "$API/all" | jq . 2>/dev/null || curl -s "$API/all"
echo ""

echo "=== 4. Get book by id (1) ==="
BOOK_1=$(curl -s "$API/1")
echo "$BOOK_1" | jq . 2>/dev/null || echo "$BOOK_1"
echo ""

# Fail if the book we added is not in the list or not gettable by id
if ! echo "$BOOK_1" | grep -q "The Pragmatic Programmer"; then
  echo "FAIL: Book by id 1 did not return expected content"
  exit 1
fi
LIST=$(curl -s "$API/all")
if ! echo "$LIST" | grep -q "The Pragmatic Programmer"; then
  echo "FAIL: Book not found in list after add"
  exit 1
fi

echo "=== Done (all API checks passed) ==="
