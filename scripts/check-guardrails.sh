#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

errors=0

info()  { echo ":: $*"; }
fail()  { echo "  FAIL: $*"; errors=$((errors + 1)); }
pass()  { echo "  PASS: $*"; }

# ── 1. Directory structure ──────────────────────────
info "[structure] Checking directory layout..."

EXPECTED_DIRS=(Agent App DI Gleaner Models Services Sources Storage UI)
for dir in "${EXPECTED_DIRS[@]}"; do
  if [ -d "Sources/Glint/$dir" ]; then
    pass "Sources/Glint/$dir exists"
  else
    fail "Missing expected directory Sources/Glint/$dir"
  fi
done

while IFS= read -r f; do
  fail "Unexpected file at Sources/Glint/ root: $(basename "$f") (should move to subdirectory)"
done < <(find Sources/Glint -maxdepth 1 -name "*.swift" ! -name "GlintApp.swift" ! -name "ContentView.swift")

# ── 2. Import boundaries ────────────────────────────
info "[imports] Checking import boundaries..."

check_imports() {
  local dir=$1; shift
  local forbidden=("$@")
  while IFS= read -r f; do
    while IFS= read -r line; do
      imp=$(echo "$line" | sed 's/^import[[:space:]]*//')
      for forbid in "${forbidden[@]}"; do
        if [ "$imp" = "$forbid" ]; then
          fail "${f#Sources/Glint/} imports '$forbid' (forbidden in $dir/)"
        fi
      done
    done < <(grep "^import" "$f" 2>/dev/null || true)
  done < <(find "Sources/Glint/$dir" -name "*.swift")
}

check_imports "Agent"   "SwiftUI" "AppKit" "Factory"
check_imports "Models"  "SwiftUI" "AppKit" "Factory"
check_imports "Storage" "SwiftUI" "AppKit" "Factory"
check_imports "Sources" "SwiftUI" "AppKit" "Factory"
check_imports "Services" "SwiftUI" "AppKit" "Factory"
check_imports "UI"      "AppKit" "Factory"

# ── 3. Dead-symbol detection ────────────────────────
info "[deadcode] Checking for unreferenced dependencies..."

dep_names=$(grep "\.package(url:" Package.swift | sed -n 's/.*name: *"\([^"]*\)".*/\1/p' || true)
if [ -z "$dep_names" ]; then
  dep_names=$(grep "\.package(url:" Package.swift | sed -n 's|.*/\([^/"]*\)") *$|\1|p' || true)
fi

while IFS= read -r dep; do
  [ -z "$dep" ] && continue
  product="$(grep -A5 "\"$dep\"" Package.swift | grep "\.product(name:" | sed 's/.*name: *"\([^"]*\)".*/\1/' | head -1)"
  product="${product:-$dep}"
  found=false
  while IFS= read -r f; do
    if grep -q "^import $product" "$f" 2>/dev/null; then
      found=true; break
    fi
  done < <(find Sources -name "*.swift")
  if [ "$found" = false ]; then
    fail "Dependency '$dep' (product '$product') is imported in zero source files"
  else
    pass "Dependency '$dep' is referenced in source"
  fi
done <<< "$dep_names"

# ── Result ──────────────────────────────────────────
echo ""
if [ "$errors" -gt 0 ]; then
  echo "FAILED: $errors violation(s) found"
  exit 1
fi
echo "PASSED: All guardrails checks passed"
