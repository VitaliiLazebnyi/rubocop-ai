# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in rubocop-ai.gemspec
gemspec

group :test, :development do
  gem 'rspec', '~> 3.12'
  gem 'rubocop-performance', '~> 1.19'
  gem 'rubocop-rake', '~> 0.6'
  gem 'rubocop-rspec', '~> 2.24'
  gem 'rubocop-md', '~> 1.1'
  gem 'rubocop-thread_safety', '~> 0.5'
  
  # Sorbet deps
  gem 'sorbet', '~> 0.5', group: :development
  gem 'yard-sorbet', '~> 0.8'
  gem 'yard', '~> 0.9'

  gem 'simplecov', '~> 0.22', require: false
  gem 'rake', '~> 13.0'
end
