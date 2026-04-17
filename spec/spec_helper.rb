# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
  add_filter '/spec/'
  add_filter '/vendor/'
end

require 'rubocop'
require 'rubocop/rspec/support'
require 'rubocop-ai'
require 'sorbet-runtime'

T::Configuration.inline_type_error_handler = lambda { |_, _| }
T::Configuration.call_validation_error_handler = lambda { |_, _| }

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed
end
