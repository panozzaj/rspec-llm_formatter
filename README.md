# rspec-llm_formatter

Token-optimized RSpec formatter for LLM/agent consumption. Zero output for passing tests, compact failure details, no ANSI colors.

## Installation

```ruby
# Gemfile
gem "rspec-llm_formatter", group: :test
```

## Usage

### Explicit

```bash
rspec --format RSpec::LlmFormatter::Formatter
```

### Auto-enable via env var

Add to `.rspec`:

```
--require rspec/llm_formatter/auto
```

Then the formatter activates only when `CLAUDECODE=1` is set. When the env var is absent, your normal formatter is used.

## Output Examples

**All passing:**

```
42 examples, 0 failures in 1.2s
```

**With failures:**

```
FAIL 1) User#full_name returns first and last name
  ./spec/models/user_spec.rb:15
  Failure/Error: expect(user.full_name).to eq("Jane Doe")
    expected: "Jane Doe"
         got: "Jane"
    (compared using ==)
  # ./spec/models/user_spec.rb:17
FAIL 2) Api::UsersController#index returns paginated results
  ./spec/controllers/users_controller_spec.rb:42
  Failure/Error: expect(response.body).to include("page")
    expected "[]" to include "page"
  # ./spec/controllers/users_controller_spec.rb:48
42 examples, 2 failures in 3.5s
Seed: 12345
```

**No examples ran:**

```
0 examples (none ran) in <1ms
```

## Design

- **Zero output for passing tests** — no dots, no descriptions
- **No ANSI color codes** by default — but respects `--color`/`--force-color` for terminal use
- **Compact failure details** — description, location, error message, filtered backtrace
- **Smart duration** — `<1ms`, `15ms`, `2.3s`, `1m30s`
- **Pending counted, not listed** — LLMs don't need to action pending tests
- **Zero-examples warning** — `0 examples (none ran)` prevents false confidence
- **Failures streamed immediately** — available even if the run is interrupted

## License

MIT
