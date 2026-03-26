require 'spec_helper'
require_relative '../../../lib/ci/spec_change_guard'

RSpec.describe Ci::TopLevelControllerCoverageGuard do
  describe '#evaluate' do
    def evaluate(changed_files:, before_source:, after_source:)
      described_class.new(
        changed_files: changed_files,
        before_reader: ->(_path) { before_source },
        after_reader: ->(_path) { after_source }
      ).evaluate
    end

    it 'passes when no new public actions were added' do
      result = evaluate(
        changed_files: ['app/controllers/properties_controller.rb'],
        before_source: "class PropertiesController < ApplicationController\n  def index\n  end\nend\n",
        after_source: "class PropertiesController < ApplicationController\n  def index\n  end\n\n  private\n\n  def helper_method\n  end\nend\n"
      )

      expect(result.success?).to be(true)
    end

    it 'fails when a new public top-level action is added without request or system spec updates' do
      result = evaluate(
        changed_files: ['app/controllers/properties_controller.rb'],
        before_source: "class PropertiesController < ApplicationController\n  def index\n  end\nend\n",
        after_source: "class PropertiesController < ApplicationController\n  def index\n  end\n\n  def map\n  end\nend\n"
      )

      expect(result.success?).to be(false)
      expect(result.message).to include('app/controllers/properties_controller.rb: #map')
    end

    it 'passes when a new public top-level action is paired with request coverage changes' do
      result = described_class.new(
        changed_files: ['app/controllers/properties_controller.rb', 'spec/requests/properties_spec.rb'],
        before_reader: ->(_path) { "class PropertiesController < ApplicationController\n  def index\n  end\nend\n" },
        after_reader: ->(_path) { "class PropertiesController < ApplicationController\n  def index\n  end\n\n  def map\n  end\nend\n" }
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'ignores nested controllers under app/controllers/admin' do
      result = described_class.new(
        changed_files: ['app/controllers/admin/properties_controller.rb'],
        before_reader: ->(_path) { nil },
        after_reader: ->(_path) { "class Admin::PropertiesController < Admin::BaseController\n  def audit\n  end\nend\n" }
      ).evaluate

      expect(result.success?).to be(true)
    end

    it 'ignores application_controller' do
      result = described_class.new(
        changed_files: ['app/controllers/application_controller.rb'],
        before_reader: ->(_path) { nil },
        after_reader: ->(_path) { "class ApplicationController < ActionController::Base\n  def helper_method\n  end\nend\n" }
      ).evaluate

      expect(result.success?).to be(true)
    end
  end
end
