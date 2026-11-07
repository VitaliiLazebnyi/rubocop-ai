# Copyright (c) 2026 Vitalii Lazebnyi
# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'open3'
require 'rspec/core/rake_task'
require 'sorbet-runtime'
require 'tmpdir'

# Every Ruby source of the repository that the code quality tools (Reek, Flay, Flog, debride) check.
RUBY_SOURCES = %w[lib script spec Rakefile rubocop-ai.gemspec].freeze

# Flog score above which a single method counts as too complex and must be split up.
FLOG_METHOD_THRESHOLD = 20

# Output of `yard stats` when every object, public or not, is documented.
FULLY_DOCUMENTED = '100.00% documented'

# Runs YARD with the yard-sorbet plugin. The plugin is loaded once YARD is: named in .yardopts (`--plugin`), YARD
# loads it while `yard.rb` itself is still loading, and the plugin's `require 'yard'` is a circular require, which
# Ruby warns about. The external encoding is UTF-8 from the start, so that YARD does not change it (another warning).
YARD_COMMAND = [
  'bundle',
  'exec',
  'ruby',
  '-EUTF-8:UTF-8',
  '-e',
  'require "yard"; require "yard-sorbet"; YARD::CLI::CommandParser.run(*ARGV)',
  '--'
].freeze

# Methods debride cannot see a caller for: RuboCop calls them by name, through `Cop::Base`.
DEBRIDE_CALLBACKS = %w[on_new_investigation].freeze

# Every category of Ruby warnings.
RUBY_WARNINGS = %w[-w -W:deprecated -W:performance].freeze

# `env` options that drop Bundler's environment.
BUNDLER_ENVIRONMENT = %w[-u BUNDLE_GEMFILE -u BUNDLE_BIN_PATH -u BUNDLER_SETUP -u RUBYLIB].freeze

# The specs that need only the runtime dependencies; the others load the development tools.
OLDEST_SPECS = %w[spec/rubocop/cop spec/rubocop/ai/inject_spec.rb spec/rubocop/ai_spec.rb].freeze

# Runs the tools whose report, not only their exit status, says whether they found anything.
module Report
  extend T::Sig

  # Prints the report of a tool and fails unless the tool succeeded and the report holds the text that means
  # "no findings".
  #
  # @param command [Array<String>] the command line of the tool
  # @param clean [String] the text of a report without findings
  # @param failure [String] the message to fail with otherwise
  # @return [void]
  sig { params(command: T::Array[String], clean: String, failure: String).void }
  def self.require_clean(command, clean, failure)
    output, status = Open3.capture2e(*command)
    puts(output)
    abort(failure) unless status.success? && output.include?(clean)
  end
end

RSpec::Core::RakeTask.new(:spec)

desc 'Run the specs of the cop and its configuration against the oldest supported RuboCop (gemfiles/oldest.gemfile)'
task :spec_oldest do
  Bundler.with_unbundled_env do
    # RubyGems itself prints Ruby warnings while it installs gems, so the installation runs without them.
    sh('env', 'RUBYOPT=', 'BUNDLE_GEMFILE=gemfiles/oldest.gemfile', 'bundle', 'install', '--quiet')
    sh('env', 'BUNDLE_GEMFILE=gemfiles/oldest.gemfile', 'bundle', 'exec', 'rspec', *OLDEST_SPECS)
  end
end

desc 'Run RuboCop with every cop of every plugin (no todo file, no inline directives)'
task :rubocop do
  sh('bundle', 'exec', 'rubocop')
end

desc 'Fail on inline suppressions of any linter, scanner, type checker, warning or test'
task :suppressions do
  sh('script/forbidden_suppressions.sh')
end

desc 'Generate the gem RBIs with Tapioca, then run the Sorbet type checker'
task :typecheck do
  sh('bundle', 'exec', 'tapioca', 'gem', '--all')
  # Tapioca already merges the RBIs that gems ship themselves (e.g. prism, spoom) into the generated ones;
  # srb must not load them a second time.
  sh('env', 'SRB_SKIP_GEM_RBIS=1', 'bundle', 'exec', 'srb', 'tc')
end

desc 'Build the YARD documentation (any warning fails) and require every object, public or not, to be documented'
task :yard do
  sh(*YARD_COMMAND, 'doc', '--fail-on-warning', '--no-save', '--no-output')
  Report.require_clean([*YARD_COMMAND, 'stats', '--list-undoc'], FULLY_DOCUMENTED, 'YARD: undocumented objects found')
end

desc 'Fail on any code smell (default Reek configuration, no exclusions)'
task :reek do
  sh('bundle', 'exec', 'reek', *RUBY_SOURCES)
end

desc 'Fail on any structural duplication (Flay, default mass)'
task :flay do
  Report.require_clean(
    ['bundle', 'exec', 'flay', *RUBY_SOURCES],
    'Total score (lower is better) = 0',
    'Flay: duplicated code found'
  )
end

desc "Fail on any method with a Flog score above #{FLOG_METHOD_THRESHOLD}"
task :flog do
  report, status = Open3.capture2e('bundle', 'exec', 'flog', '--all', '--methods-only', *RUBY_SOURCES)
  puts(report)
  abort('Flog failed') unless status.success?
  complex =
    report.scan(/^\s*(\d+\.\d+): (.+?)\s+\S+:\d+(?:-\d+)?$/).select do |score, _|
      Float(score) > FLOG_METHOD_THRESHOLD
    end
  abort("Flog: methods scoring above #{FLOG_METHOD_THRESHOLD}: #{complex.map(&:last).join(', ')}") unless complex.empty?
end

desc 'Fail on any method that nothing calls (debride; see DEBRIDE_CALLBACKS)'
task :debride do
  Dir.mktmpdir('debride') do |directory|
    callbacks = File.join(directory, 'callbacks.txt')
    File.write(callbacks, DEBRIDE_CALLBACKS.join("\n"))
    Report.require_clean(
      ['bundle', 'exec', 'debride', '--whitelist', callbacks, *RUBY_SOURCES],
      'Total suspect LOC: 0',
      'debride: methods without a caller found'
    )
  end
end

desc 'Audit gem dependencies for known vulnerabilities'
task :audit do
  sh('bundle', 'exec', 'bundler-audit', 'check', '--update')
end

desc 'Build the gem strictly (any warning fails), then install it into an empty GEM_HOME and load it'
task :package do
  specification = Gem::Specification.load('rubocop-ai.gemspec')
  Dir.mktmpdir('rubocop-ai-package') do |home|
    # An empty HOME and GEM_HOME, without Bundler's environment: the gem is built unsigned (the release workflow
    # signs it), and the smoke test sees only the installed gem and the gems it depends on.
    isolated = ['env', *BUNDLER_ENVIRONMENT, "HOME=#{home}", "GEM_HOME=#{home}", "GEM_PATH=#{home}"]
    sh(*isolated, 'gem', 'build', '--strict', '--output', "#{home}/package.gem", 'rubocop-ai.gemspec')
    # RubyGems itself prints Ruby warnings while it installs gems, so only loading the gem runs with them on.
    sh(*isolated, 'RUBYOPT=', 'gem', 'install', '--no-document', "#{home}/package.gem")
    sh(*isolated, 'ruby', *RUBY_WARNINGS, '-e', 'require "rubocop-ai"; puts RuboCop::AI::VERSION')
  end
  puts("Built, installed and loaded #{specification.full_name}")
end

desc 'Fail on anything outdated that is not on the documented hold list (script/outdated_holds.yml)'
task :outdated do
  ruby('script/outdated.rb')
end

desc 'Fail on dependencies below the OpenSSF Scorecard threshold that are not on the allowlist'
task :scorecard do
  ruby('script/scorecard.rb')
end

desc 'Run mutation testing (see .mutant.yml)'
task :mutant do
  sh('bundle', 'exec', 'mutant', 'run')
end

task default: %i[spec rubocop suppressions typecheck yard reek flay flog debride audit package]
