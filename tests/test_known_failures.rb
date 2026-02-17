require_relative 'test_helpers'

# ---- Known parsing failures - TODO items for future work --------------------
# Tests here document code patterns that don't currently parse correctly
# or represent features that need real implementation work.

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

# ---- Ternary operator --------------------------------------------------------

def test_ternary_operator(_args, assert)
  parser = Parser::RubyLine.new('result = x > 5 ? "big" : "small"').parse
  tokens = parser.tokens.map { |t| t[:type] }
  # Currently both ? and : parse as :operator, which is fine for highlighting
  # but ideally we'd have :ternary_question and :ternary_colon
  assert.true!(tokens.include?(:ternary_question))
  assert.true!(tokens.include?(:ternary_colon))
end

# ---- Heredoc in interpolation ------------------------------------------------

def test_heredoc_in_string_interpolation(_args, assert)
  # This is valid Ruby but very unusual
  parser = Parser::RubyLine.new('"start #{<<TEXT} end"').parse
  assert.equal!(parser.stack.map(&:type), [:string_double, :heredoc])
end

# ---- Pattern matching --------------------------------------------------------

def test_one_line_pattern_matching(_args, assert)
  parser = Parser::RubyLine.new('[1, 2] => [a, b]').parse
  tokens = parser.tokens.map { |t| t[:type] }
  assert.true!(tokens.include?(:pattern_match))
end

# ---- Loop construct ----------------------------------------------------------

def test_loop_construct(_args, assert)
  parser = Parser::RubyLine.new('loop do').parse
  # `loop` is an identifier, `do` pushes :do_block
  # Ideally we'd recognize loop...do as a construct
  assert.equal!(parser.stack.map(&:type), [:loop])
end

