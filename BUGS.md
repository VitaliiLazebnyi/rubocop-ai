# Bug Definitions and Anomalies

This document logs active or notable defects mapped explicitly to their requirement violations. Do NOT bloat standard specifications or changelogs with this content. remediation requires writing a failing deterministic test beforehand.

## Active Defects

- **BUG-CI-003**: Sorbet throws `Call to method X on T.untyped` for RuboCop dependencies when using `--typed strong`.
  - **Violation**: The command-line `--typed strong` override breaks compilation by demanding strongly-typed responses from internal core components (e.g. `processed_source`) across `adverb_spam.rb` and `inject.rb` where generated APIs are currently untyped by Tapioca.
  - **Expected Behavioral Delta**: Providing a custom static RBI definition file (`sorbet/rbi/rubocop.rbi`) that supplies fully realized type signatures for `Parser::Source::Comment`, `RuboCop::AST::ProcessedSource`, and related RuboCop configuration internals. Adding explicit `T.cast` for reflective calls (e.g. `send`) provides absolute strict typing without compromising the `--typed strong` standard.

- **BUG-CI-002**: Sorbet Typechecker CI step failing with `Argument ‘--dir .’ starts with a - but has incorrect syntax.`
  - **Violation**: The requirement to strictly statically type check the repository with Sorbet (via `srb tc`) cannot be satisfied due to invalid CLI argument formatting injected by `sorbet/config`.
  - **Expected Behavioral Delta**: Changing `--dir .` to simply `.` in `sorbet/config` allows the arguments to be parsed correctly by `srb tc` yielding a successful type check step.

- **BUG-CI-001**: CI Pipeline failing on older Ruby versions due to `Gemfile.lock` specifying newer Bundler and Gem dependencies.
  - **Violation**: The requirement to test across a full matrix (`["2.7", "3.2", "3.3", "4.0"]`) cannot be satisfied using a static `Gemfile.lock` generated in a newer environment.
  - **Expected Behavioral Delta**: Deleting `Gemfile.lock` and `.gitignore`ing it allows `ruby/setup-ruby` to dynamically generate compliant dependencies, yielding a green CI build across all versions. This replaces programmatic RSpec reproduction since it is an infrastructure limitation.

- **BUG-RB-001**: In `release.yml`, version synchronization attempts to replace `T.let` formatting, but `lib/rubocop/ai/version.rb` uses a plain string literal `VERSION = '0.1.0'`.
  - **Violation**: Code signature requirement and CI/CD release workflow standard for dynamic version tagging.
  - **Expected Behavioral Delta**: Wrapping `VERSION` with `T.let('0.1.0', String)` in `lib/rubocop/ai/version.rb` to enable reliable string substitution in CI releases.

- **BUG-RB-002**: `SPAM_PATTERN` greedily consumes spaces before and after the adverb chain, leading to squashed layout spaces (e.g., `# securely accurately done` correcting to `#done`, and `# @param x [String] securely accurately dynamically done` correcting to `# @param x [String]done`).
  - **Violation**: Standard spacing and comment alignment requirements under `Layout/LeadingCommentSpace`.
  - **Expected Behavioral Delta**: Modifying `SPAM_PATTERN` in `adverb_spam.rb` to omit matching the leading space preceding the first adverb, allowing preceding layout spaces to remain properly intact.

- **BUG-RB-003**: When a comment contains only comment hashes and the spam adverb chain (e.g. `## securely accurately`), it auto-corrects to multiple hashes (e.g. `##`) instead of defaulting to a single `#`.
  - **Violation**: RC-AI-REQ-003 constraint requiring the comment to default to a single `#` when all text is stripped.
  - **Expected Behavioral Delta**: Enhancing the auto-correction logic in `adverb_spam.rb` to inspect if the resulting string contains only hashes and whitespace, replacing it with a single `#` if true.

