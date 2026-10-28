# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# Flay mass threshold. At the default (16) Flay only reports identical Sorbet `sig`
# declarations of sibling methods; from 24 up it reports every duplicated piece of logic.
FLAY_MASS = 24

# Output of `yard stats` when every public API object is documented.
FULLY_DOCUMENTED = '100.00% documented'

RSpec::Core::RakeTask.new(:spec)

# The specs that need only the runtime dependencies; the others load the development tools.
OLDEST_SPECS = %w[spec/rubocop/cop spec/rubocop/ai/inject_spec.rb spec/rubocop/ai_spec.rb].freeze

desc 'Run the specs of the cop and its configuration against the oldest supported RuboCop (gemfiles/oldest.gemfile)'
task :spec_oldest do
  Bundler.with_unbundled_env do
    sh 'env BUNDLE_GEMFILE=gemfiles/oldest.gemfile bundle install --quiet'
    sh 'env', 'BUNDLE_GEMFILE=gemfiles/oldest.gemfile', 'bundle', 'exec', 'rspec', *OLDEST_SPECS
  end
end

desc 'Run RuboCop'
task :rubocop do
  sh 'bundle exec rubocop'
end

desc 'Fail on inline suppressions of any linter, scanner, type checker, warning or test'
task :suppressions do
  sh 'script/forbidden_suppressions.sh'
end

desc 'Generate the gem RBIs with Tapioca, then run the Sorbet type checker'
task :typecheck do
  sh 'bundle exec tapioca gem --all'
  # Tapioca already merges the RBIs that gems ship themselves (e.g. prism, spoom) into the generated ones;
  # srb must not load them a second time.
  sh 'env SRB_SKIP_GEM_RBIS=1 bundle exec srb tc'
end

desc 'Fail unless every public API object is documented'
task :yard do
  output = IO.popen(%w[bundle exec yard stats --list-undoc], err: %i[child out], &:read)
  puts output
  abort 'YARD: undocumented API objects found' unless output.include?(FULLY_DOCUMENTED)
end

desc 'Fail on any code smell (default Reek configuration, no exclusions)'
task :reek do
  sh 'bundle exec reek lib'
end

desc 'Fail on any structural duplication'
task :flay do
  output = IO.popen(['bundle', 'exec', 'flay', '--mass', FLAY_MASS.to_s, 'lib'], &:read)
  puts output
  abort 'Flay: duplicated code found' unless output.start_with?('Total score (lower is better) = 0')
end

desc 'Audit gem dependencies for known vulnerabilities'
task :audit do
  sh 'bundle exec bundler-audit check --update'
end

desc 'Fail on outdated gems that are not on the documented hold list'
task :outdated do
  ruby 'script/outdated.rb'
end

desc 'Run mutation testing (see .mutant.yml)'
task :mutant do
  sh 'bundle exec mutant run'
end

task default: %i[spec rubocop suppressions typecheck yard reek flay audit]
