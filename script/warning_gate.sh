#!/usr/bin/env bash
# Fails when the log of any other job of the current workflow run contains a warning or a deprecation notice
# (script/warnings.sh). Run by the "Warning gate" job of every workflow; the repository tolerates no warnings (see
# CONTRIBUTING.md).
#
# Needs GH_TOKEN (actions: read), GITHUB_REPOSITORY and GITHUB_RUN_ID. The jobs named "Warning gate ..." are the
# gates themselves, whose logs quote the warnings they found.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly root
repository=${GITHUB_REPOSITORY:?}
run_id=${GITHUB_RUN_ID:?}
token=${GH_TOKEN:?}
readonly repository run_id token

jobs=$(gh api --paginate "repos/${repository}/actions/runs/${run_id}/jobs?per_page=100" \
  --jq '.jobs[] | select((.name | startswith("Warning gate") | not) and .conclusion != "skipped")
    | "\(.id)\t\(.name)"')

status=0
while IFS=$'\t' read -r id name; do
  [[ -n ${id} ]] || continue
  # Downloaded with curl: depending on its version, gh refuses to print a log that contains terminal escape
  # sequences (colored tool output), and older versions do not know the flag that allows them.
  if hits=$(curl --fail --silent --show-error --location \
    --header "Authorization: Bearer ${token}" --header 'Accept: application/vnd.github+json' \
    "${GITHUB_API_URL:-https://api.github.com}/repos/${repository}/actions/jobs/${id}/logs" \
    | "${root}/script/warnings.sh"); then
    printf 'No warnings in the log of job "%s"\n' "${name}"
  else
    printf '::error::Warnings in the log of job "%s"\n%s\n\n' "${name}" "${hits}"
    status=1
  fi
done <<< "${jobs}"

exit "${status}"
