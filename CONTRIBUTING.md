# Contributing to `rubocop-ai`

Thanks for your interest in contributing! Bug reports and pull requests are welcome on GitHub at
<https://github.com/VitaliiLazebnyi/rubocop-ai>.

## Getting started

The repository develops on the Ruby in `.ruby-version`; Ruby 3.3 and newer are supported.

```bash
bundle install
script/install_tools.sh ~/.local/rubocop-ai-tools   # Linux x86-64: the linters of tools/, pinned by SHA-256
git config core.hooksPath .githooks                  # optional: run the fast checks before every commit
```

On other platforms, install the versions of `tools/releases.txt` and `tools/requirements.txt` with the tool's own
release or package manager (`pip install --require-hashes -r tools/requirements.txt` works everywhere).

## Before opening a pull request

Run every check. CI runs each of them through the same script, and every one fails the build:

```bash
script/check                  # every check, in the order below
script/check rubocop spec     # only the named ones
```

A check fails when its command fails, and when its output holds a single warning or deprecation notice
(`script/warnings.sh`). Every Ruby command runs with `RUBYOPT=-w -W:deprecated -W:performance`.

| Check          | Gate                                                                                             |
| -------------- | ------------------------------------------------------------------------------------------------ |
| `suppressions` | no inline suppression anywhere (`script/forbidden_suppressions.sh`, see below)                   |
| `rubocop`      | RuboCop with every cop of every plugin enabled (`.rubocop.yml`), including `AI/AdverbSpam`       |
| `spec`         | RSpec; 100% line, branch and method coverage of every file; no pending or skipped example        |
| `spec_oldest`  | the cop specs against the oldest supported RuboCop (`gemfiles/oldest.gemfile`)                   |
| `typecheck`    | Tapioca, then `srb tc`: `lib/` is `typed: strong`, every other Ruby file `typed: strict`         |
| `yard`         | YARD builds without a warning, and every object, public or not, is documented                    |
| `reek`         | no code smell (default Reek configuration) in `lib/`, `script/`, `spec/`, Rakefile and gemspec   |
| `flay`         | no structural duplication (default mass)                                                         |
| `flog`         | no method with a Flog score above 20                                                             |
| `debride`      | no method without a caller (except RuboCop's callbacks, see `Rakefile`)                          |
| `audit`        | bundler-audit: no dependency with a known vulnerability                                          |
| `package`      | `gem build --strict`, then the gem installs into an empty `GEM_HOME` and loads without a warning |
| `mutant`       | mutation testing: every mutation is killed (see `.mutant.yml`)                                   |
| `outdated`     | gems, Ruby, actions and tools at their newest release, except `script/outdated_holds.yml`        |
| `scorecard`    | OpenSSF Scorecard of 3 or more for every gem and action, except `script/scorecard_allowlist.yml` |
| `markdown`     | rumdl, every rule (`.rumdl.toml`)                                                                |
| `yaml`         | `yamllint --strict`, every rule (`.yamllint.yaml`)                                               |
| `editorconfig` | editorconfig-checker on every tracked file (`.editorconfig`)                                     |
| `shellcheck`   | ShellCheck with every optional check, at style severity                                          |
| `shfmt`        | shfmt, with the settings of `.editorconfig`                                                      |
| `actionlint`   | actionlint, with ShellCheck (every optional check) on every `run:` script                        |
| `zizmor`       | zizmor with the auditor persona, online audits included                                          |
| `typos`        | typos over the repository (`_typos.toml`)                                                        |
| `gitleaks`     | gitleaks over the full history                                                                   |

CI also runs dependency review (pull requests; any vulnerability, of any severity and scope, fails), CodeQL (Ruby and
GitHub Actions, `security-extended` and `security-and-quality`) and the OpenSSF Scorecard. Every workflow ends with a
"Warning gate" job (`script/warning_gate.sh`) that fails the run when the log of any of its jobs holds a warning.

Mutant requires the `parser` gem, which only has a grammar for Ruby 3.3: on newer Rubies it prints warnings. Run
`script/check mutant` on Ruby 3.3.13, as CI does; the hold and its exact upstream reason are recorded in
`script/outdated_holds.yml`, and `rake outdated` fails once a newer mutant or parser release makes it worth
re-checking. While iterating, run one subject at a time, e.g. `bundle exec mutant run 'RuboCop::Cop::AI::AdverbSpam*'`.

## Rules

- **No inline suppressions.** Nothing may silence a linter, scanner, type checker, warning or test in place: no
  `rubocop:disable`, `:nocov:`, `:reek:`, `mutant:disable`, `gitleaks:allow`, `nosec`, `rumdl-disable`,
  `yamllint disable`, `shellcheck disable`, `T.unsafe`/`T.cast`/`T.bind`/`T.untyped`, replaced `T::Configuration`
  error handlers, `$VERBOSE = nil`, `skip`/`pending`/`focus`, and so on. Fix the cause. A rule that cannot apply to a
  file is configured narrowly in the tool's configuration file, with the reason written next to it.
- **No warnings.** The only warnings that do not count are those of third-party gems listed, each with its exact
  file, line, message and gem release, in `script/upstream_warnings.txt`.
- **Behavior is specified.** Every behavioral fix needs a regression spec (tagged with its `BUGS.md` identifier), and
  every surviving mutant needs a test that kills it (or, when the mutation cannot change observable behavior, simpler
  code).
- **Dependencies are current.** Every gem, RubyGems, Bundler, the Ruby in `.ruby-version` (and every Ruby the
  workflows name, each the newest patch of its minor), every GitHub Action (pinned to a commit SHA) and every tool of
  `tools/` is at its newest release. Anything that cannot be is listed in `script/outdated_holds.yml` with the
  upstream reason; `rake outdated` fails for anything else that is outdated and for a hold that is no longer needed.
- `lib/` is `# typed: strong`. Type the RuboCop APIs it calls in `sorbet/rbi/shims/rubocop.rbi` rather than loosening
  the typed sigil. The example files of the specs are `# typed: false`: the RSpec DSL cannot be typed without
  `T.bind`; every other Ruby file is `# typed: strict`.
- Update `CHANGELOG.md` for user-visible changes.

## Releasing

`lib/rubocop/ai/version.rb` is the single source of truth. Bump it, update `CHANGELOG.md`, commit, then push a tag
`vX.Y.Z` with the same version: the release workflow runs the verification suite, refuses a tag that differs from
`RuboCop::AI::VERSION`, signs the gem and publishes it from the `release` environment.
