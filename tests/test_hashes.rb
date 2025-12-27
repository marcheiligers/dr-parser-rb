require_relative 'test_helpers'

# ---- Basic hash parsing ------------------------------------------------------

def test_parses_simple_hash(_args, assert)
  assert_parses_to(assert, '{a: 1}', [
    token(:operator, '{', 0, 0),
    token(:identifier, 'a', 1, 1),
    token(:operator, ':', 2, 2),
    token(:whitespace, ' ', 3, 3),
    token(:number, '1', 4, 4),
    token(:operator, '}', 5, 5)
  ])
end

def test_parses_empty_hash(_args, assert)
  assert_parses_to(assert, '{}', [
    token(:operator, '{', 0, 0),
    token(:operator, '}', 1, 1)
  ])
end

def test_parses_hash_with_hash_rocket(_args, assert)
  assert_parses_to(assert, '{:a => 1}', [
    token(:operator, '{', 0, 0),
    token(:symbol, ':a', 1, 2),
    token(:whitespace, ' ', 3, 3),
    token(:operator, '=>', 4, 5),
    token(:whitespace, ' ', 6, 6),
    token(:number, '1', 7, 7),
    token(:operator, '}', 8, 8)
  ])
end

# ---- Multiline hash tests ----------------------------------------------------

def test_multiline_hash_basic(_args, assert)
  parser1 = Parser::RubyLine.new('{a:').parse
  assert.equal!(parser1.stack.map(&:type), [:hash])
  assert.equal!(parser1.stack.last.depth, 1)

  parser2 = Parser::RubyLine.new('1}', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
  assert.false!(parser1.stack.empty?)  # We dup the stack
end

def test_multiline_hash_empty(_args, assert)
  parser1 = Parser::RubyLine.new('{').parse
  assert.equal!(parser1.stack.map(&:type), [:hash])

  parser2 = Parser::RubyLine.new('}', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_hash_nested(_args, assert)
  parser1 = Parser::RubyLine.new('{{a:').parse
  assert.equal!(parser1.stack.map(&:type), [:hash])
  assert.equal!(parser1.stack.last.depth, 2)

  parser2 = Parser::RubyLine.new('1}}', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_hash_in_array(_args, assert)
  parser1 = Parser::RubyLine.new('[{a:').parse
  assert.equal!(parser1.stack.map(&:type), [:array, :hash])

  parser2 = Parser::RubyLine.new('1}]', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_hash_multiple_lines(_args, assert)
  parser1 = Parser::RubyLine.new('{').parse
  assert.equal!(parser1.stack.map(&:type), [:hash])

  parser2 = Parser::RubyLine.new('a: 1,', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:hash])

  parser3 = Parser::RubyLine.new('b: 2', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:hash])

  parser4 = Parser::RubyLine.new('}', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end
