# typed: strong
# frozen_string_literal: true

require 'sorbet-runtime'

# Top-level namespace for RuboCop
module RuboCop
  # Container namespace for the AI-related cops and extensions
  module AI
    extend T::Sig

    # Error boundary for AI cops
    class Error < StandardError; end

    # The root directory of the installed gem, which holds its +config/+ directory.
    #
    # @return [String]
    sig { returns(String) }
    def self.project_root
      File.expand_path('../..', __dir__)
    end
  end
end
