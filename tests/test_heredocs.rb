require_relative 'test_helpers'

# ---- Basic heredoc tests -----------------------------------------------------

def test_multiline_heredoc_basic(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<EOF').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'EOF')
  assert.equal!(parser1.stack.last.modifier, nil)  # No modifier

  parser2 = Parser::RubyLine.new('This is text', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('More text', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:heredoc])

  parser4 = Parser::RubyLine.new('EOF', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_heredoc_with_dash(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<-DELIMITER').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'DELIMITER')
  assert.equal!(parser1.stack.last.depth, 1)  # Dash modifier

  parser2 = Parser::RubyLine.new('  Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('  DELIMITER', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_with_tilde(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<~END').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'END')
  assert.equal!(parser1.stack.last.modifier, '~')  # Tilde modifier

  parser2 = Parser::RubyLine.new('    Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('    END', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_quoted_delimiter(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<"MARKER"').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'MARKER')

  parser2 = Parser::RubyLine.new('Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('MARKER', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_single_quoted_delimiter(_args, assert)
  parser1 = Parser::RubyLine.new("text = <<'MARKER'").parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'MARKER')

  parser2 = Parser::RubyLine.new('Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('MARKER', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_empty(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<EMPTY').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = Parser::RubyLine.new('EMPTY', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_heredoc_multiple_lines(_args, assert)
  parser1 = Parser::RubyLine.new('msg = <<TEXT').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = Parser::RubyLine.new('Line 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('Line 2', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:heredoc])

  parser4 = Parser::RubyLine.new('Line 3', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:heredoc])

  parser5 = Parser::RubyLine.new('TEXT', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

# ---- Heredoc with code structure tests ---------------------------------------

def test_multiline_heredoc_in_method(_args, assert)
  parser1 = Parser::RubyLine.new('def message').parse
  assert.equal!(parser1.stack.map(&:type), [:def])

  parser2 = Parser::RubyLine.new('  <<MSG', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def, :heredoc])

  parser3 = Parser::RubyLine.new('  Hello', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def, :heredoc])

  parser4 = Parser::RubyLine.new('MSG', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:def])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_heredoc_in_array(_args, assert)
  parser1 = Parser::RubyLine.new('arr = [').parse
  assert.equal!(parser1.stack.map(&:type), [:array])

  parser2 = Parser::RubyLine.new('  <<TEXT,', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:array, :heredoc])

  parser3 = Parser::RubyLine.new('Content', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:array, :heredoc])

  parser4 = Parser::RubyLine.new('TEXT', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:array])

  parser5 = Parser::RubyLine.new(']', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

# ---- Edge cases --------------------------------------------------------------

def test_heredoc_delimiter_not_at_start(_args, assert)
  # Heredoc delimiter must be at start of line (or indented for <<-)
  parser1 = Parser::RubyLine.new('text = <<END').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = Parser::RubyLine.new('  END', parser1.stack).parse
  # Should NOT close because regular << requires exact match at start
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('END', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_heredoc_dash_allows_indent(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<-END').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = Parser::RubyLine.new('  Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('  END', parser2.stack).parse
  # Should close because <<- allows indented delimiter
  assert.true!(parser3.stack.empty?)
end

def test_heredoc_content_contains_delimiter_substring(_args, assert)
  parser1 = Parser::RubyLine.new('text = <<DELIM').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = Parser::RubyLine.new('DELIMIT', parser1.stack).parse
  # Should NOT close - only exact match closes
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = Parser::RubyLine.new('DELIM', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

# ---- Full parser -------------------------------------------------------------

def test_parser_heredoc_with_tilde(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    args.state.message = <<~TEXT
      Welcome to DragonRuby!
    TEXT
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  # After heredoc_start, there's a newline which is parsed as whitespace
  expected = [:identifier, :operator, :identifier, :operator, :identifier, :whitespace, :operator, :whitespace, :heredoc_start, :whitespace]
  assert.equal!(parser.lines.first.tokens.map(&:type), expected)
end

def test_parser_heredoc_with_tilde_and_capitalize(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    args.state.message = <<~TEXT.capitalize
      Welcome to DragonRuby!
    TEXT
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  # After heredoc_start, .capitalize is parsed as operator + identifier, then whitespace (newline)
  expected = [:identifier, :operator, :identifier, :operator, :identifier, :whitespace, :operator, :whitespace, :heredoc_start, :operator, :identifier, :whitespace]
  assert.equal!(parser.lines.first.tokens.map(&:type), expected)
end

def test_parser_heredoc_with_tilde_and_a_comment(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    args.state.message = <<~TEXT # comment
      Welcome to DragonRuby!
    TEXT
  RUBYCODE

  parser = Parser::Ruby.new(sample_code)
  # After heredoc_start, the comment is parsed as whitespace + comment + whitespace (newline after comment)
  expected = [:identifier, :operator, :identifier, :operator, :identifier, :whitespace, :operator, :whitespace, :heredoc_start, :whitespace, :comment, :whitespace]
  assert.equal!(parser.lines.first.tokens.map(&:type), expected)
end

# ---- Heredoc interpolation tests ---------------------------------------------

def test_heredoc_with_interpolation(_args, assert)
  code = <<~'CODE'
    msg = <<TEXT
    Hello #{name}!
    TEXT
  CODE

  parser = Parser::Ruby.new(code)
  assert.equal!(parser.lines[0].stack.map(&:type), [:heredoc])

  line2 = parser.lines[1]
  # Should have heredoc_line, interpolation_start, identifier, interpolation_end, heredoc_line
  types = line2.tokens.map { |t| t[:type] }
  assert.true!(types.include?(:heredoc_line))
  assert.true!(types.include?(:interpolation_start))
  assert.true!(types.include?(:interpolation_end))

  line3 = parser.lines[2]
  assert.true!(line3.stack.empty?)
end

def test_heredoc_double_quoted_with_interpolation(_args, assert)
  code = <<~'CODE'
    msg = <<"TEXT"
    Hello #{name}!
    TEXT
  CODE

  parser = Parser::Ruby.new(code)
  line1 = parser.lines[0]
  assert.equal!(line1.stack.map(&:type), [:heredoc])

  line2 = parser.lines[1]
  types = line2.tokens.map { |t| t[:type] }
  assert.true!(types.include?(:interpolation_start))

  line3 = parser.lines[2]
  assert.true!(line3.stack.empty?)
end

def test_heredoc_single_quoted_no_interpolation(_args, assert)
  code = <<~'CODE'
    msg = <<'TEXT'
    Hello #{name}!
    TEXT
  CODE

  parser = Parser::Ruby.new(code)
  line1 = parser.lines[0]
  assert.equal!(line1.stack.map(&:type), [:heredoc])

  line2 = parser.lines[1]
  # Should treat #{name} as literal text, not interpolation
  types = line2.tokens.map { |t| t[:type] }
  assert.false!(types.include?(:interpolation_start))
  assert.equal!(types, [:heredoc_line])

  line3 = parser.lines[2]
  assert.true!(line3.stack.empty?)
end
