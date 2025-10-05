# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-10-04

### Added
- Initial release of dr-parse-rb
- Ruby syntax parser for DragonRuby Game Toolkit
- Whitespace-preserving tokenization for accurate syntax highlighting
- Support for Ruby keywords (37 keywords including `class`, `def`, `module`, `if`, `else`, `end`, etc.)
- String parsing (single and double-quoted)
- String interpolation support with recursive parsing of expressions inside `#{...}`
- Number parsing (integers, decimals, underscores like `1_000`)
- Method calls on numbers (e.g., `10.seconds`)
- Symbol parsing (`:foo`, `:"quoted symbol"`)
- Constant parsing (`Foo`, `MY_CONSTANT`, namespaced `Foo::Bar`)
- Global variable parsing (`$gtk`, `$0`, `$$`, special globals)
- Operator parsing (all Ruby operators including `=>`, `::`, `.`, etc.)
- Comment parsing
- Array literal parsing
- Percent literal support (`%w`, `%W`, `%i`, `%I`, `%q`, `%Q`, `%r`, `%s`, `%x`)
- Method names with `!` and `?` (`save!`, `empty?`)
- Hash syntax support (`{a: 1}`)
- Comprehensive test suite (79 tests passing)
- Syntax highlighting demo application
- MIT License
- Documentation (README.md, CLAUDE.md)

### Technical Details
- Character-by-character parsing (no regex - mruby compatible)
- Position tracking for every token (start and end positions)
- Single-line REPL-style parsing
- 12 token types: keyword, string, number, symbol, constant, identifier, global, operator, comment, whitespace, interpolation_start, interpolation_end, array_literal

[0.0.1]: https://github.com/marcheiligers/dr-parse-rb/releases/tag/v0.0.1
