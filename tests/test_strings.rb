require_relative 'test_helpers'

def test_parses_string_with_interpolation(_args, assert)
  assert_parses_to(assert, '"hello #{name}"', [
    token(:string, '"hello #{name}"', 0, 14)
  ])
end

def test_parses_string_with_multiple_interpolations(_args, assert)
  assert_parses_to(assert, '"#{first} #{last}"', [
    token(:string, '"#{first} #{last}"', 0, 17)
  ])
end

def test_parses_string_with_nested_interpolation(_args, assert)
  assert_parses_to(assert, '"value: #{obj.value}"', [
    token(:string, '"value: #{obj.value}"', 0, 20)
  ])
end

def test_parses_string_with_expression_interpolation(_args, assert)
  assert_parses_to(assert, '"sum: #{1 + 2}"', [
    token(:string, '"sum: #{1 + 2}"', 0, 14)
  ])
end

def test_parses_string_with_incomplete_interpolation(_args, assert)
  assert_parses_to(assert, '"hello #{name', [
    token(:string, '"hello #{name', 0, 12)
  ])
end

def test_parses_empty_interpolation(_args, assert)
  assert_parses_to(assert, '"result: #{}"', [
    token(:string, '"result: #{}"', 0, 12)
  ])
end

def test_parses_interpolation_with_curly_braces(_args, assert)
  assert_parses_to(assert, '"hash: #{{a: 1}}"', [
    token(:string, '"hash: #{{a: 1}}"', 0, 16)
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
