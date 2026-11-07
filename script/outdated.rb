#!/usr/bin/env ruby
# Copyright (c) 2026 Vitalii Lazebnyi
# typed: strict
# frozen_string_literal: true

require 'json'
require 'net/http'
require 'open3'
require 'sorbet-runtime'
require 'yaml'

# Fails when anything in the toolchain is not at its newest release and is not on the documented hold list
# (script/outdated_holds.yml), or when a listed hold is no longer needed:
# - every gem of the bundle (`bundle outdated`),
# - RubyGems and Bundler,
# - the Ruby in .ruby-version, and every Ruby the workflows name (each must be the newest patch of its minor),
# - every GitHub Action, pinned to the commit of its newest release tag,
# - every release binary of tools/releases.txt,
# - the Python of the linters (.python-version), held back by a documented hold.
module Outdated
  extend T::Sig

  ROOT = T.let(File.expand_path('..', __dir__), String)
  public_constant :ROOT

  # Newest releases, as published upstream.
  module Upstream
    extend T::Sig

    # Release tags of the form `1.2.3` or `v1.2.3`, optionally peeled (`^{}`).
    RELEASE_TAG = %r{\Arefs/tags/(v?\d+\.\d+\.\d+)(\^\{\})?\z}
    public_constant :RELEASE_TAG

    # @param text [String] a version, with or without a leading +v+
    # @return [Gem::Version]
    sig { params(text: String).returns(Gem::Version) }
    def self.version(text)
      Gem::Version.new(text.delete_prefix('v'))
    end

    # @param name [String] a gem name
    # @return [String] the newest release of the gem on rubygems.org
    sig { params(name: String).returns(String) }
    def self.gem(name)
      body = Net::HTTP.get(URI("https://rubygems.org/api/v1/versions/#{name}/latest.json")).to_s
      JSON.parse(body).fetch('version').to_s
    end

    # @param name [String] a Python package name
    # @return [String] the newest release of the package on PyPI
    sig { params(name: String).returns(String) }
    def self.pypi(name)
      body = Net::HTTP.get(URI("https://pypi.org/pypi/#{name}/json")).to_s
      JSON.parse(body).fetch('info').fetch('version').to_s
    end

    # @return [Array<Gem::Version>] every Ruby release
    sig { returns(T::Array[Gem::Version]) }
    def self.rubies
      index = Net::HTTP.get(URI('https://cache.ruby-lang.org/pub/ruby/index.txt')).to_s
      index.scan(/^ruby-(\d+\.\d+\.\d+)\t/).map { |(release)| version(release.to_s) }
    end

    # The newest release tag of a GitHub repository and the commit it points to: an annotated tag lists its
    # commit under `tag^{}` (after the tag object, so it wins), a lightweight tag only under `tag`.
    #
    # @param repository [String] +owner/name+
    # @return [Array(String, String)] the tag and its commit
    sig { params(repository: String).returns([String, String]) }
    def self.tag(repository)
      tags = tags(repository)
      newest = tags.keys.max_by { |tag| version(tag) }
        .to_s
      [newest, tags.fetch(newest)]
    end

    # @param repository [String] +owner/name+
    # @return [Hash{String => String}] the commit of every release tag of a GitHub repository
    sig { params(repository: String).returns(T::Hash[String, String]) }
    def self.tags(repository)
      refs, status = Open3.capture2('git', 'ls-remote', '--tags', "https://github.com/#{repository}")
      abort("git ls-remote #{repository} failed") unless status.success?
      refs.lines.filter_map { |line| tag_entry(line) }
        .to_h
    end

    # @param line [String] a line of `git ls-remote --tags`
    # @return [Array(String, String), nil] the release tag and its commit, nil for any other ref
    sig { params(line: String).returns(T.nilable([String, String])) }
    def self.tag_entry(line)
      commit, ref = line.split
      match = Outdated::Upstream::RELEASE_TAG.match(ref.to_s)
      [match.captures.first.to_s, commit.to_s] if match
    end
  end

  # Collects every problem, so that one run reports all of them.
  class Report
    extend T::Sig

    sig { void }
    def initialize
      @problems = T.let([], T::Array[String])
    end

    # Prints what was checked.
    #
    # @param message [String]
    # @return [void]
    sig { params(message: String).void }
    def checked(message)
      puts(message)
    end

    # Records a problem.
    #
    # @param message [String]
    # @return [void]
    sig { params(message: String).void }
    def problem(message)
      @problems << message
    end

    # Prints a comparison with the newest release, and records a problem unless +current+ is +newest+.
    #
    # @param subject [String] what is compared
    # @param current [String] its version
    # @param newest [String] the newest release
    # @return [void]
    sig { params(subject: String, current: String, newest: String).void }
    def compare(subject, current, newest)
      checked("#{subject}: #{current} (newest #{newest})")
      problem("OUTDATED: #{subject} #{current} -> #{newest}") unless current == newest
    end

    # Prints every problem.
    #
    # @return [Boolean] whether there is none
    sig { returns(T::Boolean) }
    def passed?
      @problems.each { |message| warn(message) }
      @problems.empty?
    end
  end

  # The outdated gems of the bundle, as `bundle outdated --parseable` lists them.
  module Bundle
    extend T::Sig

    # One line of `bundle outdated --parseable`.
    OUTDATED_LINE = /\A(\S+) \(newest ([^,\s]+), installed ([^,)\s]+)/
    # `bundle outdated` refuses to run in deployment mode, which the bundler cache of `ruby/setup-ruby` turns on.
    ENVIRONMENT = T.let({ BUNDLE_DEPLOYMENT: 'false', BUNDLE_FROZEN: 'false' }.freeze, T::Hash[Symbol, String])
    public_constant :OUTDATED_LINE, :ENVIRONMENT

    # @return [Array<Array(String, String, String)>] name, newest and installed version of every outdated gem
    sig { returns(T::Array[[String, String, String]]) }
    def self.outdated
      environment = Outdated::Bundle::ENVIRONMENT.transform_keys(&:to_s)
      output, status = Open3.capture2e(environment, 'bundle', 'outdated', '--parseable', chdir: Outdated::ROOT)
      # `bundle outdated` exits 1 when it reports an outdated gem, and with any other status when it could not check.
      abort("bundle outdated failed:\n#{output}") unless [0, 1].include?(status.exitstatus)
      output.lines.filter_map { |line| entry(line) }
    end

    # @param line [String] a line of `bundle outdated --parseable`
    # @return [Array(String, String, String), nil] name, newest and installed version, nil for any other line
    sig { params(line: String).returns(T.nilable([String, String, String])) }
    def self.entry(line)
      match = Outdated::Bundle::OUTDATED_LINE.match(line) or return
      name, newest, installed = match.captures
      [name.to_s, newest.to_s, installed.to_s]
    end
  end

  # The gems of the bundle, RubyGems and Bundler, against the gem holds.
  class Gems
    extend T::Sig

    # @param holds [Hash{String => Hash}] the gem holds
    # @param report [Report]
    sig { params(holds: T::Hash[String, T::Hash[String, Object]], report: Outdated::Report).void }
    def initialize(holds, report)
      @holds = holds
      @report = report
    end

    # Runs the checks.
    #
    # @return [void]
    sig { void }
    def check
      check_bundle
      [['rubygems-update', Gem::VERSION], ['bundler', Bundler::VERSION]].each do |name, installed|
        @report.compare(name, installed, Outdated::Upstream.gem(name))
      end
    end

    private

    # Every outdated gem of the bundle is held at its newest release, and every gem hold is still needed.
    #
    # @return [void]
    sig { void }
    def check_bundle
      outdated = Outdated::Bundle.outdated
      outdated.each { |name, newest, installed| check_gem(name, newest, installed) }
      (@holds.keys - outdated.map(&:first)).each { |name| @report.problem("STALE HOLD (no longer outdated): #{name}") }
    end

    # @param name [String] an outdated gem
    # @param newest [String] its newest release
    # @param installed [String] the installed release
    # @return [void]
    sig { params(name: String, newest: String, installed: String).void }
    def check_gem(name, newest, installed)
      @report.compare("gem #{name} (installed #{installed}), held at", @holds.dig(name, 'newest').to_s, newest)
    end
  end

  # The Rubies of .ruby-version and of the workflows, against the Ruby holds.
  class Rubies
    extend T::Sig

    # @param holds [Hash{String => Hash}] the Ruby holds, by job
    # @param workflows [Hash{String => String}] the text of every workflow, by file name
    # @param report [Report]
    sig do
      params(
        holds: T::Hash[String, T::Hash[String, Object]],
        workflows: T::Hash[String, String],
        report: Outdated::Report
      ).void
    end
    def initialize(holds, workflows, report)
      @holds = holds
      @workflows = workflows
      @report = report
      @releases = T.let(Outdated::Upstream.rubies, T::Array[Gem::Version])
    end

    # Runs the checks.
    #
    # @return [void]
    sig { void }
    def check
      check_current
      @workflows.each { |name, text| check_workflow(name, text) }
      @holds.each { |job, hold| check_hold(job, hold) }
    end

    private

    # The Ruby in .ruby-version is the newest release.
    #
    # @return [void]
    sig { void }
    def check_current
      current = File.read(File.join(Outdated::ROOT, '.ruby-version')).strip
      @report.compare('Ruby in .ruby-version', current, @releases.max.to_s)
    end

    # Every Ruby a workflow names is the newest release of its series.
    #
    # @param name [String] the workflow file
    # @param text [String] its text
    # @return [void]
    sig { params(name: String, text: String).void }
    def check_workflow(name, text)
      text.scan(/^ *(?:- |ruby-version: )(\d+\.\d+\.\d+)$/).uniq.each do |(ruby)|
        newest = newest_of_series(Outdated::Upstream.version(ruby.to_s))
        unless ruby == newest.to_s
          @report.problem("OUTDATED: Ruby #{ruby} in #{name} (newest of its series: #{newest})")
        end
      end
    end

    # @param version [Gem::Version] a Ruby release
    # @return [Gem::Version, nil] the newest release of its series
    sig { params(version: Gem::Version).returns(T.nilable(Gem::Version)) }
    def newest_of_series(version)
      series = version.segments.first(2)
      @releases.select { |release| release.segments.first(2) == series }
        .max
    end

    # A job that runs on another Ruby than .ruby-version still does, as its hold says.
    #
    # @param job [String]
    # @param hold [Hash]
    # @return [void]
    sig { params(job: String, hold: T::Hash[String, Object]).void }
    def check_hold(job, hold)
      workflow, version = hold.fetch_values('workflow', 'version').map(&:to_s)
      @report.checked("Ruby hold #{job}: #{version} (#{workflow})")
      pinned = @workflows.fetch(File.basename(workflow.to_s), '').include?("ruby-version: #{version}\n")
      @report.problem("RUBY HOLD #{job}: #{workflow} does not run Ruby #{version}") unless pinned
    end
  end

  # The GitHub Actions and the downloaded tools of the workflows.
  class Workflows
    extend T::Sig

    # `uses: owner/repo[/path]@<sha>  # <tag>`
    ACTION = %r{uses: ([\w.-]+/[\w.-]+)[\w./-]*@(\h{40}) +# (\S+)}
    public_constant :ACTION

    # @param text [String] the text of a workflow
    # @param pattern [Regexp] a pin, with a group for each of its parts
    # @return [Array<Array<String>>] the parts of every distinct pin in +text+
    sig { params(text: String, pattern: Regexp).returns(T::Array[T::Array[String]]) }
    def self.pins(text, pattern)
      Set.new(text.scan(pattern)) { |pin| Kernel.Array(pin).map(&:to_s) }
        .to_a
    end

    # @param report [Report]
    sig { params(report: Outdated::Report).void }
    def initialize(report)
      @report = report
    end

    # Every action of a workflow is pinned to the commit of its newest release tag.
    #
    # @param name [String] the workflow file
    # @param text [String] its text
    # @return [void]
    sig { params(name: String, text: String).void }
    def check(name, text)
      Outdated::Workflows.pins(text, Outdated::Workflows::ACTION).each { |pin| action(name, pin) }
    end

    private

    # @param name [String] the workflow file
    # @param pin [Array(String, String, String)] the action's repository, the commit it is pinned to and the
    #   release tag the pin names
    # @return [void]
    sig { params(name: String, pin: T::Array[String]).void }
    def action(name, pin)
      repository, commit, tag = pin
      @report.compare("#{name}: #{repository}", "#{tag} #{commit}", Outdated::Upstream.tag(repository.to_s).join(' '))
    end
  end

  # Runs every check.
  #
  # @return [Boolean] whether nothing is outdated
  sig { returns(T::Boolean) }
  def self.passed?
    report = Outdated::Report.new
    check(report)
    report.passed?
  end

  # Runs every check.
  #
  # @param report [Report]
  # @return [void]
  sig { params(report: Outdated::Report).void }
  def self.check(report)
    check_holds(report)
    check_workflows(report)
    check_releases(report)
  end

  # The Python of the linters is the one its hold names, and the hold is re-examined as soon as the package it waits
  # for has a new release on PyPI.
  #
  # @param report [Report]
  # @return [void]
  # @param hold [Hash] the Python hold
  sig { params(hold: T::Hash[String, Object], report: Outdated::Report).void }
  def self.check_python(hold, report)
    current = File.read(File.join(Outdated::ROOT, '.python-version')).strip
    report.compare('Python in .python-version, held at', current, hold.fetch('version').to_s)
    Hash.try_convert(hold.fetch('until_newer_than')).to_h.each do |name, version|
      report.compare(
        "#{name} on PyPI, which the Python hold waits for",
        version.to_s,
        Outdated::Upstream.pypi(name.to_s)
      )
    end
  end

  # Every release binary of tools/releases.txt is the newest release of its tool.
  #
  # @param report [Report]
  # @return [void]
  sig { params(report: Outdated::Report).void }
  def self.check_releases(report)
    listing, status = Open3.capture2(File.join(Outdated::ROOT, 'script', 'install_tools.sh'), '--list')
    abort('script/install_tools.sh --list failed') unless status.success?
    listing.lines.each do |line|
      tool, version, repository = line.split
      report.compare("tools/releases.txt: #{tool}", "v#{version}", Outdated::Upstream.tag(repository.to_s).first)
    end
  end

  # Checks the gems and the Rubies against their holds, and every hold that waits for a release.
  #
  # @param report [Report]
  # @return [void]
  sig { params(report: Outdated::Report).void }
  def self.check_holds(report)
    gem_holds, ruby_holds, python_hold = holds
    Outdated::Gems.new(gem_holds, report).check
    Outdated::Rubies.new(ruby_holds, workflows, report).check
    check_python(python_hold, report)
    holds_until([*gem_holds, *ruby_holds], report)
  end

  # @return [Array(Hash, Hash, Hash)] the gem holds, the Ruby holds and the Python hold
  sig do
    returns(
      [T::Hash[String, T::Hash[String, Object]], T::Hash[String, T::Hash[String, Object]], T::Hash[String, Object]]
    )
  end
  def self.holds
    YAML.safe_load_file(File.join(Outdated::ROOT, 'script', 'outdated_holds.yml'))
      .fetch_values('gems', 'ruby', 'python')
  end

  # @return [Hash{String => String}] the text of every workflow, by file name
  sig { returns(T::Hash[String, String]) }
  def self.workflows
    Dir[File.join(Outdated::ROOT, '.github', 'workflows', '*.yml')].to_h do |path|
      [File.basename(path), File.read(path)]
    end
  end

  # Checks the actions and the tools of every workflow.
  #
  # @param report [Report]
  # @return [void]
  sig { params(report: Outdated::Report).void }
  def self.check_workflows(report)
    checker = Outdated::Workflows.new(report)
    workflows.each { |name, text| checker.check(name, text) }
  end

  # Checks every hold that waits for a release of another gem.
  #
  # @param holds [Array<Array(String, Hash)>] the holds, each with what it holds
  # @param report [Report]
  # @return [void]
  sig { params(holds: T::Array[[String, T::Hash[String, Object]]], report: Outdated::Report).void }
  def self.holds_until(holds, report)
    holds.each { |held, hold| held_until(held, hold, report) }
  end

  # A hold that waits for a release of another gem is re-examined as soon as that gem has a new release.
  #
  # @param held [String] what the hold holds
  # @param hold [Hash] the hold
  # @param report [Report]
  # @return [void]
  sig { params(held: String, hold: T::Hash[String, Object], report: Outdated::Report).void }
  def self.held_until(held, hold, report)
    Hash.try_convert(hold.fetch('until_newer_than', {})).to_h.each do |name, version|
      report.compare("#{name}, which hold #{held} waits for", version.to_s, Outdated::Upstream.gem(name.to_s))
    end
  end
end

exit(Outdated.passed?)
