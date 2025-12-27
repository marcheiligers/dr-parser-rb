require_relative 'test_helpers'

# ---- Known parsing failures - TODO items for future work --------------------
# These tests document code patterns that don't currently parse correctly.
# DO NOT FIX THESE - they are intentionally failing to track missing features.

# ---- Multiple heredocs on same line ------------------------------------------

def test_multiple_heredocs_same_line(_args, assert)
  # Ruby allows multiple heredocs started on the same line
  parser = Parser::RubyLine.new('foo(<<A, <<B)').parse
  assert.equal!(parser.stack.map(&:type), [:paren, :heredoc])  # Should track both heredocs
end

# ---- Heredoc with method chaining on delimiter -------------------------------

def test_heredoc_method_chain_on_delimiter(_args, assert)
  # Method calls after the closing delimiter line
  parser1 = Parser::RubyLine.new('msg = <<TEXT').parse
  parser2 = Parser::RubyLine.new('Hello', parser1.stack).parse
  parser3 = Parser::RubyLine.new('TEXT.upcase.strip', parser2.stack).parse

  # Should parse .upcase.strip as method calls
  types = parser3.tokens.map { |t| t[:type] }
  assert.true!(types.include?(:operator))  # The . operators
  assert.true!(types.include?(:identifier))  # upcase, strip
end

# ---- Percent literal variations ----------------------------------------------

def test_percent_w_with_square_brackets(_args, assert)
  parser = Parser::RubyLine.new('arr = %w[one two three]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_percent_w_with_curly_braces(_args, assert)
  parser = Parser::RubyLine.new('arr = %w{one two three}').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_percent_w_with_pipes(_args, assert)
  parser = Parser::RubyLine.new('arr = %w|one two three|').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

# ---- Regular expressions -----------------------------------------------------

def test_regex_literal(_args, assert)
  parser = Parser::RubyLine.new('pattern = /\\d+/').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

def test_regex_with_modifiers(_args, assert)
  parser = Parser::RubyLine.new('pattern = /hello/i').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

def test_regex_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('pattern = /#{prefix}\\d+/').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:interpolation_start))
end

# ---- Lambda and proc syntax --------------------------------------------------

def test_stabby_lambda(_args, assert)
  parser = Parser::RubyLine.new('f = ->(x) { x * 2 }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:lambda))
end

def test_lambda_keyword(_args, assert)
  parser1 = Parser::RubyLine.new('f = lambda do |x|').parse
  assert.equal!(parser1.stack.map(&:type), [:lambda])
end

def test_proc_new(_args, assert)
  parser1 = Parser::RubyLine.new('p = Proc.new do').parse
  assert.equal!(parser1.stack.map(&:type), [:do_block])
end

# ---- Ternary operator --------------------------------------------------------

def test_ternary_operator(_args, assert)
  parser = Parser::RubyLine.new('result = x > 5 ? "big" : "small"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:ternary_question))
  assert.true!(tokens.include?(:ternary_colon))
end

# ---- Range operators ---------------------------------------------------------

def test_inclusive_range(_args, assert)
  parser = Parser::RubyLine.new('range = 1..10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:range_inclusive))
end

def test_exclusive_range(_args, assert)
  parser = Parser::RubyLine.new('range = 1...10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:range_exclusive))
end

# ---- Splat and double splat --------------------------------------------------

def test_splat_in_method_call(_args, assert)
  parser = Parser::RubyLine.new('foo(*args)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:splat))
end

def test_double_splat_in_hash(_args, assert)
  parser = Parser::RubyLine.new('h = { a: 1, **other }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:double_splat))
end

# ---- Safe navigation operator ------------------------------------------------

def test_safe_navigation(_args, assert)
  parser = Parser::RubyLine.new('result = obj&.method').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:safe_navigation))
end

# ---- String escape sequences -------------------------------------------------

def test_string_with_newline_escape(_args, assert)
  parser = Parser::RubyLine.new('"hello\\nworld"').parse
  # Should properly handle \n escape
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens, [:string])
end

def test_string_with_tab_escape(_args, assert)
  parser = Parser::RubyLine.new('"hello\\tworld"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens, [:string])
end

# ---- BEGIN and END blocks ----------------------------------------------------

def test_begin_block(_args, assert)
  parser = Parser::RubyLine.new('BEGIN { puts "starting" }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:begin_block))
end

def test_end_block(_args, assert)
  parser = Parser::RubyLine.new('END { puts "ending" }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:end_block))
end

# ---- Keyword arguments -------------------------------------------------------

def test_keyword_arguments_in_def(_args, assert)
  parser = Parser::RubyLine.new('def foo(x:, y: 5)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  # Should distinguish keyword args from regular hash syntax
  assert.true!(tokens.include?(:keyword_arg))
end

def test_keyword_arguments_in_call(_args, assert)
  parser = Parser::RubyLine.new('foo(x: 10, y: 20)').parse
  # Currently might parse as hash, but in method call context these are keyword args
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(parser.stack.map(&:type), [])
end

# ---- Block parameters --------------------------------------------------------

def test_block_with_multiple_params(_args, assert)
  parser = Parser::RubyLine.new('hash.each do |key, value|').parse
  tokens = parser.tokens.map { |t| t[:type] }
  # Should properly parse block parameters
  assert.true!(tokens.include?(:block_param))
end

# ---- Heredoc in interpolation ------------------------------------------------

def test_heredoc_in_string_interpolation(_args, assert)
  # This is valid Ruby but very unusual
  parser = Parser::RubyLine.new('"start #{<<TEXT} end"').parse
  assert.equal!(parser.stack.map(&:type), [:string_double, :heredoc])
end

# ---- Method definition edge cases --------------------------------------------

def test_def_with_default_params(_args, assert)
  parser = Parser::RubyLine.new('def foo(x, y = 10, z = 20)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  # Should track default parameter values
  assert.true!(tokens.include?(:default_param))
end

def test_def_with_splat_param(_args, assert)
  parser = Parser::RubyLine.new('def foo(*args)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:splat))
end

# ---- Multiline strings with backslash continuation --------------------------

# TODO: this is not a backslash continuation, but we do need to implement that
def test_string_continuation(_args, assert)
  parser1 = Parser::RubyLine.new('"hello \\').parse
  parser2 = Parser::RubyLine.new('world"', parser1.stack).parse
  # Should treat backslash-newline as continuation
  assert.equal!(parser2.stack.map(&:type), [])
end

# ---- Character literals ------------------------------------------------------

def test_character_literal(_args, assert)
  parser = Parser::RubyLine.new('char = ?a').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:character))
end

# ---- Numeric literals --------------------------------------------------------

def test_binary_literal(_args, assert)
  parser = Parser::RubyLine.new('num = 0b1010').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last[:type], :number)
end

def test_octal_literal(_args, assert)
  parser = Parser::RubyLine.new('num = 0o755').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last[:type], :number)
end

def test_hex_literal(_args, assert)
  parser = Parser::RubyLine.new('num = 0xFF').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last[:type], :number)
end

# ---- Operator edge cases -----------------------------------------------------

def test_spaceship_operator(_args, assert)
  parser = Parser::RubyLine.new('result = a <=> b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:spaceship))
end

def test_power_operator(_args, assert)
  parser = Parser::RubyLine.new('result = 2 ** 8').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:power))
end

def test_modulo_assign(_args, assert)
  parser = Parser::RubyLine.new('x %= 5').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:modulo_assign))
end

# TODO: or equals ||=, and equals &&=

# ---- More percent literals ---------------------------------------------------

def test_percent_q_lowercase(_args, assert)
  parser = Parser::RubyLine.new('str = %q(hello world)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))
end

def test_percent_Q_uppercase(_args, assert)
  parser = Parser::RubyLine.new('str = %Q(hello #{name})').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))
  assert.true!(tokens.include?(:interpolation_start))
end

def test_percent_r_regex(_args, assert)
  parser = Parser::RubyLine.new('pattern = %r{\\d+}i').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

def test_percent_i_symbol_array(_args, assert)
  parser = Parser::RubyLine.new('syms = %i[foo bar baz]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol_array))
end

def test_percent_I_symbol_array_interpolated(_args, assert)
  parser = Parser::RubyLine.new('syms = %I[foo #{x} baz]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol_array))
end

def test_percent_s_symbol(_args, assert)
  parser = Parser::RubyLine.new('sym = %s[foo bar]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol))
end

def test_percent_x_command(_args, assert)
  parser = Parser::RubyLine.new('output = %x(ls -la)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:command))
end

# ---- Symbol to proc ----------------------------------------------------------

def test_symbol_to_proc(_args, assert)
  parser = Parser::RubyLine.new('arr.map(&:to_s)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol_to_proc))
end

# ---- Variable types ----------------------------------------------------------

def test_global_variable(_args, assert)
  parser = Parser::RubyLine.new('$global = 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:global_variable))
end

def test_instance_variable(_args, assert)
  parser = Parser::RubyLine.new('@instance = 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:instance_variable))
end

def test_class_variable(_args, assert)
  parser = Parser::RubyLine.new('@@class_var = 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:class_variable))
end

# ---- Parallel assignment -----------------------------------------------------

# TODO: do we care?
def test_parallel_assignment(_args, assert)
  parser = Parser::RubyLine.new('a, b = 1, 2').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:parallel_assign))
end

def test_array_destructuring(_args, assert)
  parser = Parser::RubyLine.new('a, b = [1, 2]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:parallel_assign))
end

# ---- Rescue modifier ---------------------------------------------------------

def test_rescue_modifier(_args, assert)
  parser = Parser::RubyLine.new('value = dangerous_call rescue default').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:rescue_modifier))
end

# ---- Symbol literals ---------------------------------------------------------

def test_quoted_symbol(_args, assert)
  parser = Parser::RubyLine.new('sym = :"symbol with spaces"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol))
end

def test_symbol_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('sym = :"prefix_#{name}"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol))
  assert.true!(tokens.include?(:interpolation_start))
end

# ---- Modifier if/unless/while/until ------------------------------------------

def test_modifier_if(_args, assert)
  parser = Parser::RubyLine.new('puts "hello" if condition').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:modifier_if))
end

def test_modifier_unless(_args, assert)
  parser = Parser::RubyLine.new('puts "hello" unless condition').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:modifier_unless))
end

def test_modifier_while(_args, assert)
  parser = Parser::RubyLine.new('x += 1 while x < 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:modifier_while))
end

def test_modifier_until(_args, assert)
  parser = Parser::RubyLine.new('x += 1 until x > 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:modifier_until))
end

# ---- Logical operators -------------------------------------------------------

def test_and_operator(_args, assert)
  parser = Parser::RubyLine.new('result = x and y').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:and))
end

def test_or_operator(_args, assert)
  parser = Parser::RubyLine.new('result = x or y').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:or))
end

def test_not_operator(_args, assert)
  parser = Parser::RubyLine.new('result = not condition').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:not))
end

# ---- Bitwise operators -------------------------------------------------------

# TODO: bitwise assignments?
def test_bitwise_and(_args, assert)
  parser = Parser::RubyLine.new('result = a & b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:bitwise_and))
end

def test_bitwise_or(_args, assert)
  parser = Parser::RubyLine.new('result = a | b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:bitwise_or))
end

def test_bitwise_xor(_args, assert)
  parser = Parser::RubyLine.new('result = a ^ b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:bitwise_xor))
end

def test_bitwise_not(_args, assert)
  parser = Parser::RubyLine.new('result = ~a').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:bitwise_not))
end

def test_left_shift(_args, assert)
  parser = Parser::RubyLine.new('result = a << b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:left_shift))
end

def test_right_shift(_args, assert)
  parser = Parser::RubyLine.new('result = a >> b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:right_shift))
end

# ---- Numeric literals with underscores ---------------------------------------

def test_number_with_underscores(_args, assert)
  parser = Parser::RubyLine.new('big = 1_000_000').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last[:type], :number)
end

def test_float_with_exponent(_args, assert)
  parser = Parser::RubyLine.new('sci = 1.5e10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last[:type], :number)
end

# ---- Attr accessors ----------------------------------------------------------

def test_attr_reader(_args, assert)
  parser = Parser::RubyLine.new('attr_reader :name, :age').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:attr_reader))
end

def test_attr_writer(_args, assert)
  parser = Parser::RubyLine.new('attr_writer :name').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:attr_writer))
end

def test_attr_accessor(_args, assert)
  parser = Parser::RubyLine.new('attr_accessor :name, :age').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:attr_accessor))
end

# ---- Case statements ---------------------------------------------------------

def test_case_statement(_args, assert)
  parser = Parser::RubyLine.new('case value').parse
  assert.equal!(parser.stack.map(&:type), [:case])
end

def test_when_clause(_args, assert)
  parser1 = Parser::RubyLine.new('case value').parse
  parser2 = Parser::RubyLine.new('when 1', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:when))
end

def test_case_without_argument(_args, assert)
  parser = Parser::RubyLine.new('case').parse
  assert.equal!(parser.stack.map(&:type), [:case])
end

# ---- Pattern matching --------------------------------------------------------

# TODO: Does mruby have pattern matching? Does DragonRuby?

def test_pattern_matching_case_in(_args, assert)
  parser1 = Parser::RubyLine.new('case value').parse
  parser2 = Parser::RubyLine.new('in { x: Integer }', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:in))
end

# TODO: WTF does this even do?

def test_one_line_pattern_matching(_args, assert)
  parser = Parser::RubyLine.new('[1, 2] => [a, b]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:pattern_match))
end

# ---- Endless method definitions ----------------------------------------------

def test_endless_method_def(_args, assert)
  parser = Parser::RubyLine.new('def foo(x) = x * 2').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:endless_def))
end

# ---- Numbered block parameters -----------------------------------------------

def test_numbered_block_param(_args, assert)
  parser = Parser::RubyLine.new('arr.map { _1 * 2 }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:numbered_param))
end

# ---- Hash rocket syntax ------------------------------------------------------

def test_hash_rocket(_args, assert)
  parser = Parser::RubyLine.new('h = { "key" => "value" }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:hash_rocket))
end

# ---- Method calls without parentheses ----------------------------------------

def test_method_call_no_parens(_args, assert)
  parser = Parser::RubyLine.new('puts "hello"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:method_call))
  assert.false!(tokens.include?(:paren))
end

# ---- Singleton class ---------------------------------------------------------

def test_singleton_class(_args, assert)
  parser = Parser::RubyLine.new('class << self').parse
  assert.equal!(parser.stack.map(&:type), [:singleton_class])
end

# ---- Special constants -------------------------------------------------------

def test_file_constant(_args, assert)
  parser = Parser::RubyLine.new('path = __FILE__').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:special_constant))
end

def test_line_constant(_args, assert)
  parser = Parser::RubyLine.new('line = __LINE__').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:special_constant))
end

def test_encoding_constant(_args, assert)
  parser = Parser::RubyLine.new('enc = __ENCODING__').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:special_constant))
end

# ---- Super, yield, return ----------------------------------------------------

def test_super_keyword(_args, assert)
  parser = Parser::RubyLine.new('super').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:super))
end

def test_super_with_args(_args, assert)
  parser = Parser::RubyLine.new('super(arg1, arg2)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:super))
end

def test_yield_keyword(_args, assert)
  parser = Parser::RubyLine.new('yield').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:yield))
end

def test_yield_with_args(_args, assert)
  parser = Parser::RubyLine.new('yield x, y').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:yield))
end

def test_return_multiple_values(_args, assert)
  parser = Parser::RubyLine.new('return a, b, c').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:return))
end

# ---- Break and next with values ----------------------------------------------

def test_break_with_value(_args, assert)
  parser = Parser::RubyLine.new('break result').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:break))
end

def test_next_with_value(_args, assert)
  parser = Parser::RubyLine.new('next value').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:next))
end

# ---- Undef and alias ---------------------------------------------------------

def test_undef_keyword(_args, assert)
  parser = Parser::RubyLine.new('undef :old_method').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:undef))
end

def test_alias_keyword(_args, assert)
  parser = Parser::RubyLine.new('alias new_name old_name').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:alias))
end

def test_alias_method(_args, assert)
  parser = Parser::RubyLine.new('alias_method :new, :old').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:alias_method))
end

# ---- For loops ---------------------------------------------------------------

def test_for_loop(_args, assert)
  parser = Parser::RubyLine.new('for i in 1..10').parse
  assert.equal!(parser.stack.map(&:type), [:for])
end

# ---- Loop construct ----------------------------------------------------------

def test_loop_construct(_args, assert)
  parser = Parser::RubyLine.new('loop do').parse
  assert.equal!(parser.stack.map(&:type), [:loop])
end

# ---- Begin/rescue/ensure blocks ----------------------------------------------

def test_begin_keyword(_args, assert)
  parser = Parser::RubyLine.new('begin').parse
  assert.equal!(parser.stack.map(&:type), [:begin])
end

def test_rescue_clause(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  parser2 = Parser::RubyLine.new('rescue StandardError => e', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:rescue))
end

def test_ensure_clause(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  parser2 = Parser::RubyLine.new('ensure', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:ensure))
end

def test_retry_keyword(_args, assert)
  parser = Parser::RubyLine.new('retry').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:retry))
end

# ---- Method visibility modifiers ---------------------------------------------

def test_private_keyword(_args, assert)
  parser = Parser::RubyLine.new('private').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:visibility))
end

def test_protected_keyword(_args, assert)
  parser = Parser::RubyLine.new('protected').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:visibility))
end

def test_public_keyword(_args, assert)
  parser = Parser::RubyLine.new('public').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:visibility))
end

# ---- Defined? operator -------------------------------------------------------

def test_defined_operator(_args, assert)
  parser = Parser::RubyLine.new('defined?(variable)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:defined))
end

# ---- Include/extend/prepend --------------------------------------------------

def test_include_keyword(_args, assert)
  parser = Parser::RubyLine.new('include MyModule').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:include))
end

def test_extend_keyword(_args, assert)
  parser = Parser::RubyLine.new('extend MyModule').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:extend))
end

def test_prepend_keyword(_args, assert)
  parser = Parser::RubyLine.new('prepend MyModule').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:prepend))
end

# ---- Flip-flop operator ------------------------------------------------------

# TODO: Do we care?

def test_flip_flop_inclusive(_args, assert)
  parser = Parser::RubyLine.new('if (1..10)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:flip_flop))
end

def test_flip_flop_exclusive(_args, assert)
  parser = Parser::RubyLine.new('if (1...10)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:flip_flop))
end

# ---- Backtick command execution ----------------------------------------------

def test_backtick_command(_args, assert)
  parser = Parser::RubyLine.new('output = `ls -la`').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:command))
end

def test_backtick_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('output = `echo #{var}`').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:command))
  assert.true!(tokens.include?(:interpolation_start))
end
