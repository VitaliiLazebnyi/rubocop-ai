# Bug Definitions and Anomalies

This document logs active or notable defects mapped explicitly to their requirement violations. Do NOT bloat standard specifications or changelogs with this content. remediation requires writing a failing deterministic test beforehand.

## Active Defects

- **BUG-CI-001**: CI Pipeline failing on older Ruby versions due to `Gemfile.lock` specifying newer Bundler and Gem dependencies.
  - **Violation**: The requirement to test across a full matrix (`["2.7", "3.2", "3.3", "4.0"]`) cannot be satisfied using a static `Gemfile.lock` generated in a newer environment.
  - **Expected Behavioral Delta**: Deleting `Gemfile.lock` and `.gitignore`ing it allows `ruby/setup-ruby` to dynamically generate compliant dependencies, yielding a green CI build across all versions. This replaces programmatic RSpec reproduction since it is an infrastructure limitation.
