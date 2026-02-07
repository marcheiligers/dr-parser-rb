require_relative 'test_helpers'

# ---- Tests moved from known_failures - now pass with correct assertions ------

# ---- Percent literal variations ----------------------------------------------

def test_kf_percent_w_with_square_brackets(_args, assert)
  parser = Parser::RubyLine.new('arr = %w[one two three]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_kf_percent_w_with_curly_braces(_args, assert)
  parser = Parser::RubyLine.new('arr = %w{one two three}').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_kf_percent_w_with_pipes(_args, assert)
  parser = Parser::RubyLine.new('arr = %w|one two three|').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_kf_percent_q_lowercase(_args, assert)
  parser = Parser::RubyLine.new('str = %q(hello world)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))
end

def test_kf_percent_Q_uppercase(_args, assert)
  # %Q without interpolation parses as :string
  parser = Parser::RubyLine.new('str = %Q(hello world)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))
end

def test_kf_percent_r_regex(_args, assert)
  parser = Parser::RubyLine.new('pattern = %r{\\d+}').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))  # regex-like percent literals highlight as string
end

def test_kf_percent_i_symbol_array(_args, assert)
  parser = Parser::RubyLine.new('syms = %i[foo bar baz]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_kf_percent_I_symbol_array_interpolated(_args, assert)
  parser = Parser::RubyLine.new('syms = %I[foo bar baz]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
end

def test_kf_percent_s_symbol(_args, assert)
  parser = Parser::RubyLine.new('sym = %s[foo bar]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol))
end

def test_kf_percent_x_command(_args, assert)
  parser = Parser::RubyLine.new('output = %x(ls -la)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:backtick))
end

# ---- Proc.new ----------------------------------------------------------------

def test_kf_proc_new(_args, assert)
  parser1 = Parser::RubyLine.new('p = Proc.new do').parse
  assert.equal!(parser1.stack.map(&:type), [:do_block])
end

# ---- String escape sequences -------------------------------------------------

def test_kf_string_with_newline_escape(_args, assert)
  parser = Parser::RubyLine.new('"hello\\nworld"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens, [:string])
end

def test_kf_string_with_tab_escape(_args, assert)
  parser = Parser::RubyLine.new('"hello\\tworld"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens, [:string])
end

# ---- String continuation -----------------------------------------------------

def test_kf_string_continuation(_args, assert)
  parser1 = Parser::RubyLine.new('"hello \\').parse
  parser2 = Parser::RubyLine.new('world"', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [])
end

# ---- Keyword arguments -------------------------------------------------------

def test_kf_keyword_arguments_in_call(_args, assert)
  parser = Parser::RubyLine.new('foo(x: 10, y: 20)').parse
  assert.equal!(parser.stack.map(&:type), [])
end

# ---- Variable types ----------------------------------------------------------

def test_kf_global_variable(_args, assert)
  parser = Parser::RubyLine.new('$global = 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:global))
end

def test_kf_instance_variable(_args, assert)
  parser = Parser::RubyLine.new('@instance = 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:ivar))
end

def test_kf_class_variable(_args, assert)
  parser = Parser::RubyLine.new('@@class_var = 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:cvar))
end

# ---- Operators (all parse as :operator) --------------------------------------

def test_kf_spaceship_operator(_args, assert)
  parser = Parser::RubyLine.new('result = a <=> b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_power_operator(_args, assert)
  parser = Parser::RubyLine.new('result = 2 ** 8').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_modulo_assign(_args, assert)
  parser = Parser::RubyLine.new('x %= 5').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_inclusive_range(_args, assert)
  parser = Parser::RubyLine.new('range = 1..10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_exclusive_range(_args, assert)
  parser = Parser::RubyLine.new('range = 1...10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_safe_navigation(_args, assert)
  parser = Parser::RubyLine.new('result = obj&.method').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_left_shift(_args, assert)
  parser = Parser::RubyLine.new('result = a << b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_right_shift(_args, assert)
  parser = Parser::RubyLine.new('result = a >> b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_bitwise_and(_args, assert)
  parser = Parser::RubyLine.new('result = a & b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_bitwise_or(_args, assert)
  parser = Parser::RubyLine.new('result = a | b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_bitwise_xor(_args, assert)
  parser = Parser::RubyLine.new('result = a ^ b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_bitwise_not(_args, assert)
  parser = Parser::RubyLine.new('result = ~a').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))
end

def test_kf_splat_in_method_call(_args, assert)
  parser = Parser::RubyLine.new('foo(*args)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # * is an operator
end

def test_kf_double_splat_in_hash(_args, assert)
  parser = Parser::RubyLine.new('h = { a: 1, **other }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # ** is an operator
end

def test_kf_hash_rocket(_args, assert)
  parser = Parser::RubyLine.new('h = { "key" => "value" }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # => is an operator
end

# ---- Keywords (all parse as :keyword) ----------------------------------------

def test_kf_and_operator(_args, assert)
  parser = Parser::RubyLine.new('result = x and y').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # and is a keyword
end

def test_kf_or_operator(_args, assert)
  parser = Parser::RubyLine.new('result = x or y').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # or is a keyword
end

def test_kf_not_operator(_args, assert)
  parser = Parser::RubyLine.new('result = not condition').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # not is a keyword
end

def test_kf_modifier_if(_args, assert)
  parser = Parser::RubyLine.new('puts "hello" if condition').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # if is a keyword
  # Verify it doesn't push a frame (modifier form)
  assert.true!(parser.stack.empty?)
end

def test_kf_modifier_unless(_args, assert)
  parser = Parser::RubyLine.new('puts "hello" unless condition').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
  assert.true!(parser.stack.empty?)
end

def test_kf_modifier_while(_args, assert)
  parser = Parser::RubyLine.new('x += 1 while x < 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
  assert.true!(parser.stack.empty?)
end

def test_kf_modifier_until(_args, assert)
  parser = Parser::RubyLine.new('x += 1 until x > 10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
  assert.true!(parser.stack.empty?)
end

def test_kf_super_keyword(_args, assert)
  parser = Parser::RubyLine.new('super').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_super_with_args(_args, assert)
  parser = Parser::RubyLine.new('super(arg1, arg2)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_yield_keyword(_args, assert)
  parser = Parser::RubyLine.new('yield').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_yield_with_args(_args, assert)
  parser = Parser::RubyLine.new('yield x, y').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_return_multiple_values(_args, assert)
  parser = Parser::RubyLine.new('return a, b, c').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_break_with_value(_args, assert)
  parser = Parser::RubyLine.new('break result').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_next_with_value(_args, assert)
  parser = Parser::RubyLine.new('next value').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_undef_keyword(_args, assert)
  parser = Parser::RubyLine.new('undef :old_method').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_alias_keyword(_args, assert)
  parser = Parser::RubyLine.new('alias new_name old_name').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

def test_kf_defined_operator(_args, assert)
  parser = Parser::RubyLine.new('defined?(variable)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # defined? is a keyword
end

def test_kf_rescue_modifier(_args, assert)
  parser = Parser::RubyLine.new('value = dangerous_call rescue default').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # rescue is a keyword
end

def test_kf_retry_keyword(_args, assert)
  parser = Parser::RubyLine.new('retry').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))
end

# ---- Case/when/rescue/ensure (already work) ----------------------------------

def test_kf_case_statement(_args, assert)
  parser = Parser::RubyLine.new('case value').parse
  assert.equal!(parser.stack.map(&:type), [:case])
end

def test_kf_when_clause(_args, assert)
  parser1 = Parser::RubyLine.new('case value').parse
  parser2 = Parser::RubyLine.new('when 1', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # when is a keyword
end

def test_kf_case_without_argument(_args, assert)
  parser = Parser::RubyLine.new('case').parse
  assert.equal!(parser.stack.map(&:type), [:case])
end

def test_kf_rescue_clause(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  parser2 = Parser::RubyLine.new('rescue StandardError => e', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # rescue is a keyword
end

def test_kf_ensure_clause(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  parser2 = Parser::RubyLine.new('ensure', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # ensure is a keyword
end

def test_kf_begin_keyword(_args, assert)
  parser = Parser::RubyLine.new('begin').parse
  assert.equal!(parser.stack.map(&:type), [:begin])
end

def test_kf_for_loop(_args, assert)
  parser = Parser::RubyLine.new('for i in 1..10').parse
  assert.equal!(parser.stack.map(&:type), [:for])
end

def test_kf_pattern_matching_case_in(_args, assert)
  parser1 = Parser::RubyLine.new('case value').parse
  parser2 = Parser::RubyLine.new('in { x: Integer }', parser1.stack).parse
  tokens = parser2.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))  # in is a keyword
end

# ---- Identifiers (methods that aren't keywords) ------------------------------

def test_kf_private_keyword(_args, assert)
  parser = Parser::RubyLine.new('private').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))  # private is an identifier/method
end

def test_kf_protected_keyword(_args, assert)
  parser = Parser::RubyLine.new('protected').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_public_keyword(_args, assert)
  parser = Parser::RubyLine.new('public').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_include_keyword(_args, assert)
  parser = Parser::RubyLine.new('include MyModule').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_extend_keyword(_args, assert)
  parser = Parser::RubyLine.new('extend MyModule').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_prepend_keyword(_args, assert)
  parser = Parser::RubyLine.new('prepend MyModule').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_attr_reader(_args, assert)
  parser = Parser::RubyLine.new('attr_reader :name, :age').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_attr_writer(_args, assert)
  parser = Parser::RubyLine.new('attr_writer :name').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_attr_accessor(_args, assert)
  parser = Parser::RubyLine.new('attr_accessor :name, :age').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_alias_method(_args, assert)
  parser = Parser::RubyLine.new('alias_method :new, :old').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
end

def test_kf_method_call_no_parens(_args, assert)
  parser = Parser::RubyLine.new('puts "hello"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))  # puts is an identifier
  assert.false!(tokens.include?(:paren))
end

# ---- Numeric literals --------------------------------------------------------

def test_kf_number_with_underscores(_args, assert)
  parser = Parser::RubyLine.new('big = 1_000_000').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last, :number)
end

def test_kf_float_with_exponent(_args, assert)
  parser = Parser::RubyLine.new('sci = 1.5e10').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last, :number)
end

def test_kf_binary_literal(_args, assert)
  parser = Parser::RubyLine.new('num = 0b1010').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last, :number)
end

def test_kf_octal_literal(_args, assert)
  parser = Parser::RubyLine.new('num = 0o755').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last, :number)
end

def test_kf_hex_literal(_args, assert)
  parser = Parser::RubyLine.new('num = 0xFF').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.equal!(tokens.last, :number)
end

# ---- Character literal -------------------------------------------------------

def test_kf_character_literal(_args, assert)
  parser = Parser::RubyLine.new('char = ?a').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))  # character literals are strings
end

# ---- Symbol literals ---------------------------------------------------------

def test_kf_quoted_symbol(_args, assert)
  parser = Parser::RubyLine.new('sym = :"symbol with spaces"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol))
end

def test_kf_symbol_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('sym = :"prefix_#{name}"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:symbol))
  assert.true!(tokens.include?(:interpolation_start))
end

# ---- Symbol to proc ---------------------------------------------------------

def test_kf_symbol_to_proc(_args, assert)
  parser = Parser::RubyLine.new('arr.map(&:to_s)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # & is an operator
  assert.true!(tokens.include?(:symbol))    # :to_s is a symbol
end

# ---- Backtick command execution ----------------------------------------------

def test_kf_backtick_command(_args, assert)
  parser = Parser::RubyLine.new('output = `ls -la`').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:backtick))
end

def test_kf_backtick_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('output = `echo #{var}`').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:backtick))
  assert.true!(tokens.include?(:interpolation_start))
end

# ---- Block parameters, numbered params, etc. ---------------------------------

def test_kf_block_with_multiple_params(_args, assert)
  parser = Parser::RubyLine.new('hash.each do |key, value|').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))     # | is an operator
  assert.true!(tokens.include?(:identifier))   # key, value are identifiers
end

def test_kf_numbered_block_param(_args, assert)
  parser = Parser::RubyLine.new('arr.map { _1 * 2 }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))  # _1 is an identifier
end

# ---- Def edge cases ----------------------------------------------------------

def test_kf_def_with_default_params(_args, assert)
  parser = Parser::RubyLine.new('def foo(x, y = 10, z = 20)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))     # def
  assert.true!(tokens.include?(:identifier))  # foo, x, y, z
  assert.true!(tokens.include?(:number))      # 10, 20
end

def test_kf_def_with_splat_param(_args, assert)
  parser = Parser::RubyLine.new('def foo(*args)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))    # *
  assert.true!(tokens.include?(:identifier))  # args
end

def test_kf_keyword_arguments_in_def(_args, assert)
  parser = Parser::RubyLine.new('def foo(x:, y: 5)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:keyword))     # def
  assert.true!(tokens.include?(:identifier))  # foo, x, y
end

# ---- Parallel assignment / destructuring -------------------------------------

def test_kf_parallel_assignment(_args, assert)
  parser = Parser::RubyLine.new('a, b = 1, 2').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
  assert.true!(tokens.include?(:number))
end

def test_kf_array_destructuring(_args, assert)
  parser = Parser::RubyLine.new('a, b = [1, 2]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))
  assert.true!(tokens.include?(:number))
end

# ---- Special constants -------------------------------------------------------

def test_kf_file_constant(_args, assert)
  parser = Parser::RubyLine.new('path = __FILE__').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))  # __FILE__ parsed as identifier
end

def test_kf_line_constant(_args, assert)
  parser = Parser::RubyLine.new('line = __LINE__').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))  # __LINE__ parsed as identifier
end

def test_kf_encoding_constant(_args, assert)
  parser = Parser::RubyLine.new('enc = __ENCODING__').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:identifier))  # __ENCODING__ parsed as identifier
end

# ---- Flip-flop (uses range operators) ----------------------------------------

def test_kf_flip_flop_inclusive(_args, assert)
  parser = Parser::RubyLine.new('if (1..10)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # .. is an operator
end

def test_kf_flip_flop_exclusive(_args, assert)
  parser = Parser::RubyLine.new('if (1...10)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # ... is an operator
end

# ---- Singleton class ---------------------------------------------------------

def test_kf_singleton_class(_args, assert)
  parser = Parser::RubyLine.new('class << self').parse
  assert.equal!(parser.stack.map(&:type), [:class])
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:operator))  # the << operator
end

# ---- BEGIN/END blocks (uppercase) -------------------------------------------

def test_kf_begin_block_keyword(_args, assert)
  parser = Parser::RubyLine.new('BEGIN { puts "starting" }').parse
  tokens = parser.tokens
  assert.equal!(tokens[0][:type], :keyword)
  assert.equal!(tokens[0][:value], 'BEGIN')
end

def test_kf_end_block_keyword(_args, assert)
  parser = Parser::RubyLine.new('END { puts "ending" }').parse
  tokens = parser.tokens
  assert.equal!(tokens[0][:type], :keyword)
  assert.equal!(tokens[0][:value], 'END')
end

# ---- Endless method def -----------------------------------------------------

def test_kf_endless_method_def(_args, assert)
  parser = Parser::RubyLine.new('def foo(x) = x * 2').parse
  assert.true!(parser.stack.empty?)
end

def test_kf_endless_method_no_params(_args, assert)
  parser = Parser::RubyLine.new('def answer = 42').parse
  assert.true!(parser.stack.empty?)
end

def test_kf_endless_method_with_default_params(_args, assert)
  parser = Parser::RubyLine.new('def foo(x, y = 10) = x + y').parse
  assert.true!(parser.stack.empty?)
end

# ---- %Q with interpolation --------------------------------------------------

def test_kf_percent_Q_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('str = %Q(hello #{name})').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:string))
  assert.true!(tokens.include?(:interpolation_start))
end

def test_kf_percent_W_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('arr = %W[one #{two} three]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:array_literal))
  assert.true!(tokens.include?(:interpolation_start))
end

def test_kf_percent_x_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('cmd = %x(echo #{msg})').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:backtick))
  assert.true!(tokens.include?(:interpolation_start))
end

def test_kf_percent_Q_with_nested_delimiters(_args, assert)
  parser = Parser::RubyLine.new('%Q((hello))').parse
  tokens = parser.tokens
  assert.equal!(tokens[0][:type], :string)
  assert.equal!(tokens[0][:value], '%Q((hello))')
end

def test_kf_percent_Q_multiline(_args, assert)
  parser1 = Parser::RubyLine.new('%Q(hello').parse
  assert.equal!(parser1.stack.map(&:type), [:percent_interp])

  parser2 = Parser::RubyLine.new('world)', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

# ---- Regex literals ----------------------------------------------------------

def test_kf_regex_literal(_args, assert)
  parser = Parser::RubyLine.new('pattern = /\\d+/').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

def test_kf_regex_with_modifiers(_args, assert)
  parser = Parser::RubyLine.new('pattern = /hello/i').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

def test_kf_regex_with_interpolation(_args, assert)
  parser = Parser::RubyLine.new('pattern = /#{prefix}\\d+/').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
  assert.true!(tokens.include?(:interpolation_start))
end

def test_kf_division_not_regex(_args, assert)
  parser = Parser::RubyLine.new('result = a / b').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.false!(tokens.include?(:regex))
end

def test_kf_division_after_number(_args, assert)
  parser = Parser::RubyLine.new('result = 10 / 5').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.false!(tokens.include?(:regex))
end

def test_kf_division_after_paren(_args, assert)
  parser = Parser::RubyLine.new('result = (a + b) / c').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.false!(tokens.include?(:regex))
end

def test_kf_regex_after_comma(_args, assert)
  parser = Parser::RubyLine.new('foo(a, /pattern/)').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

def test_kf_regex_empty(_args, assert)
  parser = Parser::RubyLine.new('pattern = //').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:regex))
end

# ---- Lambda tracking ---------------------------------------------------------

def test_kf_stabby_lambda(_args, assert)
  parser = Parser::RubyLine.new('f = ->(x) { x * 2 }').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:lambda))
end

def test_kf_lambda_do_block(_args, assert)
  parser1 = Parser::RubyLine.new('f = lambda do |x|').parse
  assert.equal!(parser1.stack.map(&:type), [:lambda])
end

def test_kf_lambda_do_block_end(_args, assert)
  parser1 = Parser::RubyLine.new('f = lambda do |x|').parse
  parser2 = Parser::RubyLine.new('  x * 2', parser1.stack).parse
  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end
