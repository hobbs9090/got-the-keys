require 'spec_helper'
require_relative '../../../lib/ci/spec_change_guard'

RSpec.describe Ci::SpecChangeGuard do
  describe '#evaluate' do
    it 'passes when app changes include spec updates' do
      result = described_class.new(
        changed_files: ['app/controllers/admin/qa_controller.rb', 'spec/requests/admin/qa_spec.rb']
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'fails when monitored product code changes have no matching spec updates' do
      result = described_class.new(
        changed_files: ['app/helpers/shared_helper.rb', 'config/locales/ui.en.yml']
      ).evaluate

      expect(result.success?).to be(false)
      expect(result.message).to include('app/helpers/shared_helper.rb')
    end

    it 'ignores exempt static asset changes' do
      result = described_class.new(
        changed_files: ['app/assets/images/hero_5.jpg']
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'ignores exempt rake task changes' do
      result = described_class.new(
        changed_files: ['lib/tasks/populate.rake']
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'ignores deleted product files when no live code remains changed' do
      result = described_class.new(
        changed_files: [{ path: 'app/helpers/blog_helper.rb', status: 'D' }]
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'ignores deletion-only product edits when no live code remains changed' do
      result = described_class.new(
        changed_files: [{ path: 'app/helpers/shared_helper.rb', status: 'M', additions: 0, deletions: 8 }]
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'requires spec updates for lib changes outside exempt task paths' do
      result = described_class.new(
        changed_files: ['lib/release_build_metadata.rb']
      ).evaluate

      expect(result.success?).to be(false)
      expect(result.covered_paths).to eq(['lib/release_build_metadata.rb'])
    end
  end
end

RSpec.describe Ci::ChangeRange do
  describe '.from_github' do
    it 'builds a three-dot range for pull requests' do
      range = described_class.from_github(
        env: { 'GITHUB_EVENT_NAME' => 'pull_request' },
        payload: {
          'pull_request' => {
            'base' => { 'sha' => 'base123' },
            'head' => { 'sha' => 'head456' }
          }
        }
      )

      expect(range.base_sha).to eq('base123')
      expect(range.head_sha).to eq('head456')
      expect(range.diff_mode).to eq(:three_dot)
      expect(range).to be_complete
    end

    it 'uses a single-commit range for the first push in a branch' do
      range = described_class.from_github(
        env: { 'GITHUB_EVENT_NAME' => 'push', 'GITHUB_SHA' => 'after789' },
        payload: {
          'before' => '0' * 40,
          'after' => 'after789'
        }
      )

      expect(range.base_sha).to be_nil
      expect(range.head_sha).to eq('after789')
      expect(range.diff_mode).to eq(:single_commit)
      expect(range).to be_complete
    end

    it 'uses a two-dot range for normal pushes' do
      range = described_class.from_github(
        env: { 'GITHUB_EVENT_NAME' => 'push' },
        payload: {
          'before' => 'before123',
          'after' => 'after789'
        }
      )

      expect(range.base_sha).to eq('before123')
      expect(range.head_sha).to eq('after789')
      expect(range.diff_mode).to eq(:two_dot)
    end
  end
end
