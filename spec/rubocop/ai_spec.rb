# typed: false
# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

RSpec.describe RuboCop::AI, :bug_RB_AI_001 do
  let(:release_workflow_path) { File.join(described_class.project_root, '.github', 'workflows', 'release.yml') }
  let(:version_file_path) { File.join(described_class.project_root, 'lib', 'rubocop', 'ai', 'version.rb') }
  let(:workflow) { YAML.safe_load_file(release_workflow_path) }
  let(:steps) { workflow.dig('jobs', 'build_and_release', 'steps') }
  let(:sync_step) { steps.find { |step| step['name'] == 'Synchronize Version' } }

  it 'has a release workflow configuration' do
    expect(File.exist?(release_workflow_path)).to be(true)
  end

  it 'has a version.rb file' do
    expect(File.exist?(version_file_path)).to be(true)
  end

  it 'contains the Synchronize Version step in release.yml' do
    expect(sync_step).not_to be_nil
  end

  it 'uses the correct sed command structure in release.yml' do
    sed_command = sync_step['run']
    expect(sed_command).to include("s/VERSION = '.*'/VERSION = '${{ env.VERSION }}'/")
  end

  it 'contains a matchable version constant in version.rb' do
    version_content = File.read(version_file_path)
    expect(version_content).to match(/VERSION = '.*'/)
  end

  it 'verifies that simulated sed substitution works on the version definition format' do
    version_content = File.read(version_file_path)
    simulated_version = '99.9.9'
    modified_content = version_content.gsub(/VERSION = '.*'/, "VERSION = '#{simulated_version}'")
    expect(modified_content).to include("VERSION = '#{simulated_version}'")
  end
end
