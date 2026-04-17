# frozen_string_literal: true

require_relative 'lib/rubocop/ai/version'

Gem::Specification.new do |spec|
  spec.name          = 'rubocop-ai'
  spec.version       = RuboCop::AI::VERSION
  spec.authors       = ['Vitalii Lazebnyi']
  spec.email         = ['vitalii.lazebnyi.github@gmail.com']

  spec.summary       = 'RuboCop extensions for broken AI-generated comments detection.'
  spec.description   = 'A RuboCop extension aimed at detecting and remediating boilerplate, spam, or AI-hallucinated artifacts across codebases.'
  spec.homepage      = 'https://github.com/VitaliiLazebnyi/rubocop-ai'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.7'

  # Security: Code Signing Setup
  spec.cert_chain = ['certs/rubocop-ai-public_cert.pem']
  spec.signing_key = File.expand_path('~/.gem/gem-private_key.pem') if $PROGRAM_NAME.end_with?('gem') && File.exist?(File.expand_path('~/.gem/gem-private_key.pem'))

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('{exe,lib,certs}/**/*') + %w[README.md rubocop-ai.gemspec]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core runtime dependencies
  spec.add_dependency 'rubocop', '>= 1.50'
  spec.add_dependency 'sorbet-runtime', '>= 0.5'

  # Development dependencies
  spec.add_development_dependency 'rake', '>= 13.0'
  spec.add_development_dependency 'rspec', '>= 3.12'
  spec.add_development_dependency 'rubocop-md', '~> 1.1'
  spec.add_development_dependency 'rubocop-performance', '~> 1.19'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-thread_safety', '~> 0.5'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'sorbet', '>= 0.5'
  spec.add_development_dependency 'tapioca', '>= 0.11'
  spec.add_development_dependency 'yard', '>= 0.9'
  spec.add_development_dependency 'yard-sorbet', '~> 0.8'
end
