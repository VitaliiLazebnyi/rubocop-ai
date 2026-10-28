# frozen_string_literal: true

require_relative 'lib/rubocop/ai/version'

Gem::Specification.new do |spec|
  spec.name          = 'rubocop-ai'
  spec.version       = RuboCop::AI::VERSION
  spec.authors       = ['Vitalii Lazebnyi']
  spec.email         = ['vitalii.lazebnyi.github@gmail.com']

  spec.summary       = 'RuboCop extensions for broken AI-generated comments detection.'
  spec.description   = 'A RuboCop extension aimed at detecting and remediating boilerplate, spam, ' \
                       'or AI-hallucinated artifacts across codebases.'
  spec.homepage      = 'https://github.com/VitaliiLazebnyi/rubocop-ai'
  spec.license       = 'MIT'

  # Ruby 3.3 is the oldest Ruby that is still maintained upstream and that the current development
  # toolchain (RuboCop plugins, Sorbet, SimpleCov, Mutant) installs on; CI tests every supported minor.
  spec.required_ruby_version = '>= 3.3'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Code signing: the gem is signed only when the private key is present and not empty
  # (an unset CI secret leaves an empty file behind).
  spec.cert_chain = [File.expand_path('certs/rubocop-ai-public_cert.pem', __dir__)]
  private_key_path = File.expand_path('~/.gem/gem-private_key.pem')
  spec.signing_key = private_key_path if File.exist?(private_key_path) && File.size(private_key_path) > 100

  # Internal development documents (BUGS.md, REQUIREMENTS.md, ...) are not shipped.
  spec.files = Dir.glob('{exe,lib,certs,config}/**/*') + %w[README.md LICENSE.txt CHANGELOG.md rubocop-ai.gemspec]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core runtime dependencies.
  # RuboCop 1.56 is the oldest release CI runs the suite against (gemfiles/oldest.gemfile): older releases load
  # base64 from the standard library, which Ruby warns about on 3.3 and no longer ships as a default gem from 3.4.
  spec.add_dependency 'rubocop', '>= 1.56'
  spec.add_dependency 'sorbet-runtime', '>= 0.5'

  # Test suite.
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'simplecov', '~> 1.3'
  spec.add_development_dependency 'simplecov-ai', '~> 0.11'

  # Quality tooling (linting, typing, documentation, mutation testing, dependency audit).
  # Fails the build on dependencies with known vulnerabilities.
  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  # Structural duplication detection.
  spec.add_development_dependency 'flay', '~> 2.14'
  # Mutation testing (free for open source via `usage: opensource`).
  spec.add_development_dependency 'mutant-rspec', '~> 0.17'
  # Code smell detection.
  spec.add_development_dependency 'reek', '~> 6.6'
  # Rake tasks.
  spec.add_development_dependency 'rake', '~> 13.4'
  # Linter plugins (RuboCop itself is a runtime dependency).
  spec.add_development_dependency 'rubocop-md', '~> 2.0'
  spec.add_development_dependency 'rubocop-performance', '~> 1.27'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.10'
  spec.add_development_dependency 'rubocop-sorbet', '~> 0.17'
  spec.add_development_dependency 'rubocop-thread_safety', '~> 0.8'
  # Static type checker.
  spec.add_development_dependency 'sorbet', '~> 0.6'
  # Generates the RBI files of the dependencies that Sorbet checks against (`rake typecheck`).
  spec.add_development_dependency 'tapioca', '~> 0.20'
  # API documentation (must stay 100% documented) and its Sorbet plugin.
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'yard-sorbet', '~> 0.9'
end
