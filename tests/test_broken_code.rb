require_relative 'test_helpers'

# ---- Tests for broken/invalid code - graceful handling -----------------------
# These tests ensure the parser doesn't crash on invalid input

# ---- Unclosed strings --------------------------------------------------------

def test_broken_unclosed_string_at_eof(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    x = "hello world
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  # Should parse without crashing
  assert.true!(parser.lines.length > 0)
  # Stack should show unclosed string
  assert.equal!(parser.lines.last.stack.map(&:type), [:string_double])
end

def test_broken_unclosed_string_multiline(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    def foo
      msg = "unclosed string
      puts "another line"
    end
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Second line should still be inside the string
  assert.true!(parser.lines[1].stack.map(&:type).include?(:string_double))
end

def test_broken_unclosed_single_quote(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    x = 'hello
    y = 'world'
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

# ---- Unclosed delimiters -----------------------------------------------------

def test_broken_unclosed_paren(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    foo(1, 2, 3
    bar(4)
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines[0].stack.map(&:type), [:paren])
end

def test_broken_unclosed_bracket(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    arr = [1, 2, 3
    x = 5
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines[0].stack.map(&:type), [:array])
end

def test_broken_unclosed_brace(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    hash = { a: 1, b: 2
    x = 5
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines[0].stack.map(&:type), [:hash])
end

def test_broken_nested_unclosed_delimiters(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    data = {
      items: [1, 2, 3
      name: "test"
    }
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Second line should show nested hash and array
  assert.equal!(parser.lines[1].stack.map(&:type), [:hash, :array])
end

# ---- Mismatched delimiters ---------------------------------------------------

def test_broken_mismatched_closing_paren(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    arr = [1, 2, 3)
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  # Should parse without crashing
  assert.true!(parser.lines.length > 0)
end

def test_broken_mismatched_closing_bracket(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    hash = { a: 1 ]
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_extra_closing_delimiter(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    x = 5
    end
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

# ---- Unclosed blocks ---------------------------------------------------------

def test_broken_unclosed_def(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    def hello
      puts "world"
    def goodbye
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Last line should show nested defs
  assert.equal!(parser.lines.last.stack.map(&:type), [:def, :def])
end

def test_broken_unclosed_class(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    class Foo
      def bar
      end
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines.last.stack.map(&:type), [:class])
end

def test_broken_unclosed_if(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    if condition
      puts "true"
    x = 5
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines.last.stack.map(&:type), [:if])
end

def test_broken_unclosed_do_block(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    items.each do |item|
      puts item
    x = 5
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines.last.stack.map(&:type), [:do_block])
end

# ---- Invalid heredoc syntax --------------------------------------------------

def test_broken_heredoc_missing_delimiter(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    text = <<EOF
    This is content
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Heredoc never closed - stack should still show it
  assert.equal!(parser.lines.last.stack.map(&:type), [:heredoc])
end

def test_broken_heredoc_wrong_delimiter(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    text = <<START
    Content here
    END
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Should still be in heredoc since delimiter doesn't match
  assert.equal!(parser.lines.last.stack.map(&:type), [:heredoc])
end

def test_broken_heredoc_indented_without_dash(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    text = <<EOF
    Content
      EOF
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Indented EOF shouldn't close heredoc without <<- or <<~
  assert.equal!(parser.lines.last.stack.map(&:type), [:heredoc])
end

def test_broken_unclosed_interpolation(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    msg = "Hello \#{name"
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Should show nested string and interpolation
  final_stack = parser.lines.last.stack.map(&:type)
  assert.true!(final_stack.include?(:string_double))
end

def test_broken_nested_unclosed_interpolation(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    msg = "Outer \#{"inner \#{x"}"
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_interpolation_in_heredoc(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    text = <<EOF
    Hello \#{name
    EOF
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

# ---- Mixed broken syntax -----------------------------------------------------

def test_broken_string_in_unclosed_array(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    items = [
      "unclosed string,
      "normal string"
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_multiple_unclosed_structures(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    class Foo
      def bar
        if condition
          data = {
            items: [
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Should show all nested structures
  expected = [:class, :def, :if, :hash, :array]
  assert.equal!(parser.lines.last.stack.map(&:type), expected)
end

def test_broken_unclosed_everything(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    module App
      class User
        def initialize(name
          @name = "Hello \#{name
          @data = { items: [1, 2
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Parser should handle this gracefully even though it's completely broken
  assert.true!(parser.lines.last.stack.length > 0)
end

# ---- Edge cases --------------------------------------------------------------

def test_broken_only_opening_delimiters(_args, assert)
  sample_code = "([{"
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_only_closing_delimiters(_args, assert)
  sample_code = ")]}"
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_alternating_delimiters(_args, assert)
  sample_code = "([)]"
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_string_with_backslash_at_end(_args, assert)
  sample_code = '"hello\\'
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  assert.equal!(parser.lines[0].stack.map(&:type), [:string_double])
  assert.equal!(parser.lines[0].tokens.map(&:type), [:string])
end

def test_broken_empty_interpolation_no_close(_args, assert)
  sample_code = '"test #{'
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_percent_literal_unclosed(_args, assert)
  sample_code = 'arr = %w[one two'
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_comment_in_string(_args, assert)
  # This is actually valid Ruby, but tests edge case
  sample_code = '"This is a # comment?"'
  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
  # Should treat # as part of string, not comment
  types = parser.lines[0].tokens.map { |t| t[:type] }
  assert.false!(types.include?(:comment))
end

def test_broken_def_without_name(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    def
      puts "oops"
    end
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end

def test_broken_class_without_name(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    class
      def foo; end
    end
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  assert.true!(parser.lines.length > 0)
end
