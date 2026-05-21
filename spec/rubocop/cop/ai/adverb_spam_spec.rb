# typed: true
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::AI::AdverbSpam, :config, :req_RB_AI_001, :req_RB_AI_003 do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and auto-corrects an AI spam comment' do
    expect_offense(<<~RUBY)
      # @param c_m [String] securely accurately dynamically visually intuitively
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AI/AdverbSpam: Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def foo; end
    RUBY

    expect_correction(<<~RUBY)
      # @param c_m [String]
      def foo; end
    RUBY
  end

  it 'does not register an offense for normal, single adverbs' do
    expect_no_offenses(<<~RUBY)
      # Calculates the thing successfully
      def bar; end
    RUBY
  end

  it 'reduces to just a hash if all words are removed' do
    expect_offense(<<~RUBY)
      # securely accurately
      ^^^^^^^^^^^^^^^^^^^^^ AI/AdverbSpam: Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def blank; end
    RUBY

    expect_correction(<<~RUBY)
      #
      def blank; end
    RUBY
  end

  it 'preserves leading layout spacing correctly before surrounding text (BUG-RB-002)', :bug_RB_AI_002 do
    expect_offense(<<~RUBY)
      # securely accurately done
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ AI/AdverbSpam: Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def layout_space; end
    RUBY

    expect_correction(<<~RUBY)
      # done
      def layout_space; end
    RUBY
  end

  it 'preserves layout space for parameter docs with trailing text (BUG-RB-002)', :bug_RB_AI_002 do
    expect_offense(<<~RUBY)
      # @param x [String] securely accurately dynamically done
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AI/AdverbSpam: Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def param_space; end
    RUBY

    expect_correction(<<~RUBY)
      # @param x [String] done
      def param_space; end
    RUBY
  end

  it 'defaults multiple hashes to a single hash when all text is stripped (BUG-RB-003)', :bug_RB_AI_003 do
    expect_offense(<<~RUBY)
      ## securely accurately
      ^^^^^^^^^^^^^^^^^^^^^^ AI/AdverbSpam: Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def double_hash; end
    RUBY

    expect_correction(<<~RUBY)
      #
      def double_hash; end
    RUBY
  end
end
