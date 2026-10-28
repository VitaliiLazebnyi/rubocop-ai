# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::AI::Inject do
  let(:pristine_default) { RuboCop::ConfigLoader.load_file(RuboCop::ConfigLoader::DEFAULT_FILE) }
  let(:injected) { RuboCop::ConfigLoader.default_configuration }

  # Every example replaces RuboCop's process-wide default configuration; the other specs need the real one back.
  around do |example|
    original = RuboCop::ConfigLoader.default_configuration
    RuboCop::ConfigLoader.default_configuration = pristine_default
    example.run
  ensure
    RuboCop::ConfigLoader.default_configuration = original
  end

  describe '.defaults!' do
    it "adds the gem's cops with their default settings to RuboCop's default configuration" do
      described_class.defaults!

      expect(injected.for_cop('AI/AdverbSpam').values_at('Description', 'Enabled', 'VersionAdded')).to eq(
        ['Avoid AI-generated spam inside comments (excessive adverbs/meaningless words).', true, '0.1.0']
      )
    end

    it "keeps RuboCop's own defaults" do
      described_class.defaults!

      expect(injected.to_h.except('AI/AdverbSpam')).to eq(pristine_default.to_h)
    end

    it "keeps the origin of RuboCop's default configuration" do
      described_class.defaults!

      expect(injected.loaded_path).to eq(pristine_default.loaded_path)
    end

    it 'returns a RuboCop configuration that RuboCop can run with' do
      described_class.defaults!

      expect(injected).to be_a(RuboCop::Config)
    end

    context 'when the configuration excludes paths' do
      let(:fixture_root) { File.expand_path('../../fixtures/inject', __dir__) }

      before { allow(RuboCop::AI).to receive(:project_root).and_return(fixture_root) }

      it 'reads config/default.yml under the gem root' do
        described_class.defaults!

        expect(injected.for_cop('AI/AdverbSpam').values_at('Description', 'Enabled'))
          .to eq(['Fixture description.', false])
      end

      it 'makes the excluded paths absolute, as RuboCop does for its own defaults' do
        described_class.defaults!

        expect(injected.for_cop('AI/AdverbSpam')['Exclude']).to eq([File.join(Dir.pwd, 'generated/**/*')])
      end
    end
  end
end
