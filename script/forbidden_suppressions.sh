#!/usr/bin/env bash
# Fails when a tracked file silences a linter, scanner, type checker, warning or test, or weakens typing.
# Inline suppressions are forbidden everywhere in this repository (see CONTRIBUTING.md): fix the cause.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# This script names the patterns, and CONTRIBUTING.md and gem_practices_guide.md document the rules, so they
# are not scanned for them. The generated gem RBIs (if present) are not part of the repository.
files=$(git ls-files -z -- . ':(exclude)script/forbidden_suppressions.sh' ':(exclude)CONTRIBUTING.md' \
  ':(exclude)gem_practices_guide.md' ':(exclude)sorbet/rbi/gems' | tr '\0' '\n')

status=0
check() {
  local description=$1 pattern=$2 scope=${3:-.}
  local hits
  hits=$(printf '%s\n' "$files" | grep -E "^${scope}" | xargs -r grep -nEH -e "$pattern" -- || true)
  if [ -n "$hits" ]; then
    printf 'Forbidden (%s):\n%s\n\n' "$description" "$hits"
    status=1
  fi
}

check 'RuboCop directive' 'rubocop:(disable|enable|todo)'
check 'RuboCop todo file' 'inherit_from:.*todo'
check 'Reek suppression' ':reek:'
check 'SimpleCov exclusion' ':nocov:|nocov_token'
check 'mutant suppression' 'mutant:disable'
check 'gitleaks allow' 'gitleaks:allow'
check 'zizmor ignore' 'zizmor: ?ignore'
check 'shellcheck disable' 'shellcheck +disable'
check 'markdownlint disable' 'markdownlint-(disable|capture|configure-file)'
check 'typos ignore' 'typos: ?(ignore|off)|spellchecker: ?(disable|ignore)'
check 'LGTM/CodeQL suppression' 'lgtm\[|codeql\[|codeql-disable|lgtm: ?ignore'
check 'nosec' 'nosec'
check 'warning silencing' '[$]VERBOSE *= *(nil|false)|Warning\.ignore|Warning\[:[a-z_]+\] *= *false|silence_warnings|[$]stderr *= *File::NULL|RUBYOPT=.*-W0| -W0\b'
check 'Sorbet runtime check silencing' 'T::Configuration\.[a-z_]*(handler|checks?)[a-z_]* *='
check 'skipped or focused test' '^[[:space:]]*([xf](it|describe|context|specify|example)|skip|pending)([[:space:]]|\()|focus: *true|, *:focus|, *(skip|pending): ' '(spec|script)/'
# lib/ is `typed: strong`; spec files are `typed: false` because the RSpec DSL cannot be typed without T.bind.
check 'Sorbet escape hatch' 'T\.(unsafe|cast|bind|untyped)\b|typed: *(ignore|false|true|strict)\b' 'lib/'
check 'Sorbet sigil that skips the file' 'typed: *ignore\b'

exit "$status"
