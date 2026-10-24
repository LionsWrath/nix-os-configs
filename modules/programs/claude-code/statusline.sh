# Claude Code status line: model | dir | context bar | plan usage limits | session cost/time
# Reads the session JSON from stdin (see https://docs.claude.com/en/docs/claude-code/statusline)
export LC_NUMERIC=C
input=$(cat)
# Keep the latest payload around for debugging/tuning fields
{ printf '%s' "$input" > "$HOME/.claude/statusline-last.json"; } 2>/dev/null || true

j() { jq -r "$1 // empty" <<<"$input" 2>/dev/null || true; }

model=$(j '.model.display_name')
dir=$(basename "$(j '.workspace.current_dir')")
cost=$(j '.cost.total_cost_usd')
dur_ms=$(j '.cost.total_duration_ms | floor')
ctx_pct=$(j '.context_window.used_percentage')
ctx_size=$(j '.context_window.context_window_size')
ctx_used=$(j '(.context_window.current_usage | if . then (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0) else null end)')
five_pct=$(j '.rate_limits.five_hour.used_percentage')
five_reset=$(j '.rate_limits.five_hour.resets_at')
week_pct=$(j '.rate_limits.seven_day.used_percentage')

# Fall back to computing context % from token counts
if [[ -z $ctx_pct && -n $ctx_used && -n $ctx_size ]] && (( ctx_size > 0 )); then
  ctx_pct=$(( ctx_used * 100 / ctx_size ))
fi

RST=$'\e[0m'; DIM=$'\e[2m'; CYAN=$'\e[36m'; MAG=$'\e[35m'
color_for() { # green < 50 <= yellow < 80 <= red
  local p=${1%.*}
  if (( p >= 80 )); then printf '\e[31m'; elif (( p >= 50 )); then printf '\e[33m'; else printf '\e[32m'; fi
}

bar() { # 10-cell bar
  local p=${1%.*} filled i out=""
  (( p > 100 )) && p=100
  filled=$(( (p + 5) / 10 ))
  for ((i = 0; i < 10; i++)); do
    if (( i < filled )); then out+="█"; else out+="░"; fi
  done
  printf '%s' "$out"
}

human() { # 123456 -> 123k, 1000000 -> 1.0M
  local n=$1
  if (( n >= 1000000 )); then printf '%d.%dM' $(( n / 1000000 )) $(( n % 1000000 / 100000 ))
  elif (( n >= 1000 )); then printf '%dk' $(( n / 1000 ))
  else printf '%d' "$n"; fi
}

parts=()
[[ -n $model ]] && parts+=("${MAG}${model}${RST}")
[[ -n $dir ]] && parts+=("${CYAN}${dir}${RST}")

if [[ -n $ctx_pct ]]; then
  c=$(color_for "$ctx_pct")
  seg="ctx ${c}$(bar "$ctx_pct") ${ctx_pct%.*}%${RST}"
  [[ -n $ctx_used && -n $ctx_size ]] && seg+=" ${DIM}$(human "$ctx_used")/$(human "$ctx_size")${RST}"
  parts+=("$seg")
fi

if [[ -n $five_pct ]]; then
  c=$(color_for "$five_pct")
  seg="5h ${c}${five_pct%.*}%${RST}"
  if [[ -n $five_reset ]]; then
    now=$(date +%s)
    [[ $five_reset =~ ^[0-9]+$ ]] || five_reset=$(date -d "$five_reset" +%s 2>/dev/null || true)
    if [[ -n $five_reset ]] && (( five_reset > now )); then
      left=$(( five_reset - now ))
      seg+=" ${DIM}↻$(( left / 3600 ))h$(( left % 3600 / 60 ))m${RST}"
    fi
  fi
  parts+=("$seg")
fi
[[ -n $week_pct ]] && parts+=("7d $(color_for "$week_pct")${week_pct%.*}%${RST}")

if [[ -n $cost ]]; then
  seg=$(printf '$%.2f' "$cost")
  [[ -n $dur_ms ]] && seg+=" ${DIM}$(( dur_ms / 60000 ))m${RST}"
  parts+=("$seg")
fi

out=""
for p in "${parts[@]}"; do
  [[ -n $out ]] && out+=" ${DIM}│${RST} "
  out+="$p"
done
printf '%s' "$out"
