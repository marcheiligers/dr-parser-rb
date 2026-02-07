require_relative 'test_helpers'

# ---- Basic parentheses parsing -----------------------------------------------

def test_parses_simple_parens(_args, assert)
  assert_parses_to(assert, '(1 + 2)', [
    token(:operator, '(', 0, 0),
    token(:number, '1', 1, 1),
    token(:whitespace, ' ', 2, 2),
    token(:operator, '+', 3, 3),
    token(:whitespace, ' ', 4, 4),
    token(:number, '2', 5, 5),
    token(:operator, ')', 6, 6)
  ])
end

def test_parses_empty_parens(_args, assert)
  assert_parses_to(assert, '()', [
    token(:operator, '(', 0, 0),
    token(:operator, ')', 1, 1)
  ])
end

def test_parses_method_call_with_parens(_args, assert)
  assert_parses_to(assert, 'foo(1, 2)', [
    token(:identifier, 'foo', 0, 2),
    token(:operator, '(', 3, 3),
    token(:number, '1', 4, 4),
    token(:operator, ',', 5, 5),
    token(:whitespace, ' ', 6, 6),
    token(:number, '2', 7, 7),
    token(:operator, ')', 8, 8)
  ])
end

# ---- Multiline parentheses tests ---------------------------------------------

def test_multiline_parens_basic(_args, assert)
  parser1 = Parser::RubyLine.new('(1 +').parse
  assert.equal!(parser1.stack.map(&:type), [:paren])

  parser2 = Parser::RubyLine.new('2)', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
  assert.false!(parser1.stack.empty?)  # We dup the stack
end

def test_multiline_parens_empty(_args, assert)
  parser1 = Parser::RubyLine.new('(').parse
  assert.equal!(parser1.stack.map(&:type), [:paren])

  parser2 = Parser::RubyLine.new(')', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_parens_nested(_args, assert)
  parser1 = Parser::RubyLine.new('((1 +').parse
  assert.equal!(parser1.stack.map(&:type), [:paren, :paren])

  parser2 = Parser::RubyLine.new('2))', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_method_call_args(_args, assert)
  parser1 = Parser::RubyLine.new('foo(').parse
  assert.equal!(parser1.stack.map(&:type), [:paren])

  parser2 = Parser::RubyLine.new('1,', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:paren])

  parser3 = Parser::RubyLine.new('2', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:paren])

  parser4 = Parser::RubyLine.new(')', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_parens_with_array(_args, assert)
  parser1 = Parser::RubyLine.new('([1,').parse
  assert.equal!(parser1.stack.map(&:type), [:paren, :array])

  parser2 = Parser::RubyLine.new('2])', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end
