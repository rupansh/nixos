# shellcheck shell=bash
# Claude Code status line, a single row:
#   ~/nix master ↑1+2~1?3 │ Opus 5.5 xhigh │ 123k 12% │ 5h 63% ↻2h │ 7d 89% ↻3d
# Schema: https://code.claude.com/docs/en/statusline#available-data

# ${#var} has to count characters, not bytes, when truncating the branch.
export LC_ALL=C.UTF-8

IFS= read -rd '' input || true

dir="" model="" effort="" ctx_used="" ctx_pct=""
five_pct="" five_left="" week_pct="" week_left=""

# One jq pass turns every field we need into shell-quoted assignments. Fields
# that are absent (effort on models without it, rate_limits off a Pro/Max plan
# or before the first API response) come out as empty strings.
eval "$(
  jq -r '
    def tok:
      if . >= 1000000 then "\(. / 100000 | floor / 10)M"
      elif . >= 1000 then "\(. / 1000 | floor)k"
      else tostring end;
    def left:
      (. - now | floor) as $s
      | if $s >= 86400 then "\($s / 86400 | floor)d"
        elif $s >= 3600 then "\($s / 3600 | floor)h"
        elif $s > 0 then "\($s / 60 | ceil)m"
        else "" end;
    def pct: if . == null then "" else round end;
    def window: {pct: (.used_percentage | pct), left: (.resets_at // null | if . == null then "" else left end)};

    .context_window as $c
    | (.rate_limits.five_hour // {} | window) as $five
    | (.rate_limits.seven_day // {} | window) as $week
    | @sh "dir=\(.workspace.current_dir // .cwd)",
      @sh "model=\(.model.display_name // .model.id | sub(" *\\([^)]*context\\)$"; ""))",
      @sh "effort=\(.effort.level // "")",
      @sh "ctx_used=\($c.total_input_tokens // 0 | if . > 0 then tok else "" end)",
      @sh "ctx_pct=\($c.used_percentage // 0 | round)",
      @sh "five_pct=\($five.pct) five_left=\($five.left)",
      @sh "week_pct=\($week.pct) week_left=\($week.left)"
  ' <<<"$input"
)"

reset=$'\e[0m'
dim=$'\e[2m'
bold=$'\e[1m'
red=$'\e[31m'
green=$'\e[32m'
yellow=$'\e[33m'
blue=$'\e[34m'
magenta=$'\e[35m'
cyan=$'\e[36m'
sep=" $dim│$reset "

# Green below 50%, yellow below 80%, red from there. Writes into the variable
# named by $1.
ctx_color="" five_color="" week_color=""
level() {
  if (($2 >= 80)); then
    printf -v "$1" %s "$red"
  elif (($2 >= 50)); then
    printf -v "$1" %s "$yellow"
  else
    printf -v "$1" %s "$green"
  fi
}
level ctx_color "$ctx_pct"
level five_color "${five_pct:-0}"
level week_color "${week_pct:-0}"

# Up to the last three folders of the cwd, $HOME shown as ~ and anything
# above collapsed to …: ~/nix, /tmp, …/src/components/button.
case $dir in
"$HOME" | "$HOME"/*) rel=\~${dir#"$HOME"} ;;
*) rel=$dir ;;
esac
lead=${rel%%[!/]*}
IFS=/ read -ra parts <<<"${rel#/}"
if ((${#parts[@]} > 3)); then
  parts=("…" "${parts[@]: -3}")
  lead=""
fi
printf -v path '%s/' "${parts[@]}"
path=$lead${path%/}

# Branch, ahead/behind, and staged/modified/untracked/conflicted counts from a
# single `git status`. --no-optional-locks keeps us from fighting a git command
# Claude is running in the same repo.
branch="" oid="" ahead=0 behind=0 staged=0 modified=0 untracked=0 conflicts=0
if st=$(git --no-optional-locks -C "$dir" status --porcelain=v2 --branch 2>/dev/null); then
  while IFS= read -r l; do
    case $l in
    "# branch.oid "*) oid=${l#"# branch.oid "} ;;
    "# branch.head "*) branch=${l#"# branch.head "} ;;
    "# branch.ab "*)
      ab=${l#"# branch.ab +"}
      ahead=${ab%% *} behind=${ab##*-}
      ;;
    [12]" "*)
      [[ ${l:2:1} != . ]] && ((++staged))
      [[ ${l:3:1} != . ]] && ((++modified))
      ;;
    "u "*) ((++conflicts)) ;;
    "? "*) ((++untracked)) ;;
    esac
  done <<<"$st"
  [[ $branch == "(detached)" ]] && branch="@${oid:0:7}"
  ((${#branch} > 16)) && branch="${branch:0:15}…"
fi

line="$bold$blue$path$reset"
if [[ -n $branch ]]; then
  line+=" $magenta$branch$reset"
  marks=""
  ((ahead)) && marks+="$cyan↑$ahead$reset"
  ((behind)) && marks+="$cyan↓$behind$reset"
  ((conflicts)) && marks+="$red!$conflicts$reset"
  ((staged)) && marks+="$green+$staged$reset"
  ((modified)) && marks+="$yellow~$modified$reset"
  ((untracked)) && marks+="$dim?$untracked$reset"
  [[ -n $marks ]] && line+=" $marks"
fi

line+="$sep$bold$model$reset"
[[ -n $effort ]] && line+=" $cyan$effort$reset"

line+=$sep
[[ -n $ctx_used ]] && line+="$ctx_used "
line+="$ctx_color$ctx_pct%$reset"

if [[ -n $five_pct ]]; then
  line+="${sep}5h $five_color$five_pct%$reset"
  [[ -n $five_left ]] && line+=" $dim↻$five_left$reset"
fi
if [[ -n $week_pct ]]; then
  line+="${sep}7d $week_color$week_pct%$reset"
  [[ -n $week_left ]] && line+=" $dim↻$week_left$reset"
fi

printf '%s\n' "$line"
