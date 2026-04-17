# typed: strict
# frozen_string_literal: true

require 'yaml'
require 'sorbet-runtime'

module RuboCop
  module AI
    # Injects the default configuration cleanly into RuboCop
    module Inject
      extend T::Sig

      # Applies the default config
      # @return [void]
      sig { void }
      def self.defaults!
        path = File.join(RuboCop::AI.project_root, 'config', 'default.yml')
        # We explicitly cast to handle missing typing in RuboCop YAML internals
        hash = RuboCop::ConfigLoader.send(:load_yaml_configuration, path)
        config = RuboCop::Config.new(hash, path).tap(&:make_excludes_absolute)
        RuboCop::ConfigLoader.instance_variable_set(:@default_configuration, RuboCop::ConfigLoader.default_configuration.merge(config))
      end
    end
  end
end
