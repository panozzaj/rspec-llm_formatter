#!/usr/bin/env python3
"""
Compare token counts across RSpec formatters.

Requires: pip install tiktoken

Usage:
  # 1. Generate output files for each formatter:
  bundle exec rspec --format progress      --no-color --order defined spec_file.rb > tmp/progress.txt 2>/dev/null
  bundle exec rspec --format documentation --no-color --order defined spec_file.rb > tmp/documentation.txt 2>/dev/null
  bundle exec rspec --format RSpec::LlmFormatter::Formatter --no-color --order defined spec_file.rb > tmp/llm.txt 2>/dev/null

  # 2. Count tokens:
  python3 script/count_tokens.py tmp/progress.txt tmp/documentation.txt tmp/llm.txt
"""

import sys
import tiktoken

enc = tiktoken.get_encoding("cl100k_base")

if len(sys.argv) < 2:
    print(__doc__.strip())
    sys.exit(1)

print(f"{'File':<50} {'Tokens':>8} {'Lines':>8} {'Bytes':>8}")
print("-" * 80)

results = []
for path in sys.argv[1:]:
    text = open(path).read()
    tokens = len(enc.encode(text))
    lines = text.count("\n")
    bytes_ = len(text.encode())
    results.append((path, tokens, lines, bytes_))
    print(f"{path:<50} {tokens:>8} {lines:>8} {bytes_:>8}")

if len(results) >= 2:
    min_tokens = min(r[1] for r in results)
    min_name = next(r[0] for r in results if r[1] == min_tokens)
    print()
    for path, tokens, _, _ in results:
        if path != min_name and tokens > 0:
            saved = tokens - min_tokens
            pct = (saved / tokens) * 100
            print(f"{path} -> {min_name}: {saved} tokens saved ({pct:.0f}%)")
