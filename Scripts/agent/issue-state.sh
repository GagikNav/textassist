#!/usr/bin/env bash
# Set an issue's agent state label (and sync the Project Status field).
#
# Usage: issue-state.sh <issue-number> <ready|in-progress|blocked|review|done>
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/agent-lib.sh"
require_gh

[[ $# -eq 2 ]] || die "usage: issue-state.sh <issue-number> <ready|in-progress|blocked|review|done>"
n="$1"; state="$2"

gh issue view "$n" --repo "$REPO" --json number >/dev/null 2>&1 || die "issue #$n not found in $REPO"

set_state_label "$n" "$state"
ok "issue #$n → $(state_label_for "$state")"
