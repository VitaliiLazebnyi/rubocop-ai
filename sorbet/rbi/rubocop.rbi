# typed: true

module RuboCop
  class ConfigLoader
    def self.send(*args); end
    def self.default_configuration; end
    def self.instance_variable_set(*args); end
  end

  class Config
    def self.new(*args); end
    def tap; end
  end

  module Cop
    class Base
      def processed_source; end
      def add_offense(node, &block); end
    end
    module AutoCorrector; end
  end
end
