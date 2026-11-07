# typed: false
# frozen_string_literal: true

require 'yaml'

RSpec.describe RuboCop::AI do
  describe '.project_root' do
    it 'is the absolute directory that holds the gemspec and the configuration of the gem' do
      root = described_class.project_root

      contents = %w[rubocop-ai.gemspec config/default.yml].map { |file| File.file?(File.join(root, file)) }

      expect([root, *contents]).to eq([File.expand_path('../..', __dir__), true, true])
    end
  end

  describe 'VERSION' do
    it 'is a semantic version' do
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe 'the release workflow', bug: 'BUG-RB-001' do
    let(:workflow) do
      YAML.safe_load_file(File.join(described_class.project_root, '.github', 'workflows', 'release.yml'))
    end
    let(:validate_step) do
      steps = workflow.dig('jobs', 'build_and_release', 'steps')
      steps.find { |step| step['name'] == 'Validate tag against version.rb' }
    end

    it 'refuses to publish a tag that differs from the committed version' do
      expect(validate_step['run']).to include('RuboCop::AI::VERSION', '"$VERSION" != "$FILE_VERSION"')
    end
  end

  describe 'the gemspec', bug: 'BUG-RB-005' do
    let(:specification) { Gem::Specification.load(File.join(described_class.project_root, 'rubocop-ai.gemspec')) }

    it 'links a changelog that exists in the repository and ships with the gem' do
      changelog = specification.metadata.fetch('changelog_uri').delete_prefix("#{specification.homepage}/blob/main/")

      expect([File.file?(File.join(described_class.project_root, changelog)),
              specification.files.include?(changelog)]).to eq([true, true])
    end

    it 'ships the configuration that RuboCop loads' do
      expect(specification.files).to include('config/default.yml', 'lib/rubocop-ai.rb')
    end
  end
end
