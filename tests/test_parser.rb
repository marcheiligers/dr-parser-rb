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

def test_parses_incomplete_double_quote_string(_args, assert)
  assert_parses_to(assert, '"hello', [
    token(:string, '"hello', 0, 5)
  ])
end

def test_parses_incomplete_single_quote_string(_args, assert)
  assert_parses_to(assert, "'hello", [
    token(:string, "'hello", 0, 5)
  ])
end

def test_parses_incomplete_string_with_code_after(_args, assert)
  assert_parses_to(assert, '"hello + 1', [
    token(:string, '"hello + 1', 0, 9)
  ])
end

def test_parses_incomplete_string_with_escape(_args, assert)
  assert_parses_to(assert, '"hello\\"', [
    token(:string, '"hello\\"', 0, 7)
  ])
end

def test_parses_keyword_class(_args, assert)
  assert_parses_to(assert, 'class', [
    token(:keyword, 'class', 0, 4)
  ])
end

def test_parses_keyword_def(_args, assert)
  assert_parses_to(assert, 'def', [
    token(:keyword, 'def', 0, 2)
  ])
end

def test_parses_keyword_module(_args, assert)
  assert_parses_to(assert, 'module', [
    token(:keyword, 'module', 0, 5)
  ])
end

def test_parses_keyword_end(_args, assert)
  assert_parses_to(assert, 'end', [
    token(:keyword, 'end', 0, 2)
  ])
end

def test_parses_keywords_if_else(_args, assert)
  assert_parses_to(assert, 'if true else false end', [
    token(:keyword, 'if', 0, 1),
    token(:whitespace, ' ', 2, 2),
    token(:keyword, 'true', 3, 6),
    token(:whitespace, ' ', 7, 7),
    token(:keyword, 'else', 8, 11),
    token(:whitespace, ' ', 12, 12),
    token(:keyword, 'false', 13, 17),
    token(:whitespace, ' ', 18, 18),
    token(:keyword, 'end', 19, 21)
  ])
end

def test_distinguishes_keyword_from_identifier(_args, assert)
  assert_parses_to(assert, 'class_name', [
    token(:identifier, 'class_name', 0, 9)
  ])
end

def test_parses_def_method(_args, assert)
  assert_parses_to(assert, 'def foo', [
    token(:keyword, 'def', 0, 2),
    token(:whitespace, ' ', 3, 3),
    token(:identifier, 'foo', 4, 6)
  ])
end

def test_parses_decimal_number(_args, assert)
  assert_parses_to(assert, '3.14', [
    token(:number, '3.14', 0, 3)
  ])
end

def test_parses_number_with_underscores(_args, assert)
  assert_parses_to(assert, '1_000', [
    token(:number, '1_000', 0, 4)
  ])
end

def test_parses_large_number_with_underscores(_args, assert)
  assert_parses_to(assert, '1_000_000', [
    token(:number, '1_000_000', 0, 8)
  ])
end

def test_parses_decimal_with_underscores(_args, assert)
  assert_parses_to(assert, '1_234.567_89', [
    token(:number, '1_234.567_89', 0, 11)
  ])
end

def test_parses_method_call_on_number(_args, assert)
  assert_parses_to(assert, '10.seconds', [
    token(:number, '10', 0, 1),
    token(:operator, '.', 2, 2),
    token(:identifier, 'seconds', 3, 9)
  ])
end

def test_parses_chained_method_calls_on_number(_args, assert)
  assert_parses_to(assert, '10.seconds.ago', [
    token(:number, '10', 0, 1),
    token(:operator, '.', 2, 2),
    token(:identifier, 'seconds', 3, 9),
    token(:operator, '.', 10, 10),
    token(:identifier, 'ago', 11, 13)
  ])
end

def test_parses_number_ending_with_dot_space(_args, assert)
  assert_parses_to(assert, '10. ', [
    token(:number, '10', 0, 1),
    token(:operator, '.', 2, 2),
    token(:whitespace, ' ', 3, 3)
  ])
end

def test_parses_constant(_args, assert)
  assert_parses_to(assert, 'Foo', [
    token(:constant, 'Foo', 0, 2)
  ])
end

def test_parses_screaming_snake_case_constant(_args, assert)
  assert_parses_to(assert, 'MY_CONSTANT', [
    token(:constant, 'MY_CONSTANT', 0, 10)
  ])
end

def test_parses_class_definition(_args, assert)
  assert_parses_to(assert, 'class Foo', [
    token(:keyword, 'class', 0, 4),
    token(:whitespace, ' ', 5, 5),
    token(:constant, 'Foo', 6, 8)
  ])
end

def test_parses_namespaced_constant(_args, assert)
  assert_parses_to(assert, 'Foo::Bar', [
    token(:constant, 'Foo', 0, 2),
    token(:operator, '::', 3, 4),
    token(:constant, 'Bar', 5, 7)
  ])
end

def test_parses_constant_assignment(_args, assert)
  assert_parses_to(assert, 'MAX = 100', [
    token(:constant, 'MAX', 0, 2),
    token(:whitespace, ' ', 3, 3),
    token(:operator, '=', 4, 4),
    token(:whitespace, ' ', 5, 5),
    token(:number, '100', 6, 8)
  ])
end

def test_parses_module_definition(_args, assert)
  assert_parses_to(assert, 'module MyModule', [
    token(:keyword, 'module', 0, 5),
    token(:whitespace, ' ', 6, 6),
    token(:constant, 'MyModule', 7, 14)
  ])
end

def test_parses_predicate_method(_args, assert)
  assert_parses_to(assert, 'empty?', [
    token(:identifier, 'empty?', 0, 5)
  ])
end

def test_parses_bang_method(_args, assert)
  assert_parses_to(assert, 'save!', [
    token(:identifier, 'save!', 0, 4)
  ])
end

def test_parses_method_call_with_predicate(_args, assert)
  assert_parses_to(assert, 'arr.empty?', [
    token(:identifier, 'arr', 0, 2),
    token(:operator, '.', 3, 3),
    token(:identifier, 'empty?', 4, 9)
  ])
end

def test_parses_method_call_with_bang(_args, assert)
  assert_parses_to(assert, 'obj.save!', [
    token(:identifier, 'obj', 0, 2),
    token(:operator, '.', 3, 3),
    token(:identifier, 'save!', 4, 8)
  ])
end

def test_parses_def_predicate_method(_args, assert)
  assert_parses_to(assert, 'def valid?', [
    token(:keyword, 'def', 0, 2),
    token(:whitespace, ' ', 3, 3),
    token(:identifier, 'valid?', 4, 9)
  ])
end

def test_parses_def_bang_method(_args, assert)
  assert_parses_to(assert, 'def reset!', [
    token(:keyword, 'def', 0, 2),
    token(:whitespace, ' ', 3, 3),
    token(:identifier, 'reset!', 4, 9)
  ])
end

def test_parses_quoted_symbol_with_interpolation(_args, assert)
  assert_parses_to(assert, ':"prefix_#{name}"', [
    token(:symbol, ':"', 0, 1),
    token(:string, 'prefix_', 2, 8),
    token(:interpolation_start, '#{', 9, 10),
    token(:identifier, 'name', 11, 14),
    token(:interpolation_end, '}', 15, 15),
    token(:string, '"', 16, 16)
  ])
end

def test_parses_stabby_lambda_operator(_args, assert)
  assert_parses_to(assert, '->', [
    token(:lambda, '->', 0, 1)
  ])
end

def test_parses_instance_variable(_args, assert)
  assert_parses_to(assert, '@name', [
    token(:ivar, '@name', 0, 4)
  ])
end

def test_parses_instance_variable_with_underscore(_args, assert)
  assert_parses_to(assert, '@my_var', [
    token(:ivar, '@my_var', 0, 6)
  ])
end

def test_parses_instance_variable_assignment(_args, assert)
  assert_parses_to(assert, '@name = "test"', [
    token(:ivar, '@name', 0, 4),
    token(:whitespace, ' ', 5, 5),
    token(:operator, '=', 6, 6),
    token(:whitespace, ' ', 7, 7),
    token(:string, '"test"', 8, 13)
  ])
end

def test_parses_instance_variable_method_call(_args, assert)
  assert_parses_to(assert, '@items.length', [
    token(:ivar, '@items', 0, 5),
    token(:operator, '.', 6, 6),
    token(:identifier, 'length', 7, 12)
  ])
end

def test_parses_class_variable(_args, assert)
  assert_parses_to(assert, '@@count', [
    token(:cvar, '@@count', 0, 6)
  ])
end

def test_parses_class_variable_assignment(_args, assert)
  assert_parses_to(assert, '@@count = 0', [
    token(:cvar, '@@count', 0, 6),
    token(:whitespace, ' ', 7, 7),
    token(:operator, '=', 8, 8),
    token(:whitespace, ' ', 9, 9),
    token(:number, '0', 10, 10)
  ])
end

# ---- Numeric literal variations -----------------------------------------------

def test_parses_hex_literal(_args, assert)
  assert_parses_to(assert, '0xFF', [
    token(:number, '0xFF', 0, 3)
  ])
end

def test_parses_hex_literal_uppercase(_args, assert)
  assert_parses_to(assert, '0XAB', [
    token(:number, '0XAB', 0, 3)
  ])
end

def test_parses_binary_literal(_args, assert)
  assert_parses_to(assert, '0b1010', [
    token(:number, '0b1010', 0, 5)
  ])
end

def test_parses_octal_literal(_args, assert)
  assert_parses_to(assert, '0o755', [
    token(:number, '0o755', 0, 4)
  ])
end

def test_parses_scientific_notation(_args, assert)
  assert_parses_to(assert, '1.5e10', [
    token(:number, '1.5e10', 0, 5)
  ])
end

def test_parses_scientific_notation_negative_exponent(_args, assert)
  assert_parses_to(assert, '2.5e-3', [
    token(:number, '2.5e-3', 0, 5)
  ])
end

def test_parses_scientific_notation_positive_exponent(_args, assert)
  assert_parses_to(assert, '1e+5', [
    token(:number, '1e+5', 0, 3)
  ])
end

# ---- Character literals -------------------------------------------------------

def test_parses_character_literal(_args, assert)
  assert_parses_to(assert, 'char = ?a', [
    token(:identifier, 'char', 0, 3),
    token(:whitespace, ' ', 4, 4),
    token(:operator, '=', 5, 5),
    token(:whitespace, ' ', 6, 6),
    token(:string, '?a', 7, 8)
  ])
end

def test_parses_escaped_character_literal(_args, assert)
  assert_parses_to(assert, '?\\n', [
    token(:string, '?\\n', 0, 2)
  ])
end

def test_parses_ternary_not_character(_args, assert)
  # After an identifier, ? should be ternary operator, not character literal
  assert_parses_to(assert, 'x ?a', [
    token(:identifier, 'x', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '?', 2, 2),
    token(:identifier, 'a', 3, 3)
  ])
end

# ---- Range operators ----------------------------------------------------------

def test_parses_inclusive_range(_args, assert)
  assert_parses_to(assert, '1..10', [
    token(:number, '1', 0, 0),
    token(:operator, '..', 1, 2),
    token(:number, '10', 3, 4)
  ])
end

def test_parses_exclusive_range(_args, assert)
  assert_parses_to(assert, '1...10', [
    token(:number, '1', 0, 0),
    token(:operator, '...', 1, 3),
    token(:number, '10', 4, 5)
  ])
end

# ---- Compound assignment operators --------------------------------------------

def test_parses_plus_equals(_args, assert)
  assert_parses_to(assert, 'x += 1', [
    token(:identifier, 'x', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '+=', 2, 3),
    token(:whitespace, ' ', 4, 4),
    token(:number, '1', 5, 5)
  ])
end

def test_parses_minus_equals(_args, assert)
  assert_parses_to(assert, 'x -= 1', [
    token(:identifier, 'x', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '-=', 2, 3),
    token(:whitespace, ' ', 4, 4),
    token(:number, '1', 5, 5)
  ])
end

def test_parses_or_equals(_args, assert)
  assert_parses_to(assert, 'x ||= 5', [
    token(:identifier, 'x', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '||=', 2, 4),
    token(:whitespace, ' ', 5, 5),
    token(:number, '5', 6, 6)
  ])
end

def test_parses_and_equals(_args, assert)
  assert_parses_to(assert, 'x &&= 5', [
    token(:identifier, 'x', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '&&=', 2, 4),
    token(:whitespace, ' ', 5, 5),
    token(:number, '5', 6, 6)
  ])
end

def test_parses_power_operator(_args, assert)
  assert_parses_to(assert, '2 ** 8', [
    token(:number, '2', 0, 0),
    token(:whitespace, ' ', 1, 1),
    token(:operator, '**', 2, 3),
    token(:whitespace, ' ', 4, 4),
    token(:number, '8', 5, 5)
  ])
end

def test_parses_scope_resolution(_args, assert)
  assert_parses_to(assert, 'Foo::Bar', [
    token(:constant, 'Foo', 0, 2),
    token(:operator, '::', 3, 4),
    token(:constant, 'Bar', 5, 7)
  ])
end

def test_parses_global_variable(_args, assert)
  assert_parses_to(assert, '$global', [
    token(:global, '$global', 0, 6)
  ])
end

def test_parses_global_with_underscore(_args, assert)
  assert_parses_to(assert, '$my_global', [
    token(:global, '$my_global', 0, 9)
  ])
end

def test_parses_special_globals(_args, assert)
  assert_parses_to(assert, '$0', [
    token(:global, '$0', 0, 1)
  ])
end

def test_parses_dollar_sign_globals(_args, assert)
  assert_parses_to(assert, '$$', [
    token(:global, '$$', 0, 1)
  ])
end

def test_parses_global_in_expression(_args, assert)
  assert_parses_to(assert, '$gtk.args', [
    token(:global, '$gtk', 0, 3),
    token(:operator, '.', 4, 4),
    token(:identifier, 'args', 5, 8)
  ])
end

def test_parses_global_assignment(_args, assert)
  assert_parses_to(assert, '$count = 0', [
    token(:global, '$count', 0, 5),
    token(:whitespace, ' ', 6, 6),
    token(:operator, '=', 7, 7),
    token(:whitespace, ' ', 8, 8),
    token(:number, '0', 9, 9)
  ])
end
