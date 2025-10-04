require_relative 'test_helpers'

def test_parses_empty_array(_args, assert)
  assert_parses_to(assert, '[]', [
    token(:operator, '[', 0, 0),
    token(:operator, ']', 1, 1)
  ])
end

def test_parses_simple_array(_args, assert)
  assert_parses_to(assert, '[1, 2, 3]', [
    token(:operator, '[', 0, 0),
    token(:number, '1', 1, 1),
    token(:operator, ',', 2, 2),
    token(:whitespace, ' ', 3, 3),
    token(:number, '2', 4, 4),
    token(:operator, ',', 5, 5),
    token(:whitespace, ' ', 6, 6),
    token(:number, '3', 7, 7),
    token(:operator, ']', 8, 8)
  ])
end

def test_parses_array_with_strings(_args, assert)
  assert_parses_to(assert, '["a", "b"]', [
    token(:operator, '[', 0, 0),
    token(:string, '"a"', 1, 3),
    token(:operator, ',', 4, 4),
    token(:whitespace, ' ', 5, 5),
    token(:string, '"b"', 6, 8),
    token(:operator, ']', 9, 9)
  ])
end

def test_parses_percent_w_array(_args, assert)
  assert_parses_to(assert, '%w[one two three]', [
    token(:array_literal, '%w[one two three]', 0, 16)
  ])
end

def test_parses_percent_w_array_with_parens(_args, assert)
  assert_parses_to(assert, '%w(one two three)', [
    token(:array_literal, '%w(one two three)', 0, 16)
  ])
end

def test_parses_percent_w_array_with_braces(_args, assert)
  assert_parses_to(assert, '%w{one two three}', [
    token(:array_literal, '%w{one two three}', 0, 16)
  ])
end

def test_parses_percent_capital_w_array(_args, assert)
  assert_parses_to(assert, '%W[one two three]', [
    token(:array_literal, '%W[one two three]', 0, 16)
  ])
end

def test_parses_percent_i_array(_args, assert)
  assert_parses_to(assert, '%i[foo bar baz]', [
    token(:array_literal, '%i[foo bar baz]', 0, 14)
  ])
end

def test_parses_percent_capital_i_array(_args, assert)
  assert_parses_to(assert, '%I[foo bar baz]', [
    token(:array_literal, '%I[foo bar baz]', 0, 14)
  ])
end

def test_parses_percent_x_array(_args, assert)
  assert_parses_to(assert, '%x[ls -la]', [
    token(:array_literal, '%x[ls -la]', 0, 9)
  ])
end

def test_parses_percent_q_string(_args, assert)
  assert_parses_to(assert, '%q[hello world]', [
    token(:array_literal, '%q[hello world]', 0, 14)
  ])
end

def test_parses_percent_capital_q_string(_args, assert)
  assert_parses_to(assert, '%Q[hello world]', [
    token(:array_literal, '%Q[hello world]', 0, 14)
  ])
end

def test_parses_percent_r_regex(_args, assert)
  assert_parses_to(assert, '%r[pattern]', [
    token(:array_literal, '%r[pattern]', 0, 10)
  ])
end

def test_parses_percent_s_symbol(_args, assert)
  assert_parses_to(assert, '%s[symbol]', [
    token(:array_literal, '%s[symbol]', 0, 9)
  ])
end

def test_parses_nested_array(_args, assert)
  assert_parses_to(assert, '[[1, 2], [3, 4]]', [
    token(:operator, '[', 0, 0),
    token(:operator, '[', 1, 1),
    token(:number, '1', 2, 2),
    token(:operator, ',', 3, 3),
    token(:whitespace, ' ', 4, 4),
    token(:number, '2', 5, 5),
    token(:operator, ']', 6, 6),
    token(:operator, ',', 7, 7),
    token(:whitespace, ' ', 8, 8),
    token(:operator, '[', 9, 9),
    token(:number, '3', 10, 10),
    token(:operator, ',', 11, 11),
    token(:whitespace, ' ', 12, 12),
    token(:number, '4', 13, 13),
    token(:operator, ']', 14, 14),
    token(:operator, ']', 15, 15)
  ])
end

def test_parses_array_with_symbols(_args, assert)
  assert_parses_to(assert, '[:a, :b, :c]', [
    token(:operator, '[', 0, 0),
    token(:symbol, ':a', 1, 2),
    token(:operator, ',', 3, 3),
    token(:whitespace, ' ', 4, 4),
    token(:symbol, ':b', 5, 6),
    token(:operator, ',', 7, 7),
    token(:whitespace, ' ', 8, 8),
    token(:symbol, ':c', 9, 10),
    token(:operator, ']', 11, 11)
  ])
end

def test_parses_array_of_hashes(_args, assert)
  assert_parses_to(assert, '[{a: 1}, {b: 2}]', [
    token(:operator, '[', 0, 0),
    token(:operator, '{', 1, 1),
    token(:identifier, 'a', 2, 2),
    token(:operator, ':', 3, 3),
    token(:whitespace, ' ', 4, 4),
    token(:number, '1', 5, 5),
    token(:operator, '}', 6, 6),
    token(:operator, ',', 7, 7),
    token(:whitespace, ' ', 8, 8),
    token(:operator, '{', 9, 9),
    token(:identifier, 'b', 10, 10),
    token(:operator, ':', 11, 11),
    token(:whitespace, ' ', 12, 12),
    token(:number, '2', 13, 13),
    token(:operator, '}', 14, 14),
    token(:operator, ']', 15, 15)
  ])
end

def test_parses_percent_w_incomplete(_args, assert)
  assert_parses_to(assert, '%w[one two', [
    token(:array_literal, '%w[one two', 0, 9)
  ])
end
