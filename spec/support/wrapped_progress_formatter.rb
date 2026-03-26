require 'io/console'
require 'rspec/core/formatters/progress_formatter'

class WrappedProgressFormatter < RSpec::Core::Formatters::ProgressFormatter
  RSpec::Core::Formatters.register self, :example_passed, :example_pending, :example_failed, :start_dump

  DEFAULT_LINE_WIDTH = 80
  MINIMUM_LINE_WIDTH = 20

  def initialize(output)
    super
    @line_width = detect_line_width
    @line_length = 0
  end

  def example_passed(_notification)
    print_progress('.', :success)
  end

  def example_pending(_notification)
    print_progress('*', :pending)
  end

  def example_failed(_notification)
    print_progress('F', :failure)
  end

  private

  def print_progress(character, color)
    output.puts if @line_length >= @line_width
    @line_length = 0 if @line_length >= @line_width

    output.print RSpec::Core::Formatters::ConsoleCodes.wrap(character, color)
    @line_length += 1
  end

  def detect_line_width
    width = output_width || console_width || DEFAULT_LINE_WIDTH
    [width, MINIMUM_LINE_WIDTH].max
  end

  def output_width
    return unless output.respond_to?(:winsize)

    output.winsize[1]
  rescue StandardError
    nil
  end

  def console_width
    console = IO.console
    return unless console

    console.winsize[1]
  rescue StandardError
    nil
  end
end
