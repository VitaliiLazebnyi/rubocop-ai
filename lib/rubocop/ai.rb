# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

# Top-level namespace for RuboCop
module RuboCop
  # Container namespace for the AI-related cops and extensions
  module AI
    # Error boundary for AI cops
    class Error < StandardError; end

    # Project root finder
    # @return [String]
    extend T::Sig

    sig { returns(String) }
    def self.project_root
      T.let(File.join(__dir__ || '', '..', '..'), String)
    end
  end
end
