#!/usr/bin/env bash
# Reads a log on standard input and fails when it contains a warning or a deprecation notice, printing each such
# line with its line number. The only lines that do not count are the warnings of third-party gems listed in
# script/upstream_warnings.txt, and CodeQL's description of its own deprecated option (below).
# Used by script/check (the output of every check) and script/warning_gate.sh (the log of every CI job).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly root

# Ruby and compiler style "warning:", the log levels of tools (WARN, level=warn, [warn]), GitHub annotations and
# deprecation notices of any tool.
pattern='[Ww]arning:|WARNING|(^|[^[:alnum:]_])WARN([^[:alnum:]_]|$)|level=warn|\[warn\]|##\[warning\]|DEPRECATION'
pattern+='|DEPRECATED|is deprecated|will be deprecated|deprecated and will|Node\.js [0-9]+ actions are deprecated'
readonly pattern

# CodeQL prints the JSON schema of its extractor options, whose "title" and "description" fields document a
# deprecated option ("DEPRECATED - Whether to use buildless ..."). Only such JSON documentation fields are skipped.
codeql_documentation='^[0-9TZ:.-]+ +"(title|description)" : "'
readonly codeql_documentation

upstream=$(grep -vE '^(#|$)' "${root}/script/upstream_warnings.txt")
readonly upstream

hits=$(grep -nE -e "${pattern}" | grep -vE -e "^[0-9]+:${codeql_documentation#^}" | grep -vE -e "${upstream}" || true)
if [[ -n ${hits} ]]; then
  printf '%s\n' "${hits}"
  exit 1
fi
