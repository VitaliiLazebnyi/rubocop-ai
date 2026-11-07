# typed: false
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuboCop::Cop::AI::AdverbSpam, :config, requirements: %w[RC-AI-REQ-001 RC-AI-REQ-003] do
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

  it 'preserves leading layout spacing correctly before surrounding text', bug: 'BUG-RB-002' do
    expect_offense(<<~RUBY)
      # securely accurately done
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def layout_space; end
    RUBY

    expect_correction(<<~RUBY)
      # done
      def layout_space; end
    RUBY
  end

  it 'preserves layout space for parameter docs with trailing text', bug: 'BUG-RB-002' do
    expect_offense(<<~RUBY)
      # @param x [String] securely accurately dynamically done
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def param_space; end
    RUBY

    expect_correction(<<~RUBY)
      # @param x [String] done
      def param_space; end
    RUBY
  end

  it 'defaults multiple hashes to a single hash when all text is stripped', bug: 'BUG-RB-003' do
    expect_offense(<<~RUBY)
      ## securely accurately
      ^^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def double_hash; end
    RUBY

    expect_correction(<<~RUBY)
      #
      def double_hash; end
    RUBY
  end

  it 'does not count verbs and nouns ending in "ly" as adverbs', bug: 'BUG-RB-004' do
    expect_no_offenses(<<~RUBY)
      # Only apply this when needed
      # Reply quickly
      # The family assembly
      def not_spam; end
    RUBY
  end

  it 'still flags an adverb chain next to a word ending in "ly" that is not an adverb', bug: 'BUG-RB-004' do
    expect_offense(<<~RUBY)
      # apply securely accurately
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def apply; end
    RUBY

    expect_correction(<<~RUBY)
      # apply
      def apply; end
    RUBY
  end

  it 'only exempts whole words, not adverbs that start with a non-adverb' do
    expect_offense(<<~RUBY)
      # bullyingly securely
      ^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def bullying; end
    RUBY

    expect_correction(<<~RUBY)
      #
      def bullying; end
    RUBY
  end

  it 'removes every adverb chain of a comment and keeps the text between them' do
    expect_offense(<<~RUBY)
      # Returns securely accurately the value dynamically visually
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      def value; end
    RUBY

    expect_correction(<<~RUBY)
      # Returns the value
      def value; end
    RUBY
  end

  it 'matches adverbs regardless of their case' do
    expect_offense(<<~RUBY)
      x = 1 # SECURELY Accurately
            ^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
    RUBY

    expect_correction(<<~RUBY)
      x = 1 #
    RUBY
  end

  it 'does not join adverbs across lines of a comment block' do
    expect_no_offenses(<<~RUBY)
      # Runs securely
      # accurately formatted
      def block; end
    RUBY
  end

  it 'checks every comment of the file independently' do
    expect_offense(<<~RUBY)
      # Fine comment
      # securely accurately
      ^^^^^^^^^^^^^^^^^^^^^ Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).
      # Another fine comment
      def several; end
    RUBY

    expect_correction(<<~RUBY)
      # Fine comment
      #
      # Another fine comment
      def several; end
    RUBY
  end

  describe '.correct' do
    it 'removes every adverb chain of the comment in one pass' do
      expect(described_class.correct('# Returns securely accurately the value dynamically visually'))
        .to eq('# Returns the value')
    end

    it 'keeps a comment without an adverb chain as it is' do
      expect(described_class.correct('# Returns the value')).to eq('# Returns the value')
    end

    it 'reduces a comment that only held adverbs to a single hash' do
      expect(described_class.correct("##\t securely accurately")).to eq('#')
    end
  end
end
