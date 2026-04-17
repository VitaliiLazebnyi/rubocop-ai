# frozen_string_literal: true

require_relative 'lib/rubocop/ai/version'

Gem::Specification.new do |spec|
  spec.name          = 'rubocop-ai'
  spec.version       = RuboCop::AI::VERSION
  spec.authors       = ['AI Developer']
  spec.email         = ['developer@example.com']

  spec.summary       = 'RuboCop extensions for AI-generated code detection.'
  spec.description   = 'A RuboCop extension aimed at detecting and remediating boilerplate, spam, or AI-hallucinated artifacts across codebases.'
  spec.homepage      = 'https://github.com/example/rubocop-ai'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 4.0.2'

  # Security: Code Signing Setup
  spec.cert_chain  = ['certs/rubocop-ai-public_cert.pem']
  spec.signing_key = File.expand_path('~/.gem/gem-private_key.pem') if $PROGRAM_NAME.end_with?('gem') && File.exist?(File.expand_path('~/.gem/gem-private_key.pem'))

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core runtime dependency
  spec.add_dependency 'rubocop', '>= 1.50', '< 2.0'
  spec.add_dependency 'sorbet-runtime', '>= 0.5.10000'

  # Development dependencies handled mainly via Gemfile lock in dev environment
end
