# Bug Definitions and Anomalies

This document logs active or notable defects mapped explicitly to their requirement violations. Do NOT bloat
standard specifications or changelogs with this content. Remediation requires writing a failing deterministic test
beforehand; the regression spec of each defect carries its identifier as `bug:` metadata.

## Active Defects

None.

## Resolved Defects

- **BUG-RB-005**: The gem metadata (`changelog_uri`) linked `CHANGELOG.md`, which did not exist (the link was a 404 on
  rubygems.org), and the gem did not ship it.
  - **Violation**: Gem metadata standards (every metadata URI resolves).
  - **Resolution**: `CHANGELOG.md` is added and listed in `spec.files`. Regression spec: `spec/rubocop/ai_spec.rb`
    ("links a changelog that exists in the repository and ships with the gem").

- **BUG-RB-004**: `AI/AdverbSpam` counted every word ending in "ly" as an adverb, so ordinary comments such as
  `# Only apply this when needed`, `# Reply quickly` or `# The family assembly` were reported, and autocorrection
  deleted the words (`# Only apply this when needed` became `# this when needed`).
  - **Violation**: RC-AI-REQ-001 (flag repetitive *adverb* chains) and RC-AI-REQ-003 (preserve the surrounding
    meaning when correcting).
  - **Resolution**: Common verbs and nouns that end in "ly" (`NON_ADVERBS`: apply, reply, supply, family, ...) never
    count towards a chain; only whole words are exempted. Regression specs: `spec/rubocop/cop/ai/adverb_spam_spec.rb`
    (`bug: 'BUG-RB-004'`).

- **BUG-RB-003**: When a comment contains only comment hashes and the spam adverb chain (e.g. `## securely
  accurately`), it auto-corrected to multiple hashes (e.g. `##`) instead of a single `#`.
  - **Violation**: RC-AI-REQ-003 (the comment defaults to a single `#` when all text is stripped).
  - **Resolution**: A correction that leaves only hashes and blanks becomes `#` (`bug: 'BUG-RB-003'`).

- **BUG-RB-002**: `SPAM_PATTERN` greedily consumed the spaces before and after the adverb chain, squashing layout
  spaces (`# securely accurately done` corrected to `#done`).
  - **Violation**: Standard spacing and comment alignment requirements under `Layout/LeadingCommentSpace`.
  - **Resolution**: The pattern does not match the space before the first adverb (`bug: 'BUG-RB-002'`).

- **BUG-RB-001**: The release workflow rewrote `lib/rubocop/ai/version.rb` from the tag with `sed`, so a published gem
  could carry a version that the committed code did not.
  - **Violation**: Code signature requirement and CI/CD release workflow standard for version tagging.
  - **Resolution**: `version.rb` is the single source of truth: the release job refuses a tag that is not `vX.Y.Z` or
    that differs from `RuboCop::AI::VERSION` (`spec/rubocop/ai_spec.rb`, `bug: 'BUG-RB-001'`).

- **BUG-CI-003**: Sorbet reported `Call to method X on T.untyped` for RuboCop dependencies under `--typed strong`.
  - **Violation**: The strictest type checking requirement (RC-AI-REQ-004).
  - **Resolution**: Tapioca generates the RBIs of every gem (`rake typecheck`), and
    `sorbet/rbi/shims/rubocop.rbi` types the RuboCop, rubocop-ast and parser methods that `lib/` calls, so every file
    of `lib/` is `# typed: strong` without any `T.cast`, `T.unsafe` or `T.untyped`.

- **BUG-CI-002**: The Sorbet CI step failed with `Argument '--dir .' starts with a - but has incorrect syntax.`
  - **Violation**: The requirement to statically type check the repository with Sorbet (`srb tc`).
  - **Resolution**: `sorbet/config` gives every option and its value on separate lines.

- **BUG-CI-001**: CI failed on older Rubies because a committed `Gemfile.lock` pinned newer Bundler and gems.
  - **Violation**: The requirement to test across the full Ruby matrix.
  - **Resolution**: `Gemfile.lock` is not committed, so every job resolves the newest compatible releases; the
    `Outdated gems` job fails when one is not the newest (`script/outdated_holds.yml` lists the documented holds).
