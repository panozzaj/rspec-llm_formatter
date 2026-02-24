require_relative "lib/rspec/llm_formatter/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-llm_formatter"
  spec.version = RSpec::LlmFormatter::VERSION
  spec.authors = ["Anthony Panozzo"]
  spec.email = ["panozzaj@gmail.com"]

  spec.summary = "Token-optimized RSpec formatter for LLM/agent consumption"
  spec.description = "An RSpec formatter that minimizes output tokens while preserving " \
                     "full failure details. Zero output for passing tests, compact " \
                     "summary, no ANSI colors."
  spec.homepage = "https://github.com/panozzaj/rspec-llm_formatter"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rspec-core", ">= 3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
end
