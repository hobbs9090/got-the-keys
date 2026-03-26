require 'spec_helper'
require 'stringio'

RSpec.describe WrappedProgressFormatter do
  let(:notification) { instance_double(RSpec::Core::Notifications::ExampleNotification) }
  let(:output) { StringIO.new }
  let(:formatter) { described_class.new(output) }

  before do
    allow(RSpec::Core::Formatters::ConsoleCodes).to receive(:wrap) { |character, _color| character }
  end

  it 'wraps progress output to the available terminal width' do
    output.define_singleton_method(:winsize) { [24, 20] }

    formatter = described_class.new(output)

    21.times { formatter.example_passed(notification) }
    formatter.start_dump(nil)

    expect(output.string).to eq(("#{'.' * 20}\n.\n"))
  end

  it 'uses a sensible fallback width when the output size is unavailable' do
    5.times { formatter.example_passed(notification) }
    formatter.start_dump(nil)

    expect(output.string).to eq(".....\n")
  end
end
