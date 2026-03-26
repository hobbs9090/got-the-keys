require 'spec_helper'
require_relative '../../../lib/ci/rspec_performance_report'

RSpec.describe Ci::RspecPerformanceReport do
  let(:baseline) do
    Ci::RspecPerformanceBaseline.new(
      top_examples: 3,
      suite_warning_seconds: 4.0,
      slow_example_warning_seconds: 0.4,
      warning_examples_limit: 2
    )
  end

  let(:report_data) do
    {
      'summary' => { 'duration' => 5.2 },
      'examples' => [
        {
          'file_path' => './spec/system/public_appointment_booking_spec.rb',
          'line_number' => 12,
          'full_description' => 'books a viewing from a property page',
          'run_time' => 0.72
        },
        {
          'file_path' => './spec/requests/properties_spec.rb',
          'line_number' => 33,
          'full_description' => 'filters by town',
          'run_time' => 0.18
        },
        {
          'file_path' => './spec/system/admin_demo_scenarios_spec.rb',
          'line_number' => 8,
          'full_description' => 'restores the baseline scenario',
          'run_time' => 0.55
        }
      ]
    }
  end

  describe '#slow_examples' do
    it 'returns the slowest examples first' do
      examples = described_class.new(report_data: report_data, baseline: baseline).slow_examples

      expect(examples.map(&:location)).to eq([
        'spec/system/public_appointment_booking_spec.rb:12',
        'spec/system/admin_demo_scenarios_spec.rb:8',
        'spec/requests/properties_spec.rb:33'
      ])
    end
  end

  describe '#warnings' do
    it 'warns when the suite and examples exceed the configured baseline' do
      warnings = described_class.new(report_data: report_data, baseline: baseline).warnings

      expect(warnings.first).to include('RSpec suite duration 5.20s exceeded the warning baseline of 4.00s.')
      expect(warnings.last).to include('spec/system/admin_demo_scenarios_spec.rb:8')
    end
  end

  describe '#markdown_lines' do
    it 'includes the slowest examples and baseline table' do
      lines = described_class.new(report_data: report_data, baseline: baseline).markdown_lines.join("\n")

      expect(lines).to include('## Slowest Examples')
      expect(lines).to include('spec/system/public_appointment_booking_spec.rb:12')
      expect(lines).to include('## Performance Baseline')
      expect(lines).to include('| Suite duration | 5.20s | 4.00s |')
    end
  end
end
