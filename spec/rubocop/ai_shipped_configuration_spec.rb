# typed: false
# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'tmpdir'
require 'yaml'

# config/default.yml is loaded by RuboCop at run time, so it is checked against the RuboCop release and plugins
# the bundle resolves (`rake outdated` keeps them at their newest release): it must name only cops this gem
# defines, with the metadata RuboCop expects, and RuboCop must load it without a single warning, unknown or
# renamed cop, or obsolete parameter.
RSpec.describe RuboCop::AI do
  let(:root) { described_class.project_root }
  let(:shipped) { YAML.safe_load_file(File.join(root, 'config', 'default.yml')) }
  let(:own_cops) { RuboCop::Cop::Registry.global.filter_map { |cop| cop.cop_name if cop.department == :AI } }

  it 'configures exactly the cops of the gem' do
    expect(shipped.keys).to match_array(own_cops)
  end

  it 'gives every cop a description, an Enabled flag and the release that added it' do
    metadata = shipped.values.map { |settings| settings.slice('Description', 'Enabled', 'VersionAdded').keys }

    expect(metadata).to all(contain_exactly('Description', 'Enabled', 'VersionAdded'))
  end

  it 'enables or disables every cop with a value RuboCop accepts' do
    expect(shipped.values.map { |settings| settings.fetch('Enabled') }).to all(be(true).or(be(false)).or(eq('pending')))
  end

  it 'names releases that exist up to the current version' do
    added = shipped.values.map { |settings| Gem::Version.new(settings.fetch('VersionAdded')) }

    expect(added).to all(be <= Gem::Version.new(RuboCop::AI::VERSION))
  end

  context 'when RuboCop runs with the gem and every plugin of the bundle' do
    # The user configuration repeats every setting of the shipped one, so RuboCop's validator, which only
    # checks user configuration, checks each of them for obsolete, renamed and unsupported parameters too.
    let(:user_config) do
      YAML.safe_load(<<~YAML).merge(shipped)
        plugins: [rubocop-md, rubocop-performance, rubocop-rake, rubocop-rspec, rubocop-sorbet, rubocop-thread_safety]
        require: [rubocop-ai]
        AllCops:
          NewCops: enable
          SuggestExtensions: false
      YAML
    end
    let(:run) do
      Dir.mktmpdir do |directory|
        File.write(File.join(directory, '.rubocop.yml'), YAML.dump(user_config))
        File.write(File.join(directory, 'sample.rb'), "# frozen_string_literal: true\n\n# securely accurately\n")
        Open3.capture3(RbConfig.ruby, '-w', Gem.bin_path('rubocop', 'rubocop'), '--cache', 'false',
                       '--format', 'json', '--only', own_cops.join(','), 'sample.rb', chdir: directory)
      end
    end

    it 'reports the offense without printing any warning' do
      stdout, stderr, status = run
      reported_cops = stdout.scan(/"cop_name":"([^"]+)"/).flatten

      expect([stderr, status.exitstatus, reported_cops]).to eq(['', 1, ['AI/AdverbSpam']])
    end
  end
end
