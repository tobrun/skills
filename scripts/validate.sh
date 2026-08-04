#!/usr/bin/env bash
# Self-validation script for the skills marketplace repository.
# Checks all structural rules and exits non-zero on first category of failure.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ERROR_FILE=$(mktemp)
trap 'rm -f "$ERROR_FILE"' EXIT

# ---------------------------------------------------------------------------
# Helper: accumulate error message
# ---------------------------------------------------------------------------
fail() {
  local category="$1"
  local file="$2"
  local msg="$3"
  echo "[$category] $file: $msg" >> "$ERROR_FILE"
}

# ---------------------------------------------------------------------------
# Get list of plugin directories from marketplace
# ---------------------------------------------------------------------------
marketplace_source_dirs() {
  jq -r '.plugins[] | .source | sub("^\\./"; "")' \
    ".claude-plugin/marketplace.json" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Get list of actual plugin dirs (have .claude-plugin/plugin.json)
# ---------------------------------------------------------------------------
actual_plugin_dirs() {
  for dir in */; do
    dir="${dir%/}"
    [ "${dir:0:1}" = "." ] && continue
    [ "$dir" = "scripts" ] && continue
    [ "$dir" = "todo" ] && continue
    [ -f "$dir/.claude-plugin/plugin.json" ] && echo "$dir"
  done
}

# ===========================================================================
# R01: marketplace.json exists and is valid JSON
# ===========================================================================
check_01() {
  local f=".claude-plugin/marketplace.json"
  if [ ! -f "$f" ]; then
    fail "R01" "$f" "File not found"
    return
  fi
  if ! jq -e . "$f" >/dev/null 2>&1; then
    fail "R01" "$f" "Invalid JSON"
  fi
}

# ===========================================================================
# R02: Every entry in plugins[] has name, source, description
# ===========================================================================
check_02() {
  local f=".claude-plugin/marketplace.json"
  [ ! -f "$f" ] && return
  local entries
  entries=$(jq -c '.plugins[]' "$f" 2>/dev/null || true)
  [ -z "$entries" ] && return
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local name source desc
    name=$(echo "$entry" | jq -r '.name // empty')
    source=$(echo "$entry" | jq -r '.source // empty')
    desc=$(echo "$entry" | jq -r '.description // empty')
    [ -z "$name" ]   && fail "R02" "$f" "Plugin entry missing 'name'"
    [ -z "$source" ] && fail "R02" "$f" "Plugin entry '$name' missing 'source'"
    [ -z "$desc" ]   && fail "R02" "$f" "Plugin entry '$name' missing 'description'"
  done <<< "$entries"
}

# ===========================================================================
# R03: Every source path exists as a directory
# ===========================================================================
check_03() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r source; do
    [ -z "$source" ] && continue
    [ ! -d "$source" ] && fail "R03" ".claude-plugin/marketplace.json" \
      "Source path './$source' is not a directory"
  done <<< "$sources"
}

# ===========================================================================
# R04: No orphans -- every plugin dir is listed AND every listing has a dir
# ===========================================================================
check_04() {
  local f=".claude-plugin/marketplace.json"
  local listed
  listed=$(marketplace_source_dirs)

  # Every actual plugin dir must be listed
  local actual
  actual=$(actual_plugin_dirs)
  if [ -n "$actual" ]; then
    while IFS= read -r dir; do
      [ -z "$dir" ] && continue
      if ! grep -qxF "$dir" <<< "$listed" 2>/dev/null; then
        fail "R04" "$dir" "Plugin directory not listed in marketplace.json"
      fi
    done <<< "$actual"
  fi

  # Every listing must have a matching directory
  if [ -n "$listed" ]; then
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      if [ ! -d "$entry" ]; then
        fail "R04" "$f" "Plugin '$entry' listed but directory not found"
      elif [ ! -f "$entry/.claude-plugin/plugin.json" ]; then
        fail "R04" "$f" "Plugin '$entry' listed but no .claude-plugin/plugin.json"
      fi
    done <<< "$listed"
  fi
}

# ===========================================================================
# R05: Every plugin has plugin.json with name, version (semver),
#      description, author.name
# ===========================================================================
check_05() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    local pf="$dir/.claude-plugin/plugin.json"
    if [ ! -f "$pf" ]; then
      fail "R05" "$pf" "File not found"
      continue
    fi
    if ! jq -e . "$pf" >/dev/null 2>&1; then
      fail "R05" "$pf" "Invalid JSON"
      continue
    fi
    local name ver desc author
    name=$(jq -r '.name // empty' "$pf")
    ver=$(jq -r '.version // empty' "$pf")
    desc=$(jq -r '.description // empty' "$pf")
    author=$(jq -r '.author.name // empty' "$pf")

    [ -z "$name" ]   && fail "R05" "$pf" "Missing 'name'"
    [ -z "$desc" ]   && fail "R05" "$pf" "Missing 'description'"
    [ -z "$author" ] && fail "R05" "$pf" "Missing 'author.name'"
    if [ -z "$ver" ]; then
      fail "R05" "$pf" "Missing 'version'"
    else
      if ! echo "$ver" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
        fail "R05" "$pf" "Version '$ver' is not valid semver"
      fi
    fi
  done <<< "$sources"
}

# ===========================================================================
# R06: Dir name = plugin.json name = marketplace entry name
# ===========================================================================
check_06() {
  local f=".claude-plugin/marketplace.json"
  local entries
  entries=$(jq -c '.plugins[]' "$f" 2>/dev/null || true)
  [ -z "$entries" ] && return
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    local mkt_name source
    mkt_name=$(echo "$entry" | jq -r '.name // empty')
    source=$(echo "$entry" | jq -r '.source // empty' | sed 's|^\./||')
    [ -z "$source" ] && continue
    [ ! -d "$source" ] && continue

    local dir_basename
    dir_basename=$(basename "$source")

    if [ "$dir_basename" != "$mkt_name" ]; then
      fail "R06" "$f" \
        "Dir name '$dir_basename' != marketplace entry name '$mkt_name'"
    fi

    local pj_name
    pj_name=$(jq -r '.name // empty' "$source/.claude-plugin/plugin.json" 2>/dev/null || echo "")
    if [ -n "$pj_name" ] && [ "$pj_name" != "$mkt_name" ]; then
      fail "R06" "$source/.claude-plugin/plugin.json" \
        "Name '$pj_name' != marketplace name '$mkt_name'"
    fi
  done <<< "$entries"
}

# ===========================================================================
# R07: Every plugin has a README.md
# ===========================================================================
check_07() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    [ ! -f "$dir/README.md" ] && fail "R07" "$dir/README.md" "File not found"
  done <<< "$sources"
}

# ===========================================================================
# R08: Every plugin has at least one of skills/, commands/, agents/
# ===========================================================================
check_08() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    if [ ! -d "$dir/skills" ] && [ ! -d "$dir/commands" ] && [ ! -d "$dir/agents" ]; then
      fail "R08" "$dir" "No skills/, commands/, or agents/ directory found"
    fi
  done <<< "$sources"
}

# ===========================================================================
# R09: Every skills/*/ directory contains SKILL.md
# ===========================================================================
check_09() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    [ ! -d "$dir/skills" ] && continue
    for skilldir in "$dir/skills"/*/; do
      [ ! -d "$skilldir" ] && continue
      skilldir="${skilldir%/}"
      [ ! -f "$skilldir/SKILL.md" ] && fail "R09" "$skilldir" "Missing SKILL.md"
    done
  done <<< "$sources"
}

# ===========================================================================
# R10: SKILL.md has YAML frontmatter with non-empty name and description
# ===========================================================================
check_10() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    [ ! -d "$dir/skills" ] && continue
    for skilldir in "$dir/skills"/*/; do
      [ ! -d "$skilldir" ] && continue
      local sf="${skilldir%/}/SKILL.md"
      [ ! -f "$sf" ] && continue

      # Must start with ---
      if ! head -1 "$sf" | grep -q '^---$'; then
        fail "R10" "$sf" "Does not start with ---"
        continue
      fi

      # Extract YAML frontmatter (lines between first and second ---)
      local yaml
      yaml=$(awk '/^---$/ {c++; next} c==1 {print}' "$sf")
      if [ -z "$yaml" ]; then
        fail "R10" "$sf" "Empty or missing frontmatter"
        continue
      fi

      # Parse with yq
      local n d
      n=$(echo "$yaml" | yq eval '.name // ""' - 2>/dev/null || echo "")
      d=$(echo "$yaml" | yq eval '.description // ""' - 2>/dev/null || echo "")
      [ -z "$n" ] && fail "R10" "$sf" "Frontmatter 'name' is empty or missing"
      [ -z "$d" ] && fail "R10" "$sf" "Frontmatter 'description' is empty or missing"
    done
  done <<< "$sources"
}

# ===========================================================================
# R11: Frontmatter name matches skill directory name
# ===========================================================================
check_11() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    [ ! -d "$dir/skills" ] && continue
    for skilldir in "$dir/skills"/*/; do
      [ ! -d "$skilldir" ] && continue
      local sname
      sname=$(basename "${skilldir%/}")
      local sf="${skilldir%/}/SKILL.md"
      [ ! -f "$sf" ] && continue

      local yaml
      yaml=$(awk '/^---$/ {c++; next} c==1 {print}' "$sf")
      [ -z "$yaml" ] && continue

      local fm_name
      fm_name=$(echo "$yaml" | yq eval '.name // ""' - 2>/dev/null || echo "")
      if [ -n "$fm_name" ] && [ "$fm_name" != "$sname" ]; then
        fail "R11" "$sf" \
          "Frontmatter name '$fm_name' != directory name '$sname'"
      fi
    done
  done <<< "$sources"
}

# ===========================================================================
# R14: Every SKILL.md sets disable-model-invocation: true
# ===========================================================================
check_14() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    [ ! -d "$dir/skills" ] && continue
    for skilldir in "$dir/skills"/*/; do
      [ ! -d "$skilldir" ] && continue
      local sf="${skilldir%/}/SKILL.md"
      [ ! -f "$sf" ] && continue

      local yaml
      yaml=$(awk '/^---$/ {c++; next} c==1 {print}' "$sf")
      [ -z "$yaml" ] && continue

      local dmi
      dmi=$(echo "$yaml" | yq eval '.disable-model-invocation // ""' - 2>/dev/null || echo "")
      if [ "$dmi" != "true" ]; then
        fail "R14" "$sf" \
          "Frontmatter must set 'disable-model-invocation: true' (all skills are human-triggered)"
      fi
    done
  done <<< "$sources"
}

# ===========================================================================
# R12: Every plugin appears in the root README table
# ===========================================================================
check_12() {
  local readme="README.md"
  [ ! -f "$readme" ] && { fail "R12" "$readme" "File not found"; return; }
  local names
  names=$(jq -r '.plugins[] | .name' ".claude-plugin/marketplace.json" 2>/dev/null || true)
  [ -z "$names" ] && return
  while IFS= read -r name; do
    [ -z "$name" ] && continue
    if ! grep -q "\[$name\]" "$readme" 2>/dev/null; then
      fail "R12" "$readme" \
        "Plugin '$name' not found in plugin table (search for [$name])"
    fi
  done <<< "$names"
}

# ===========================================================================
# R13: No em dashes (U+2014) in any file
# ===========================================================================
check_13() {
  while IFS= read -r -d '' file; do
    local ft
    ft=$(file "$file" 2>/dev/null || echo "unknown")
    case "$ft" in
      *binary*|*image*|*archive*|*executable*|*compressed*|*font*)
        continue
        ;;
    esac
    if grep -E "$(printf '\xE2\x80\x94')" "$file" 2>/dev/null; then
      fail "R13" "$file" \
        "Contains em dash (Unicode U+2014). Use two plain dashes instead."
    fi
  done < <(find . -not -path './.git/*' -not -path './todo/*' -not -path './research/*' -type f -print0)
}

# ===========================================================================
# R00 (bonus): Warn if SKILL.md is over ~200 lines
# ===========================================================================
check_skill_length() {
  local sources
  sources=$(marketplace_source_dirs)
  [ -z "$sources" ] && return
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    [ ! -d "$dir" ] && continue
    [ ! -d "$dir/skills" ] && continue
    for skilldir in "$dir/skills"/*/; do
      [ ! -d "$skilldir" ] && continue
      local sf="${skilldir%/}/SKILL.md"
      [ ! -f "$sf" ] && continue
      local total
      total=$(wc -l < "$sf")
      if [ "$total" -gt 200 ]; then
        fail "R00" "$sf" \
          "Body is $total lines (recommend under 150; move detail to references/)"
      fi
    done
  done <<< "$sources"
}

# ===========================================================================
# C01: Generated Codex distribution is current and structurally valid
# ===========================================================================
check_codex() {
  local marketplace=".agents/plugins/marketplace.json"
  local plugin="plugins/dev"
  local manifest="$plugin/.codex-plugin/plugin.json"

  if ! python3 scripts/build_codex_plugin.py --check >/dev/null 2>&1; then
    fail "C01" "$plugin" \
      "Generated Codex plugin is stale; run python3 scripts/build_codex_plugin.py"
  fi

  if ! jq -e '
    .name == "nurbot" and
    (.plugins | length == 1) and
    .plugins[0].name == "dev" and
    .plugins[0].source.source == "local" and
    .plugins[0].source.path == "./plugins/dev" and
    .plugins[0].policy.installation == "AVAILABLE" and
    .plugins[0].policy.authentication == "ON_INSTALL" and
    (.plugins[0].category | length > 0)
  ' "$marketplace" >/dev/null 2>&1; then
    fail "C01" "$marketplace" "Invalid Codex marketplace entry"
  fi

  if ! jq -e '
    .name == "dev" and
    (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+([+-][0-9A-Za-z.-]+)?$")) and
    (.description | length > 0) and
    (.author.name | length > 0) and
    .skills == "./skills/" and
    (.interface.displayName | length > 0) and
    (.interface.shortDescription | length > 0) and
    (.interface.longDescription | length > 0) and
    (.interface.developerName | length > 0) and
    (.interface.category | length > 0) and
    (.interface.capabilities | length > 0) and
    (.interface.defaultPrompt | length > 0)
  ' "$manifest" >/dev/null 2>&1; then
    fail "C01" "$manifest" "Invalid Codex plugin manifest"
  fi

  for skilldir in "$plugin"/skills/*/; do
    [ ! -d "$skilldir" ] && continue
    local skill_name
    skill_name=$(basename "${skilldir%/}")
    local skill_md="${skilldir%/}/SKILL.md"
    local agent_yaml="${skilldir%/}/agents/openai.yaml"

    if grep -q '^disable-model-invocation: true$' "$skill_md"; then
      fail "C01" "$skill_md" \
        "Codex skill must not contain Claude invocation frontmatter"
    fi
    if [ ! -f "$agent_yaml" ]; then
      fail "C01" "$agent_yaml" "Missing Codex skill interface metadata"
    elif ! grep -q '^  allow_implicit_invocation: false$' "$agent_yaml"; then
      fail "C01" "$agent_yaml" "Skill must remain explicit-invocation only"
    fi
    if ! grep -Fq "\$dev:$skill_name" "$agent_yaml" 2>/dev/null; then
      fail "C01" "$agent_yaml" \
        "Default prompt must name the namespaced Codex skill"
    fi
  done
}

# ===========================================================================
# P01: Pi package manifest and subprocess review transport are valid
# ===========================================================================
check_pi() {
  local package="package.json"
  local runner="dev/skills/to-review/scripts/run-pi-agents.sh"
  local package_version
  local plugin_version

  if ! jq -e '
    .name == "@tobrun/dev-workflow" and
    (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+([+-][0-9A-Za-z.-]+)?$")) and
    (.keywords | index("pi-package")) and
    .files == ["dev/skills", "dev/references", "README.md"] and
    .pi.skills == ["./dev/skills"]
  ' "$package" >/dev/null 2>&1; then
    fail "P01" "$package" "Invalid Pi package manifest"
  fi

  package_version=$(jq -r '.version // empty' "$package" 2>/dev/null || true)
  plugin_version=$(jq -r '.version // empty' \
    dev/.claude-plugin/plugin.json 2>/dev/null || true)
  if [ "$package_version" != "$plugin_version" ]; then
    fail "P01" "$package" \
      "Pi package version must match dev/.claude-plugin/plugin.json"
  fi

  if [ ! -x "$runner" ]; then
    fail "P01" "$runner" "Pi agent runner must be executable"
  elif ! bash -n "$runner" scripts/test_pi_runner.sh; then
    fail "P01" "$runner" "Pi agent runner scripts have invalid shell syntax"
  elif ! bash scripts/test_pi_runner.sh >/dev/null 2>&1; then
    fail "P01" "$runner" "Pi agent runner self-test failed"
  fi

  if ! grep -q 'Native transport (preferred)' \
    dev/skills/to-review/references/orchestration.md; then
    fail "P01" "dev/skills/to-review/references/orchestration.md" \
      "Missing native multi-agent transport"
  fi
  if ! grep -q 'PI_CODING_AGENT=true' \
    dev/skills/to-review/references/orchestration.md; then
    fail "P01" "dev/skills/to-review/references/orchestration.md" \
      "Missing Pi subprocess transport"
  fi
}

# ===========================================================================
# Main
# ===========================================================================
check_01
check_02
check_03
check_04
check_05
check_06
check_07
check_08
check_09
check_10
check_11
check_12
check_13
check_14
check_skill_length
check_codex
check_pi

if [ -s "$ERROR_FILE" ]; then
  echo ""
  echo "=== FAILED ==="
  cat "$ERROR_FILE"
  exit 1
fi

echo ""
echo "All checks passed."
