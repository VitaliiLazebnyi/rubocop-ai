# typed: false
# frozen_string_literal: true

# Must come first: it has to see warnings emitted while lib/ and spec/ are loaded.
require_relative 'support/warning_guard'

require 'simplecov'
require 'simplecov-ai'

SimpleCov::Formatter::AIFormatter.configure do |config|
  config.report_path = 'coverage/ai_report.md'
  config.output_to_console = false
end

# Mutation runs execute the suite thousands of times against deliberately broken
# code; the coverage gate is meaningless (and noisy) there.
unless defined?(Mutant)
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    SimpleCov.skip(%r{/spec/})
    SimpleCov.skip(%r{/vendor/})

    self.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                 SimpleCov::Formatter::HTMLFormatter,
                                                                 SimpleCov::Formatter::AIFormatter
                                                               ])
  end
end

require 'rubocop'
require 'rubocop-ai'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Ruby warnings from lib/ or spec/ are failures, never noise.
  config.before(:suite) do
    load_time_warnings = WarningGuard.drain
    raise "Ruby warnings while loading:\n#{load_time_warnings.join}" unless load_time_warnings.empty?
  end

  config.after do
    warnings = WarningGuard.drain
    raise "Ruby warnings emitted by this example:\n#{warnings.join}" unless warnings.empty?
  end

  # Pending and skipped examples hide missing behavior: the suite must not contain any.
  config.after(:suite) do
    unfinished = RSpec.world.all_examples.select do |example|
      example.execution_result.status == :pending || example.skipped? || example.pending?
    end
    unless unfinished.empty?
      raise "Pending or skipped examples are not allowed:\n#{unfinished.map(&:full_description).join("\n")}"
    end
  end
end
