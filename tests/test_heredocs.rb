require_relative 'test_helpers'

# ---- Basic heredoc tests -----------------------------------------------------

def test_multiline_heredoc_basic(_args, assert)
  parser1 = RubyLineParser.new('text = <<EOF').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'EOF')
  assert.equal!(parser1.stack.last.depth, 0)  # No modifier

  parser2 = RubyLineParser.new('This is text', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('More text', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:heredoc])

  parser4 = RubyLineParser.new('EOF', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_heredoc_with_dash(_args, assert)
  parser1 = RubyLineParser.new('text = <<-DELIMITER').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'DELIMITER')
  assert.equal!(parser1.stack.last.depth, 1)  # Dash modifier

  parser2 = RubyLineParser.new('  Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('  DELIMITER', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_with_tilde(_args, assert)
  parser1 = RubyLineParser.new('text = <<~END').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'END')
  assert.equal!(parser1.stack.last.depth, 2)  # Tilde modifier

  parser2 = RubyLineParser.new('    Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('    END', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_quoted_delimiter(_args, assert)
  parser1 = RubyLineParser.new('text = <<"MARKER"').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'MARKER')

  parser2 = RubyLineParser.new('Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('MARKER', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_single_quoted_delimiter(_args, assert)
  parser1 = RubyLineParser.new("text = <<'MARKER'").parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])
  assert.equal!(parser1.stack.last.name, 'MARKER')

  parser2 = RubyLineParser.new('Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('MARKER', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_heredoc_empty(_args, assert)
  parser1 = RubyLineParser.new('text = <<EMPTY').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = RubyLineParser.new('EMPTY', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_heredoc_multiple_lines(_args, assert)
  parser1 = RubyLineParser.new('msg = <<TEXT').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = RubyLineParser.new('Line 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('Line 2', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:heredoc])

  parser4 = RubyLineParser.new('Line 3', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:heredoc])

  parser5 = RubyLineParser.new('TEXT', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

# ---- Heredoc with code structure tests ---------------------------------------

def test_multiline_heredoc_in_method(_args, assert)
  parser1 = RubyLineParser.new('def message').parse
  assert.equal!(parser1.stack.map(&:type), [:def])

  parser2 = RubyLineParser.new('  <<MSG', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def, :heredoc])

  parser3 = RubyLineParser.new('  Hello', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def, :heredoc])

  parser4 = RubyLineParser.new('MSG', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:def])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_heredoc_in_array(_args, assert)
  parser1 = RubyLineParser.new('arr = [').parse
  assert.equal!(parser1.stack.map(&:type), [:array])

  parser2 = RubyLineParser.new('  <<TEXT,', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:array, :heredoc])

  parser3 = RubyLineParser.new('Content', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:array, :heredoc])

  parser4 = RubyLineParser.new('TEXT', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:array])

  parser5 = RubyLineParser.new(']', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

# ---- Edge cases --------------------------------------------------------------

def test_heredoc_delimiter_not_at_start(_args, assert)
  # Heredoc delimiter must be at start of line (or indented for <<-)
  parser1 = RubyLineParser.new('text = <<END').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = RubyLineParser.new('  END', parser1.stack).parse
  # Should NOT close because regular << requires exact match at start
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('END', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_heredoc_dash_allows_indent(_args, assert)
  parser1 = RubyLineParser.new('text = <<-END').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = RubyLineParser.new('  Content', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('  END', parser2.stack).parse
  # Should close because <<- allows indented delimiter
  assert.true!(parser3.stack.empty?)
end

def test_heredoc_content_contains_delimiter_substring(_args, assert)
  parser1 = RubyLineParser.new('text = <<DELIM').parse
  assert.equal!(parser1.stack.map(&:type), [:heredoc])

  parser2 = RubyLineParser.new('DELIMIT', parser1.stack).parse
  # Should NOT close - only exact match closes
  assert.equal!(parser2.stack.map(&:type), [:heredoc])

  parser3 = RubyLineParser.new('DELIM', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

# ---- Full parser -------------------------------------------------------------

def test_parser_heredoc_with_tilde(_args, assert)
  sample_code = <<~RUBYCODE.freeze
    args.state.message = <<~TEXT
      Welcome to DragonRuby!
    TEXT
  RUBYCODE

  parser = RubyParser.new(sample_code)
  puts "--> #{parser.lines.first.tokens.map(&:type)}"
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

  parser = RubyParser.new(sample_code)
  puts "--> #{parser.lines.first.tokens.map(&:type)}"
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

  parser = RubyParser.new(sample_code)
  puts "--> #{parser.lines.first.tokens.map(&:type)}"
  # After heredoc_start, the comment is parsed as whitespace + comment + whitespace (newline after comment)
  expected = [:identifier, :operator, :identifier, :operator, :identifier, :whitespace, :operator, :whitespace, :heredoc_start, :whitespace, :comment, :whitespace]
  assert.equal!(parser.lines.first.tokens.map(&:type), expected)
end
