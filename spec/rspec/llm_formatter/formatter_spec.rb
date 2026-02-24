require "spec_helper"
require "open3"
require "tempfile"

RSpec.describe RSpec::LlmFormatter::Formatter do
  def run_specs(spec_code, extra_args: [], env: {}, color: false)
    file = Tempfile.new(["test_spec", ".rb"])
    file.write(spec_code)
    file.close

    cmd = [
      "bundle", "exec", "rspec",
      "--format", "RSpec::LlmFormatter::Formatter",
      *(["--no-color"] unless color),
      "--order", "defined",
      *extra_args,
      file.path,
    ]

    stdout, _stderr, _status = Open3.capture3(env, *cmd)
    stdout
  ensure
    file&.unlink
  end

  describe "passing specs" do
    it "outputs only the summary line" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Math" do
          it("adds") { expect(1 + 1).to eq(2) }
          it("subtracts") { expect(3 - 1).to eq(2) }
        end
      RUBY

      expect(result.strip).to match(/\A2 examples, 0 failures in \S+\z/)
    end
  end

  describe "failing specs" do
    it "outputs FAIL with description, location, message, and backtrace" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Math" do
          it "fails" do
            expect(1 + 1).to eq(3)
          end
        end
      RUBY

      expect(result).to include("FAIL 1) Math fails")
      expect(result).to include("expected: 3")
      expect(result).to include("got: 2")
      expect(result).to include("1 example, 1 failure")
    end

    it "includes the spec file location" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Math" do
          it "fails" do
            expect(1).to eq(2)
          end
        end
      RUBY

      lines = result.lines
      fail_index = lines.index { |l| l.include?("FAIL") }
      location_line = lines[fail_index + 1]
      expect(location_line.strip).to match(%r{test_spec.*\.rb:\d+})
    end

    it "numbers multiple failures" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Math" do
          it("first") { expect(1).to eq(2) }
          it("second") { expect(3).to eq(4) }
        end
      RUBY

      expect(result).to include("FAIL 1) Math first")
      expect(result).to include("FAIL 2) Math second")
      expect(result).to include("2 examples, 2 failures")
    end

    it "does not include rerun commands" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Math" do
          it("fails") { expect(1).to eq(2) }
        end
      RUBY

      expect(result).not_to match(/^rspec /)
    end
  end

  describe "pending specs" do
    it "counts pending in summary but does not list them" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Math" do
          it "is pending", pending: "not yet" do
            expect(1).to eq(2)
          end
          it("passes") { expect(1).to eq(1) }
        end
      RUBY

      expect(result).to include("1 pending")
      expect(result).not_to include("FAIL")
      expect(result.strip.lines.size).to eq(1)
    end
  end

  describe "ANSI codes" do
    it "contains no ANSI escape codes when --no-color" do
      result = run_specs(<<~RUBY)
        RSpec.describe "x" do
          it("passes") { }
          it("fails") { expect(1).to eq(2) }
        end
      RUBY

      expect(result).not_to match(/\e\[/)
    end

    it "includes ANSI escape codes when --force-color" do
      result = run_specs(
        <<~RUBY,
          RSpec.describe "x" do
            it("fails") { expect(1).to eq(2) }
          end
        RUBY
        color: true,
        extra_args: ["--force-color"]
      )

      expect(result).to match(/\e\[/)
    end
  end

  describe "seed" do
    it "includes seed when randomized" do
      result = run_specs(
        'RSpec.describe("x") { it("y") { } }',
        extra_args: ["--order", "random"]
      )

      expect(result).to match(/Seed: \d+/)
    end

    it "omits seed when not randomized" do
      result = run_specs(<<~RUBY)
        RSpec.describe("x") { it("y") { } }
      RUBY

      expect(result).not_to include("Seed:")
    end
  end

  describe "duration formatting" do
    let(:formatter) { described_class.new(StringIO.new) }

    it "formats sub-millisecond as <1ms" do
      expect(formatter.send(:format_duration, 0.0005)).to eq("<1ms")
    end

    it "formats milliseconds" do
      expect(formatter.send(:format_duration, 0.015)).to eq("15ms")
    end

    it "formats seconds with one decimal" do
      expect(formatter.send(:format_duration, 2.345)).to eq("2.3s")
    end

    it "formats minutes and seconds" do
      expect(formatter.send(:format_duration, 90.4)).to eq("1m30s")
    end
  end

  describe "error exceptions (not assertion failures)" do
    it "includes the exception class and message" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Errors" do
          it "raises" do
            raise RuntimeError, "something broke"
          end
        end
      RUBY

      expect(result).to include("FAIL 1) Errors raises")
      expect(result).to include("RuntimeError")
      expect(result).to include("something broke")
    end
  end

  describe "zero examples" do
    it "warns when no examples ran" do
      result = run_specs(<<~RUBY)
        RSpec.describe "Empty" do
        end
      RUBY

      expect(result).to include("0 examples (none ran)")
    end
  end

  describe "CLAUDECODE env var auto-registration" do
    it "auto-registers formatter when CLAUDECODE=1" do
      file = Tempfile.new(["test_spec", ".rb"])
      file.write('RSpec.describe("x") { it("y") { } }')
      file.close

      cmd = [
        "bundle", "exec", "rspec",
        "--require", "rspec/llm_formatter/auto",
        "--no-color", "--order", "defined", file.path,
      ]
      stdout, _stderr, _status = Open3.capture3({"CLAUDECODE" => "1"}, *cmd)

      expect(stdout).to match(/1 example, 0 failures in \S+/)
    ensure
      file&.unlink
    end

    it "does not auto-register without the env var" do
      file = Tempfile.new(["test_spec", ".rb"])
      file.write('RSpec.describe("x") { it("y") { } }')
      file.close

      cmd = [
        "bundle", "exec", "rspec",
        "--require", "rspec/llm_formatter/auto",
        "--no-color", "--order", "defined", file.path,
      ]
      stdout, _stderr, _status = Open3.capture3({"CLAUDECODE" => nil}, *cmd)

      # Default progress formatter uses dots
      expect(stdout).to include(".")
      expect(stdout).not_to match(/\d+ examples?, \d+ failures? in \S+/)
    ensure
      file&.unlink
    end
  end
end
