# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rubocop-ai.gemspec
gemspec

# HOLD (script/outdated_holds.yml): the development bundle stays on RuboCop 1.92.1. RuboCop 1.92.2 warns about the
# obsolete `IgnoredPatterns` parameter in rubocop-md 2.0.4's default configuration, and rubocop-md 3.0.0, which renames
# it, loads kramdown 2.5.2, which prints a Ruby warning. The gem itself still accepts every RuboCop >= 1.56.
gem 'rubocop', '1.92.1'
