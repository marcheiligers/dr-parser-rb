require_relative 'test_helpers'

def test_parses_string_with_interpolation(_args, assert)
  assert_parses_to(assert, '"hello #{name}"', [
    token(:string, '"hello ', 0, 6),
    token(:interpolation_start, '#{', 7, 8),
    token(:identifier, 'name', 9, 12),
    token(:interpolation_end, '}', 13, 13),
    token(:string, '"', 14, 14)
  ])
end

def test_parses_string_with_multiple_interpolations(_args, assert)
  assert_parses_to(assert, '"#{first} #{last}"', [
    token(:string, '"', 0, 0),
    token(:interpolation_start, '#{', 1, 2),
    token(:identifier, 'first', 3, 7),
    token(:interpolation_end, '}', 8, 8),
    token(:string, ' ', 9, 9),
    token(:interpolation_start, '#{', 10, 11),
    token(:identifier, 'last', 12, 15),
    token(:interpolation_end, '}', 16, 16),
    token(:string, '"', 17, 17)
  ])
end

def test_parses_string_with_nested_interpolation(_args, assert)
  assert_parses_to(assert, '"value: #{obj.value}"', [
    token(:string, '"value: ', 0, 7),
    token(:interpolation_start, '#{', 8, 9),
    token(:identifier, 'obj', 10, 12),
    token(:operator, '.', 13, 13),
    token(:identifier, 'value', 14, 18),
    token(:interpolation_end, '}', 19, 19),
    token(:string, '"', 20, 20)
  ])
end

def test_parses_string_with_expression_interpolation(_args, assert)
  assert_parses_to(assert, '"sum: #{1 + 2}"', [
    token(:string, '"sum: ', 0, 5),
    token(:interpolation_start, '#{', 6, 7),
    token(:number, '1', 8, 8),
    token(:whitespace, ' ', 9, 9),
    token(:operator, '+', 10, 10),
    token(:whitespace, ' ', 11, 11),
    token(:number, '2', 12, 12),
    token(:interpolation_end, '}', 13, 13),
    token(:string, '"', 14, 14)
  ])
end

def test_parses_string_with_incomplete_interpolation(_args, assert)
  assert_parses_to(assert, '"hello #{name', [
    token(:string, '"hello ', 0, 6),
    token(:interpolation_start, '#{', 7, 8),
    token(:identifier, 'name', 9, 12)
  ])
end

def test_parses_empty_interpolation(_args, assert)
  assert_parses_to(assert, '"result: #{}"', [
    token(:string, '"result: ', 0, 8),
    token(:interpolation_start, '#{', 9, 10),
    token(:interpolation_end, '}', 11, 11),
    token(:string, '"', 12, 12)
  ])
end

def test_parses_interpolation_with_curly_braces(_args, assert)
  assert_parses_to(assert, '"hash: #{{a: 1}}"', [
    token(:string, '"hash: ', 0, 6),
    token(:interpolation_start, '#{', 7, 8),
    token(:operator, '{', 9, 9),
    token(:identifier, 'a', 10, 10),
    token(:operator, ':', 11, 11),
    token(:whitespace, ' ', 12, 12),
    token(:number, '1', 13, 13),
    token(:operator, '}', 14, 14),
    token(:interpolation_end, '}', 15, 15),
    token(:string, '"', 16, 16)
  ])
end

def test_parses_escaped_interpolation(_args, assert)
  assert_parses_to(assert, '"not \#{interpolated}"', [
    token(:string, '"not \#{interpolated}"', 0, 21)
  ])
end

def test_single_quote_no_interpolation(_args, assert)
  input = "'hello " + '#{name}' + "'"
  assert_parses_to(assert, input, [
    token(:string, input, 0, 14)
  ])
end

def test_parses_string_at_start(_args, assert)
  assert_parses_to(assert, '"hello"', [
    token(:string, '"hello"', 0, 6)
  ])
end

def test_parses_interpolation_at_start(_args, assert)
  assert_parses_to(assert, '"#{x}"', [
    token(:string, '"', 0, 0),
    token(:interpolation_start, '#{', 1, 2),
    token(:identifier, 'x', 3, 3),
    token(:interpolation_end, '}', 4, 4),
    token(:string, '"', 5, 5)
  ])
end

def test_parses_ivar_in_interpolation(_args, assert)
  assert_parses_to(assert, '"hello #{@name}"', [
    token(:string, '"hello ', 0, 6),
    token(:interpolation_start, '#{', 7, 8),
    token(:ivar, '@name', 9, 13),
    token(:interpolation_end, '}', 14, 14),
    token(:string, '"', 15, 15)
  ])
end

# ---- Backtick strings (shell commands) ----------------------------------------

def test_parses_backtick_string(_args, assert)
  assert_parses_to(assert, '`ls -la`', [
    token(:backtick, '`ls -la`', 0, 7)
  ])
end

def test_parses_backtick_with_interpolation(_args, assert)
  assert_parses_to(assert, '`echo #{name}`', [
    token(:backtick, '`echo ', 0, 5),
    token(:interpolation_start, '#{', 6, 7),
    token(:identifier, 'name', 8, 11),
    token(:interpolation_end, '}', 12, 12),
    token(:backtick, '`', 13, 13)
  ])
end

def test_parses_backtick_assignment(_args, assert)
  assert_parses_to(assert, 'output = `ls`', [
    token(:identifier, 'output', 0, 5),
    token(:whitespace, ' ', 6, 6),
    token(:operator, '=', 7, 7),
    token(:whitespace, ' ', 8, 8),
    token(:backtick, '`ls`', 9, 12)
  ])
end

def test_parses_incomplete_backtick(_args, assert)
  parser = Parser::RubyLine.new('`ls -la').parse
  assert.equal!(parser.stack.map(&:type), [:backtick])
  types = parser.tokens.map { |t| t[:type] }
  assert.true!(types.include?(:backtick))
end

def test_closing_brace_without_frame(_args, assert)
  code = <<~CODE
    shrug = 123 }
  CODE
  parser = Parser::Ruby.new(code)
  assert.true!(parser.lines.length > 0)
end

# ---- Test stack --------------------------------------------------------------

def test_stack_empty_for_a_full_string(_args, assert)
  parser = Parser::RubyLine.new('"hello, world"').parse
  assert.true!(parser.stack.empty?)
end

def test_stack_empty_for_a_full_string_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('"hello, #{"world"}"').parse
  assert.true!(parser.stack.empty?)
end

def test_stack_string_double_for_incomplete_string(_args, assert)
  parser = Parser::RubyLine.new('"hello, world').parse
  assert.equal!(parser.stack.map(&:type), [:string_double])
end

def test_stack_string_double_for_incomplete_string_in_interpolation(_args, assert)
  parser = Parser::RubyLine.new('"hello, #{"world').parse
  assert.equal!(parser.stack.map(&:type), [:string_double, :interpolation, :string_double])
end

def test_stack_for_two_line_horror_string_with_interpolation(_args, assert)
  parser1 = Parser::RubyLine.new('"hello, #{"world').parse
  assert.equal!(parser1.stack.map(&:type), [:string_double, :interpolation, :string_double])

  parser2 = Parser::RubyLine.new('"}"', parser1.stack).parse
  assert.true!(parser2.stack.empty?)

  assert.false!(parser1.stack.empty?) # We dup the stack
end

def test_multiline_interpolation_in_a_string(_args, assert)
  code = <<~CODE
    str = "something \#{
      this
    } way comes
    "
  CODE
  parser = Parser::Ruby.new(code)
  assert.true!(parser.lines.last.stack.empty?)
  # debug_parser(parser)
end

