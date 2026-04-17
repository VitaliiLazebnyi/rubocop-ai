# typed: true

module Parser
  module Source
    class Comment
      sig { returns(String) }
      def text; end
    end
  end
end

module RuboCop
  module AST
    class Node; end

    class ProcessedSource
      sig { returns(T::Array[Parser::Source::Comment]) }
      def comments; end
    end
  end

  module Cop
    class Corrector
      sig { params(node_or_range: T.any(Parser::Source::Comment, RuboCop::AST::Node), replacement: String).void }
      def replace(node_or_range, replacement); end
    end

    class Base
      sig { returns(RuboCop::AST::ProcessedSource) }
      def processed_source; end

      sig { params(node: Parser::Source::Comment, yield_block: T.nilable(T.proc.params(corrector: RuboCop::Cop::Corrector).void)).void }
      def add_offense(node, &yield_block); end
    end
    module AutoCorrector; end
  end

  class Config
    # We do NOT redefine tap here; Sorbet knows what tap is.
    sig { params(hash: T::Hash[T.untyped, T.untyped], base_dir_or_uri: String).void }
    def initialize(hash = {}, base_dir_or_uri = T.unsafe(nil)); end

    sig { returns(T.self_type) }
    def make_excludes_absolute; end

    sig { params(other: RuboCop::Config).returns(RuboCop::Config) }
    def merge(other); end

    sig { returns(T::Hash[String, T.untyped]) }
    def to_h; end

    sig { returns(String) }
    def loaded_path; end
  end

  class ConfigLoader
    sig { returns(RuboCop::Config) }
    def self.default_configuration; end

    sig { params(path: String).returns(T::Hash[T.untyped, T.untyped]) }
    def self.load_yaml_configuration(path); end
  end
end
