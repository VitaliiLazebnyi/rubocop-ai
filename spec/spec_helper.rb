# Copyright (c) 2026 Vitalii Lazebnyi
# typed: strict
# frozen_string_literal: true

# Must come first: it has to see warnings emitted while lib/ and spec/ are loaded.
require_relative 'support/warning_guard'

require 'simplecov'
require 'simplecov-ai'

# Raised after the suite when it contains pending or skipped examples.
class UnfinishedExamples < StandardError; end

SimpleCov::Formatter::AIFormatter.configure do |config|
  config.report_path = 'coverage/ai_report.md'
  config.output_to_console = false
end

# Mutation runs execute the suite thousands of times against deliberately broken
# code; the coverage gate is meaningless (and noisy) there.
unless defined?(Mutant)
  # Every line, branch and method of every file, not only of the project as a whole.
  %i[line branch method].each do |criterion|
    SimpleCov.coverage(criterion) do |rule|
      rule.minimum(100)
      rule.minimum(100, per: :file)
    end
  end
  SimpleCov.skip(%r{/spec/})
  SimpleCov.skip(%r{/vendor/})
  SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::AIFormatter]
  SimpleCov.start
end

require 'rubocop'
require 'rubocop-ai'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand(config.seed)

  # Ruby warnings from lib/ or spec/ are failures, never noise.
  config.before(:suite) { WarningGuard.check!('Ruby warnings while loading') }
  config.after { WarningGuard.check!('Ruby warnings emitted by this example') }

  # Pending and skipped examples hide missing behavior: the suite must not contain any.
  config.after(:suite) do
    unfinished =
      RSpec.world.all_examples.select do |example|
        example.execution_result.status == :pending || example.skipped? || example.pending?
      end
    unless unfinished.empty?
      raise(UnfinishedExamples, "Pending or skipped examples:\n#{unfinished.map(&:full_description).join("\n")}")
    end
  end
end
