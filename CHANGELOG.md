# Changelog

All notable changes to this project are documented in this file. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- `AI/AdverbSpam` no longer counts common verbs and nouns that end in "ly" (such as "apply",
  "reply", "supply" or "family") as adverbs. A comment like `# Only apply this when needed` was
  reported, and autocorrection deleted "Only apply" from it.
- The gem metadata links a changelog that exists (this file), and the file ships with the gem.

### Changed

- Ruby 3.3 or newer is required (Ruby 2.7 to 3.2 have reached their end of life upstream, and the
  development toolchain no longer installs on them).
- RuboCop 1.56 or newer is required: it is the oldest release the suite passes against without a warning
  on Ruby 3.3 (older releases load `base64` from the standard library, which Ruby 3.4 no longer ships as a
  default gem). CI tests it on every change.
- The default configuration is merged into RuboCop's through its public `ConfigLoader` API
  (`load_yaml_configuration`, `merge_with_default` and `default_configuration=`) instead of a private
  method call and an instance-variable write.
- Releases are published only from a tag that matches `RuboCop::AI::VERSION`.
