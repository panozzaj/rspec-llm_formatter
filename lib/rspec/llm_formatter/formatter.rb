require "rspec/core"
require "rspec/core/formatters/base_formatter"
require "rspec/core/formatters/console_codes"

module RSpec
  module LlmFormatter
    class Formatter < ::RSpec::Core::Formatters::BaseFormatter
      ::RSpec::Core::Formatters.register self,
        :example_failed, :dump_summary, :seed, :message, :close

      def initialize(output)
        super
        @failure_index = 0
      end

      def example_failed(notification)
        @failure_index += 1
        example = notification.example

        output.puts color("FAIL #{@failure_index}) #{example.full_description}", :failure)
        output.puts "  #{example.location_rerun_argument}"

        notification.message_lines.each do |line|
          next if line.strip.empty?
          output.puts "  #{line}"
        end

        notification.formatted_backtrace.each do |line|
          output.puts color("  # #{line}", :detail)
        end
      end

      def dump_summary(summary)
        if summary.example_count == 0
          output.puts color("0 examples (none ran) in #{format_duration(summary.duration)}", :failure)
        else
          line = summary.totals_line + " in #{format_duration(summary.duration)}"
          status = summary.failure_count > 0 ? :failure : :success
          output.puts color(line, status)
        end
      end

      def seed(notification)
        return unless notification.seed_used?
        output.puts "Seed: #{notification.seed}"
      end

      def message(notification)
        output.puts notification.message
      end

      def close(_notification)
        output.flush if output.respond_to?(:flush) && !output.closed?
      end

      private

      def color(text, status)
        return text unless color_enabled?
        ::RSpec::Core::Formatters::ConsoleCodes.wrap(text, status)
      end

      def color_enabled?
        ::RSpec.configuration.color_enabled?(output)
      end

      def format_duration(seconds)
        if seconds < 0.001
          "<1ms"
        elsif seconds < 1
          "#{(seconds * 1000).round}ms"
        elsif seconds < 60
          "%.1fs" % seconds
        else
          minutes = (seconds / 60).to_i
          remaining = seconds - (minutes * 60)
          "#{minutes}m#{remaining.round}s"
        end
      end
    end
  end
end
