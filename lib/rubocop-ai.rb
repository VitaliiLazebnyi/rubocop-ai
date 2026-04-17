# typed: strict
# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/ai'
require_relative 'rubocop/ai/version'
require_relative 'rubocop/ai/inject'
require_relative 'rubocop/cop/ai/adverb_spam'

RuboCop::AI::Inject.defaults!
