# typed: true
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::AI::AdverbSpam, :config, req_RB_AI_001: true, req_RB_AI_003: true do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and auto-corrects an AI spam comment' do
    expect_offense(<<~RUBY)
      # @param c_m [String] securely accurately dynamically visually intuitively
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
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
      ^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def blank; end
    RUBY

    expect_correction(<<~RUBY)
      #
      def blank; end
    RUBY
  end
end
