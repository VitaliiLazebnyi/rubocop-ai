# typed: strong

# Signatures for the parts of the RuboCop, rubocop-ast and parser APIs that lib/ calls. These gems ship no
# Sorbet signatures, so the RBIs Tapioca generates for them leave every parameter and return value
# untyped; lib/ is `typed: strong`, which forbids calling methods on untyped values.

class Parser::Source::Comment
  sig { returns(String) }
  def text; end
end

class RuboCop::AST::ProcessedSource
  sig { returns(T::Array[Parser::Source::Comment]) }
  def comments; end
end

class RuboCop::Cop::Base
  sig { returns(RuboCop::AST::ProcessedSource) }
  def processed_source; end

  sig do
    params(
      node_or_range: T.any(Parser::Source::Comment, Parser::Source::Range, RuboCop::AST::Node),
      message: T.nilable(String),
      severity: T.nilable(Symbol),
      block: T.nilable(T.proc.params(corrector: RuboCop::Cop::Corrector).void)
    ).void
  end
  def add_offense(node_or_range, message: nil, severity: nil, &block); end
end

class RuboCop::Cop::Corrector < ::Parser::Source::TreeRewriter
  # Inherited from Parser::Source::TreeRewriter; RuboCop's corrector also accepts nodes and comments.
  sig do
    params(range: T.any(Parser::Source::Comment, Parser::Source::Range, RuboCop::AST::Node), content: String)
      .returns(T.self_type)
  end
  def replace(range, content); end
end

class RuboCop::Config
  # A configuration maps cop and department names to their settings, whose values are arbitrary YAML.
  sig { params(hash: T::Hash[String, T.anything], loaded_path: T.nilable(String)).void }
  def initialize(hash = {}, loaded_path = nil); end

  sig { void }
  def make_excludes_absolute; end

  # Delegated to the underlying Hash (def_delegators), hence the forwarding parameters; only
  # `merge(other_config)` is called, which merges the settings of +other_config+ into a new Hash.
  sig do
    params(args: RuboCop::Config, kwargs: T.anything, block: T.nilable(T.proc.void))
      .returns(T::Hash[String, T.anything])
  end
  def merge(*args, **kwargs, &block); end

  sig { returns(T.nilable(String)) }
  def loaded_path; end
end

class RuboCop::ConfigLoader
  class << self
    sig { params(absolute_path: String).returns(T::Hash[String, T.anything]) }
    def load_yaml_configuration(absolute_path); end

    sig { returns(RuboCop::Config) }
    def default_configuration; end

    sig { params(_arg0: RuboCop::Config).returns(RuboCop::Config) }
    def default_configuration=(_arg0); end
  end
end
