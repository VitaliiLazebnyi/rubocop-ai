#!/usr/bin/env ruby
# typed: true
# frozen_string_literal: true

# Fails when anything in the toolchain is not at its newest release and is not on the documented hold list
# (script/outdated_holds.yml), or when a listed hold is no longer needed:
# - every gem of the bundle (`bundle outdated`),
# - RubyGems and Bundler,
# - the Ruby in .ruby-version, and every Ruby the workflows name (each must be the newest patch of its minor).

require 'json'
require 'net/http'
require 'open3'
require 'yaml'

root = File.expand_path('..', __dir__)
holds = YAML.safe_load_file(File.join(root, 'script', 'outdated_holds.yml'))
gem_holds = holds.fetch('gems')
failures = []

# --- Gems ---
output, = Open3.capture2e('bundle', 'outdated', '--parseable', chdir: root)
pattern = /^(\S+) \(newest ([^,\s]+), installed ([^,)\s]+)/
outdated = output.scan(pattern).to_h { |name, newest, installed| [name, [newest, installed]] }
outdated.each do |name, (newest, installed)|
  puts "outdated: #{name} #{installed} -> #{newest}#{' (on hold)' if gem_holds.key?(name)}"
  failures << "NOT ON THE HOLD LIST: #{name} #{installed} -> #{newest}" unless gem_holds.dig(name, 'newest') == newest
end
(gem_holds.keys - outdated.keys).each { |name| failures << "STALE HOLD (no longer outdated): #{name}" }

# --- RubyGems and Bundler ---
def newest_gem(name)
  JSON.parse(Net::HTTP.get(URI("https://rubygems.org/api/v1/versions/#{name}/latest.json"))).fetch('version')
end
[['rubygems-update', Gem::VERSION], ['bundler', Bundler::VERSION]].each do |name, installed|
  newest = newest_gem(name)
  puts "#{name}: #{installed} (newest #{newest})"
  failures << "OUTDATED: #{name} #{installed} -> #{newest}" unless installed == newest
end

# --- Ruby ---
index = Net::HTTP.get(URI('https://cache.ruby-lang.org/pub/ruby/index.txt')).to_s
releases = index.scan(/^ruby-(\d+\.\d+\.\d+)\t/).map { |(version)| Gem::Version.new(version) }
newest_patch = releases.group_by { |version| version.segments.first(2) }.transform_values(&:max)
newest_ruby = releases.max
current = Gem::Version.new(File.read(File.join(root, '.ruby-version')).strip)
puts "Ruby: .ruby-version #{current} (newest #{newest_ruby})"
failures << "OUTDATED: .ruby-version #{current} -> #{newest_ruby}" unless current == newest_ruby

Dir[File.join(root, '.github', 'workflows', '*.yml')].each do |workflow|
  File.read(workflow).scan(/"(\d+\.\d+\.\d+)"/).each do |(named)|
    version = Gem::Version.new(named)
    minor = version.segments.first(2)
    newest = newest_patch.fetch(minor, version)
    failures << "OUTDATED: Ruby #{version} in #{File.basename(workflow)} (newest #{minor.join('.')}: #{newest})" \
      unless version == newest
  end
end

holds.fetch('ruby').each do |job, hold|
  pinned = File.read(File.join(root, hold.fetch('workflow'))).include?(%("#{hold.fetch('version')}"))
  failures << "RUBY HOLD #{job}: #{hold.fetch('workflow')} does not run Ruby #{hold.fetch('version')}" unless pinned
  hold.fetch('until_newer_than').each do |name, held|
    newest = newest_gem(name)
    failures << "STALE RUBY HOLD #{job}: #{name} #{newest} is newer than #{held}; re-check the reason" if newest != held
  end
  puts "Ruby hold #{job}: #{hold.fetch('version')} (#{hold.fetch('workflow')})"
end

failures.each { |failure| warn failure }
exit(failures.empty? ? 0 : 1)
