# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

# Turns every Ruby warning raised from this project's own code (lib/ and spec/)
# into a test failure. Warnings that originate in third-party gems are ignored.
module WarningGuard
  extend T::Sig

  PROJECT_ROOT = T.let(File.expand_path('../..', __dir__), String)
  OWN_DIRECTORIES = T.let([File.join(PROJECT_ROOT, 'lib'), File.join(PROJECT_ROOT, 'spec')].freeze, T::Array[String])
  LOCATION = /\A(?<path>[^:\n]+\.rb):\d+/
  COLLECTED = Thread::Queue.new
  public_constant :PROJECT_ROOT, :OWN_DIRECTORIES, :LOCATION, :COLLECTED

  class << self
    extend T::Sig

    # Returns and forgets the warnings collected so far.
    # @return [Array<String>]
    sig { returns(T::Array[String]) }
    def drain
      Array.new(COLLECTED.size) { String(COLLECTED.pop) }
    end

    # Whether +message+ names a file inside this project's lib/ or spec/ directory.
    # @param message [String] a Ruby warning message
    # @return [Boolean]
    sig { params(message: String).returns(T::Boolean) }
    def own?(message)
      match = LOCATION.match(message) or return false
      path = File.expand_path(match[:path].to_s)
      OWN_DIRECTORIES.any? { |directory| path.start_with?("#{directory}/") }
    end
  end

  # Records warnings coming from this project, then defers to Ruby's default handling.
  # @param message [String]
  # @param category [Symbol, nil]
  # @return [void]
  sig { params(message: String, category: T.nilable(Symbol)).void }
  def warn(message, category: nil)
    COLLECTED << message if WarningGuard.own?(message)
    super
  end
end

Warning[:deprecated] = true
Warning[:experimental] = true
Warning[:performance] = true
Warning.singleton_class.prepend(WarningGuard)
