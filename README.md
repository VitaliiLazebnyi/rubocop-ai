# rubocop-ai

`rubocop-ai` is a custom standalone RuboCop extension designed to identify and remediate AI-generated spam and stereotyped code patterns within Ruby codebases. 
It strictly enforces type-safety via Sorbet, mandates 100% test coverage, and provides zero-tolerance code scanning.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-ai'
```

And then execute:
`bundle install`

## Usage

You need to tell RuboCop to load the extension. Configure your `.rubocop.yml`:

```yaml
require:
  - rubocop-ai
```

Now you can run `rubocop` and it will automatically apply the loaded cops, including `AI/AdverbSpam`.

### Configuration
By default, the `AI/AdverbSpam` cop is enabled. If you want to disable it or configure settings:

```yaml
AI/AdverbSpam:
  Enabled: true
```

## Development

- Make sure you are using Ruby 4.0.2 or higher.
- Install dependencies: `bundle install`
- Enforce strict static typing checks: `bundle exec srb tc --typed strong`
- Ensure 100% test coverage via `bundle exec rspec`
- Generate and verify YARD documentation via `bundle exec yard stats --list-undoc`
