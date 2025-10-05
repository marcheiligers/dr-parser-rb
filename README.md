# dr-parse-rb

A Ruby syntax parser for DragonRuby Game Toolkit that preserves whitespace for accurate syntax highlighting and rendering.

## Features

- **Whitespace-preserving tokenization** - Perfect for syntax highlighting with exact positioning
- **Comprehensive Ruby syntax support**:
  - Keywords (`class`, `def`, `module`, `if`, `else`, `end`, etc.)
  - Strings (single and double-quoted) with interpolation support
  - Numbers (integers, decimals, underscores like `1_000`)
  - Symbols (`:foo`, `:"quoted symbol"`)
  - Constants (`Foo`, `MY_CONSTANT`, `Foo::Bar`)
  - Global variables (`$gtk`, `$0`, `$$`)
  - Operators (all Ruby operators including `=>`, `::`, etc.)
  - Comments
  - Arrays and percent literals (`%w`, `%i`, `%q`, `%Q`, `%r`, `%s`, `%x`)
  - String interpolation with nested parsing (`"hello #{name}"`)
  - Method names with `!` and `?` (`save!`, `empty?`)

## Usage

```ruby
require 'lib/parser.rb'

# Parse some Ruby code
parser = RubyParser.new('class Foo; def bar; end; end')
tokens = parser.parse

# Each token has: type, value, start, and end positions
tokens.each do |token|
  puts "#{token[:type]}: '#{token[:value]}' [#{token[:start]}..#{token[:end]}]"
end
```

### Example Output

```ruby
parser = RubyParser.new('$gtk.args')
tokens = parser.parse
# => [
#   { type: :global, value: "$gtk", start: 0, end: 3 },
#   { type: :operator, value: ".", start: 4, end: 4 },
#   { type: :identifier, value: "args", start: 5, end: 8 }
# ]
```

### Token Types

- `:keyword` - Ruby keywords
- `:string` - String literals
- `:number` - Numeric literals
- `:symbol` - Symbols
- `:constant` - Constants
- `:identifier` - Variable and method names
- `:global` - Global variables
- `:operator` - Operators
- `:comment` - Comments
- `:whitespace` - Spaces, tabs, newlines
- `:interpolation_start` - `#{` in strings
- `:interpolation_end` - `}` closing interpolation
- `:array_literal` - Percent literals like `%w[...]`

### Syntax Highlighting Example

See `app/main.rb` for a working example that renders syntax-highlighted Ruby code using DragonRuby.

## Running the Demo

```bash
./run
```

This will show a syntax-highlighted Ruby line with a breakdown of token types.

## Testing

```bash
# Run all tests
./test

# Run specific test file
./test test_parser
./test test_strings
./test test_arrays
```

**79 tests passing** covering all major Ruby syntax features.

## Implementation Notes

- **No regex support** - DragonRuby uses mruby which doesn't include regex, so the parser is built using character-by-character parsing
- **Single-line parsing** - Designed for REPL-style single-line parsing (perfect for syntax highlighting as you type)
- **Interpolation parsing** - String interpolations are parsed recursively, allowing full syntax highlighting inside `#{...}`
- **Position tracking** - Every token includes exact start and end positions for precise rendering

## License

MIT License - see [LICENSE](LICENSE) file for details
