# frozen_string_literal: true

# Suppress the warning from parser gem when running on newer Ruby versions (e.g. Ruby 4.0+)
# where parser/current loads an older Ruby parser.
module Warning
  class << self
    unless respond_to?(:orig_warn)
      alias_method :orig_warn, :warn
      def warn(msg, category: nil)
        if msg.start_with?('warning: parser/current is loading')
          # Silence this warning
        else
          orig_warn(msg, category: category)
        end
      end
    end
  end
end

require 'simplecov'
require 'simplecov-ai'

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
  add_filter '/spec/'
  add_filter '/vendor/'

  SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                    SimpleCov::Formatter::HTMLFormatter,
                                                                    SimpleCov::Formatter::AIFormatter
                                                                  ])
end

require 'rubocop'
require 'rubocop/rspec/support'
require 'rubocop-ai'
require 'sorbet-runtime'

T::Configuration.inline_type_error_handler = ->(_, _) {}
T::Configuration.call_validation_error_handler = ->(_, _) {}

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
