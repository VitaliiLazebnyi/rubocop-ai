# rubocop-ai

`rubocop-ai` is a standalone RuboCop extension that identifies and remediates AI-generated spam and stereotyped
code patterns within Ruby codebases.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-ai'
```

And then execute `bundle install`. Ruby 3.3 or newer and RuboCop 1.56 or newer are required.

## Usage

You need to tell RuboCop to load the extension. Configure your `.rubocop.yml`:

```yaml
require:
  - rubocop-ai
```

Now you can run `rubocop` and it will automatically apply the loaded cops, including `AI/AdverbSpam`.

### AI/AdverbSpam

Reports comments that contain a chain of two or more adverbs (words ending in "ly"), which malfunctioning AI
documentation generators tend to produce, and removes the chain when autocorrecting:

```ruby
# bad
# @param name [String] securely accurately dynamically visually intuitively

# good
# @param name [String] the name of the record
```

Common verbs and nouns that end in "ly" ("apply", "reply", "supply", "family", ...) are not adverbs and never count
towards a chain, so `# Only apply this when needed` is left alone. A comment that held nothing but the chain is
corrected to a single `#`.

### Configuration

By default, the `AI/AdverbSpam` cop is enabled. If you want to disable it or configure settings:

```yaml
AI/AdverbSpam:
  Enabled: true
```

## Development

The repository develops on the Ruby in `.ruby-version` and enforces a "zero warnings, zero suppressions" standard:
100% line and branch coverage, every mutant killed, `typed: strong` Sorbet signatures, 100% YARD documentation, and
no inline suppression of any tool. [CONTRIBUTING.md](CONTRIBUTING.md) lists every gate and how to run it; the short
version is:

```bash
bundle install
bundle exec rake          # specs, RuboCop, suppression scan, Sorbet, YARD, Reek, Flay, bundler-audit
bundle exec rake mutant   # mutation testing (run it on Ruby 3.3.13, see CONTRIBUTING.md)
```
