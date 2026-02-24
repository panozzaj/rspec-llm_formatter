require_relative "../llm_formatter"

if ENV["CLAUDECODE"] == "1"
  RSpec.configure do |config|
    config.formatter = RSpec::LlmFormatter::Formatter
  end
end
