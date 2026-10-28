# Contributing to rubocop-ai

Thanks for your interest in contributing! Bug reports and pull requests are welcome on GitHub at
<https://github.com/VitaliiLazebnyi/rubocop-ai>.

## Getting started

The repository develops on the Ruby in `.ruby-version`; Ruby 3.3 and newer are supported.

```bash
bundle install
git config core.hooksPath .githooks   # optional: run the fast gates before every commit
```

## Before opening a pull request

Run the verification suite. Every gate is enforced in CI and fails the build:

```bash
bundle exec rake
```

That runs, in order:

| Task | Gate |
| --- | --- |
| `rake spec` | RSpec; 100% line **and** branch coverage, no pending or skipped examples, no Ruby warning from `lib/` or `spec/` (`spec/support/warning_guard.rb`); the shipped `config/default.yml` must load into the bundled (newest) RuboCop and all its plugins without a warning, an unknown or renamed cop, or an obsolete parameter |
| `rake rubocop` | RuboCop with its plugins (`.rubocop.yml`), including this gem's own `AI/AdverbSpam`; no todo file |
| `rake suppressions` | no inline suppression anywhere (`script/forbidden_suppressions.sh`, see below) |
| `rake typecheck` | Tapioca generates the gem RBIs, then `srb tc` must report no errors; `lib/` is `typed: strong` |
| `rake yard` | YARD must report 100% documented |
| `rake reek` / `rake flay` | no code smell (default Reek configuration) and no structural duplication |
| `rake audit` | bundler-audit: no dependency with a known vulnerability |

Not part of the default task, but also enforced in CI:

```bash
bundle exec rake mutant       # mutation testing; every mutation must be killed (see .mutant.yml)
bundle exec rake outdated     # gems, RubyGems, Bundler and Ruby at their newest, except script/outdated_holds.yml
bundle exec rake spec_oldest  # the cop specs against the oldest supported RuboCop (gemfiles/oldest.gemfile)
gem build rubocop-ai.gemspec
```

CI also runs these checks, which need tools outside the bundle:

| Workflow | Check |
| --- | --- |
| CI | markdownlint (`.markdownlint-cli2.yaml`) and typos (`_typos.toml`) over the repository |
| Workflow lint | actionlint, ShellCheck (`script/*.sh`, `.githooks/pre-commit`) and zizmor (pedantic) |
| Security | bundler-audit, dependency review, gitleaks over the full history |
| CodeQL | Ruby and GitHub Actions, `security-extended` and `security-and-quality` suites |

To run them locally: `npx markdownlint-cli2 '**/*.md'`, `typos`, `actionlint`, `shellcheck script/*.sh
.githooks/pre-commit`, `zizmor --persona pedantic .github/workflows` and `gitleaks git .`.

Mutant requires the `parser` gem, which only has a grammar for Ruby 3.3: on newer Rubies it prints warnings. Run it
on Ruby 3.3.13, as CI does; the hold and its exact upstream reason are recorded in `script/outdated_holds.yml`, and
`rake outdated` fails once a newer mutant or parser release makes it worth re-checking. While iterating, run one
subject at a time, e.g.
`bundle exec mutant run 'RuboCop::Cop::AI::AdverbSpam*'`.

## Rules

- **No inline suppressions.** Nothing may silence a linter, scanner, type checker, warning or test in place: no
  `rubocop:disable`, `:nocov:`, `:reek:`, `mutant:disable`, `gitleaks:allow`, `nosec`, `markdownlint-disable`,
  `T.unsafe`/`T.cast`/`T.bind`/`T.untyped` in `lib/`, replaced `T::Configuration` error handlers, `$VERBOSE = nil`,
  `skip`/`pending`/`focus`, and so on. Fix the cause. A rule that cannot apply to a file is configured narrowly in the
  tool's configuration file, with the reason written next to it.
- **No warnings.** Specs run with `--warnings`, and every CI job with `RUBYOPT=-W:deprecated -W:performance` (`-w` for
  the test jobs). Every workflow ends with a "Warning gate" job (`script/warning_gate.sh`) that fails the run when the
  log of any job contains a warning or a deprecation notice.
- **Behavior is specified.** Every behavioral fix needs a regression spec (tagged with its `BUGS.md` identifier), and
  every surviving mutant needs a test that kills it (or, when the mutation cannot change observable behavior, simpler
  code).
- **Dependencies are current.** Every gem, RubyGems, Bundler, the Ruby in `.ruby-version` (and every Ruby the
  workflows name, each the newest patch of its minor) and every GitHub Action (pinned to a commit SHA) is at its newest
  release. Anything that cannot be is listed in `script/outdated_holds.yml` with the upstream reason; `rake outdated`
  fails for anything else that is outdated and for a hold that is no longer needed.
- `lib/` is `# typed: strong`. Type the RuboCop APIs it calls in `sorbet/rbi/shims/rubocop.rbi` rather than loosening
  the typed sigil. Spec files are `# typed: false`: the RSpec DSL cannot be typed without `T.bind`.
- Update `CHANGELOG.md` for user-visible changes.

## Releasing

`lib/rubocop/ai/version.rb` is the single source of truth. Bump it, update `CHANGELOG.md`, commit, then push a tag
`vX.Y.Z` with the same version: the release workflow runs the full verification suite, refuses a tag that differs
from `RuboCop::AI::VERSION`, signs the gem and publishes it.
