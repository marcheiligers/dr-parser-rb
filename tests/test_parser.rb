require_relative 'test_helpers'

def test_parses_empty_string(_args, assert)
  assert_parses_to(assert, '', [])
end

def test_parses_whitespace_only(_args, assert)
  assert_parses_to(assert, '   ', [
    token(:whitespace, '   ', 0, 2)
  ])
end

def test_parses_simple_number(_args, assert)
  assert_parses_to(assert, '123', [
    token(:number, '123', 0, 2)
  ])
end

def test_parses_number_with_whitespace(_args, assert)
  assert_parses_to(assert, '  123  ', [
    token(:whitespace, '  ', 0, 1),
    token(:number, '123', 2, 4),
    token(:whitespace, '  ', 5, 6)
  ])
end

def test_parses_simple_identifier(_args, assert)
  assert_parses_to(assert, 'foo', [
    token(:identifier, 'foo', 0, 2)
  ])
end

def test_parses_identifier_with_underscore(_args, assert)
  assert_parses_to(assert, 'foo_bar', [
    token(:identifier, 'foo_bar', 0, 6)
  ])
end

def test_parses_operator(_args, assert)
  assert_parses_to(assert, '+', [
    token(:operator, '+', 0, 0)
  ])
end

def test_parses_simple_addition(_args, assert)
  assert_parses_to(assert, '1 + 2', [
    token(:number, '1', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '+', 2, 2),
    token(:whitespace, ' ', 3, 3),
    token(:number, '2', 4, 4)
  ])
end

def test_parses_string_double_quotes(_args, assert)
  assert_parses_to(assert, '"hello"', [
    token(:string, '"hello"', 0, 6)
  ])
end

def test_parses_string_single_quotes(_args, assert)
  assert_parses_to(assert, "'hello'", [
    token(:string, "'hello'", 0, 6)
  ])
end

def test_parses_symbol(_args, assert)
  assert_parses_to(assert, ':foo', [
    token(:symbol, ':foo', 0, 3)
  ])
end

def test_parses_hash_rocket(_args, assert)
  assert_parses_to(assert, '=>', [
    token(:operator, '=>', 0, 1)
  ])
end

def test_parses_comment(_args, assert)
  assert_parses_to(assert, '# comment', [
    token(:comment, '# comment', 0, 8)
  ])
end

def test_parses_code_with_comment(_args, assert)
  assert_parses_to(assert, 'x = 1 # set x', [
    token(:identifier, 'x', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '=', 2, 2),
    token(:whitespace, ' ', 3, 3),
    token(:number, '1', 4, 4),
    token(:whitespace, ' ', 5, 5),
    token(:comment, '# set x', 6, 12)
  ])
end
