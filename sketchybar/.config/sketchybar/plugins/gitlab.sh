#!/usr/bin/env bash
# Needs `glab auth login --hostname $GITLAB_HOST`. Without VPN or GitLab the item hides itself.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/settings.sh"

user_file="${TMPDIR:-/tmp}/sketchybar_gitlab_user"

api() {
	glab api --hostname "$GITLAB_HOST" "$1" 2>/dev/null
}

if [[ "$1" == "open" ]]; then
	open "https://$GITLAB_HOST/dashboard/merge_requests?reviewer_username=$(cat "$user_file" 2>/dev/null)"
	exit 0
fi

hide() {
	sketchybar --set "$NAME" drawing=off
	exit 0
}

[[ "$(scutil --nc status "$VPN_NAME" 2>/dev/null | head -1)" == "Connected" ]] || hide
[[ "$(curl -s -o /dev/null --max-time 3 -w '%{http_code}' "https://$GITLAB_HOST/users/sign_in")" == "200" ]] || hide

user="$(cat "$user_file" 2>/dev/null)"
if [[ -z "$user" ]]; then
	user="$(api user | jq -r '.username // empty')"
	[[ -n "$user" ]] || hide
	echo "$user" >"$user_file"
fi

reviews="$(api "merge_requests?scope=all&state=opened&reviewer_username=$user&per_page=100" | jq 'length' 2>/dev/null)"

failed=0
running=0
while read -r project iid; do
	[[ -z "$project" ]] && continue
	case "$(api "projects/$project/merge_requests/$iid" | jq -r '.head_pipeline.status // empty')" in
	failed) failed=$((failed + 1)) ;;
	running | pending | created) running=$((running + 1)) ;;
	esac
done < <(api "merge_requests?scope=created_by_me&state=opened&per_page=50" | jq -r '.[] | "\(.project_id) \(.iid)"' 2>/dev/null)

label=""
((${reviews:-0} > 0)) && label+="󰈈 $reviews  "
((failed > 0)) && label+=" $failed  "
((running > 0)) && label+="󰑮 $running  "
label="${label%  }"

if ((failed > 0)); then
	color="$LOVE"
elif ((${reviews:-0} > 0)); then
	color="$GOLD"
else
	color="$MUTED"
fi

sketchybar --set "$NAME" drawing=on icon.color="$color" label="$label" \
	label.drawing="$([[ -n "$label" ]] && echo on || echo off)"
