# typed: strong
# frozen_string_literal: true

require 'rubocop'
require 'sorbet-runtime'

module RuboCop
  module AI
    # Injects the default configuration of this extension into RuboCop.
    module Inject
      extend T::Sig

      # Adds the cops of +config/default.yml+, with their settings, to RuboCop's default configuration.
      # The rest of RuboCop's defaults (including the +Preview+ settings of its own cops) is kept as is.
      #
      # @return [void]
      sig { void }
      def self.defaults!
        config = Config.new(ConfigLoader.load_yaml_configuration(File.join(AI.project_root, 'config', 'default.yml')))
        config.make_excludes_absolute
        default = ConfigLoader.default_configuration
        ConfigLoader.default_configuration = Config.new(default.merge(config), default.loaded_path)
      end
    end
  end
end
