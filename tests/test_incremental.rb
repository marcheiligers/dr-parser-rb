require_relative 'test_helpers'

# --- ParsedLine backward compatibility ---

def test_incremental_parsed_line_has_tokens(_args, assert)
  parser = Parser::Ruby.new("x = 1")
  line = parser.lines[0]
  assert.true! line.tokens.is_a?(Array), "ParsedLine should have tokens array"
  assert.true! line.tokens.length > 0, "ParsedLine should have tokens"
end

def test_incremental_parsed_line_stack_alias(_args, assert)
  parser = Parser::Ruby.new("x = 1")
  line = parser.lines[0]
  assert.equal! line.stack, line.output_stack, "stack should alias output_stack"
end

def test_incremental_parsed_line_stores_text(_args, assert)
  parser = Parser::Ruby.new("x = 1")
  assert.equal! parser.lines[0].text, "x = 1"
end

def test_incremental_parsed_line_stores_stacks(_args, assert)
  code = "def foo\n  1\nend\n"
  parser = Parser::Ruby.new(code)
  assert.equal! parser.lines[0].input_stack.length, 0, "first line input stack empty"
  assert.equal! parser.lines[0].output_stack.map(&:type), [:def], "first line output has :def"
  assert.equal! parser.lines[1].input_stack.map(&:type), [:def], "second line input has :def"
end

# --- line_count ---

def test_incremental_line_count(_args, assert)
  parser = Parser::Ruby.new("a\nb\nc\n")
  assert.equal! parser.line_count, 3
end

def test_incremental_line_count_empty(_args, assert)
  parser = Parser::Ruby.new("")
  assert.equal! parser.line_count, 1
end

# --- dirty? and dirty_from ---

def test_incremental_not_dirty_after_init(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\n")
  assert.false! parser.dirty?, "should not be dirty after initial parse"
  assert.equal! parser.dirty_from, nil
end

# --- replace_lines: modify a single line (no stack change) ---

def test_incremental_replace_single_line_no_stack_change(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\nz = 3\n")
  parser.replace_lines(1, 1, ["y = 99\n"])
  assert.false! parser.dirty?, "should not be dirty when stack unchanged"
  assert.equal! parser.line_count, 3
  assert.equal! parser.lines[1].text, "y = 99\n"
  assert.equal! parser.lines[1].tokens.find { |t| t[:type] == :number }[:value], '99'
end

# --- replace_lines: modify a line with stack change ---

def test_incremental_replace_line_with_stack_change(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\nz = 3\n")
  # Replace middle line with an unclosed string - changes output stack
  parser.replace_lines(1, 1, ["y = \"\n"])
  assert.true! parser.dirty?, "should be dirty when stack changed"
  assert.equal! parser.dirty_from, 2, "dirty_from should point to first line after edit"
end

# --- replace_lines: insert lines ---

def test_incremental_insert_lines(_args, assert)
  parser = Parser::Ruby.new("a\nc\n")
  parser.replace_lines(1, 0, ["b\n"])
  assert.equal! parser.line_count, 3
  assert.equal! parser.lines[0].text, "a\n"
  assert.equal! parser.lines[1].text, "b\n"
  assert.equal! parser.lines[2].text, "c\n"
end

# --- replace_lines: delete lines ---

def test_incremental_delete_lines(_args, assert)
  parser = Parser::Ruby.new("a\nb\nc\n")
  parser.replace_lines(1, 1, [])
  assert.equal! parser.line_count, 2
  assert.equal! parser.lines[0].text, "a\n"
  assert.equal! parser.lines[1].text, "c\n"
end

# --- replace_lines: edit first line ---

def test_incremental_edit_first_line(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\n")
  parser.replace_lines(0, 1, ["x = 99\n"])
  assert.equal! parser.lines[0].text, "x = 99\n"
  assert.false! parser.dirty?, "editing first line with no stack change should not dirty"
end

# --- replace_lines: edit last line ---

def test_incremental_edit_last_line(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\n")
  parser.replace_lines(1, 1, ["y = 99\n"])
  assert.equal! parser.lines[1].text, "y = 99\n"
  assert.false! parser.dirty?, "editing last line should not dirty (no lines after)"
end

# --- replace_lines: delete all lines and insert new ---

def test_incremental_replace_all_lines(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\n")
  parser.replace_lines(0, 2, ["a = 3\n"])
  assert.equal! parser.line_count, 1
  assert.equal! parser.lines[0].text, "a = 3\n"
end

# --- replace_lines: multi-line insert ---

def test_incremental_multi_line_insert(_args, assert)
  parser = Parser::Ruby.new("a\nd\n")
  parser.replace_lines(1, 0, ["b\n", "c\n"])
  assert.equal! parser.line_count, 4
  assert.equal! parser.lines[0].text, "a\n"
  assert.equal! parser.lines[1].text, "b\n"
  assert.equal! parser.lines[2].text, "c\n"
  assert.equal! parser.lines[3].text, "d\n"
end

# --- reparse_next_line: convergence ---

def test_incremental_reparse_converges(_args, assert)
  # Open a string on line 1, making line 2 dirty.
  # Then close it - reparse should converge.
  code = "x = 1\ny = 2\nz = 3\n"
  parser = Parser::Ruby.new(code)

  # Open a string
  parser.replace_lines(0, 1, ["x = \"\n"])
  assert.true! parser.dirty?

  # Close the string - reparse line 1 with string context
  # But actually let's test convergence by fixing the line
  parser.replace_lines(0, 1, ["x = 1\n"])
  # Output stack of line 0 is now [] again, same as line 1's input_stack
  assert.false! parser.dirty?, "should converge when stack matches"
end

# --- reparse_next_line: propagation ---

def test_incremental_reparse_propagates(_args, assert)
  code = "x = 1\ny = 2\nz = 3\n"
  parser = Parser::Ruby.new(code)

  # Open a string on first line - dirties line 1
  parser.replace_lines(0, 1, ["x = \"\n"])
  assert.true! parser.dirty?
  assert.equal! parser.dirty_from, 1

  # Reparse line 1 - it will be reparsed as string content
  # Its output stack will now have :string_double, which differs from old output
  # So line 2 becomes dirty
  more = parser.reparse_next_line
  assert.true! more, "should have more dirty lines"
  assert.equal! parser.dirty_from, 2

  # Reparse line 2 - last line, dirty_from goes to nil
  more = parser.reparse_next_line
  assert.false! more, "no more dirty lines after last line"
  assert.false! parser.dirty?
end

# --- reparse_next_line: convergence stop ---

def test_incremental_reparse_convergence_stops_early(_args, assert)
  # Lines: def foo / x = 1 / end
  code = "def foo\n  x = 1\nend\n"
  parser = Parser::Ruby.new(code)

  # Change the body line - no stack change (still just inside :def)
  parser.replace_lines(1, 1, ["  x = 99\n"])
  assert.false! parser.dirty?, "modifying body shouldn't change stack"
end

# --- reparse! synchronous ---

def test_incremental_reparse_bang(_args, assert)
  code = "x = 1\ny = 2\nz = 3\n"
  parser = Parser::Ruby.new(code)

  # Open a string
  parser.replace_lines(0, 1, ["x = \"\n"])
  assert.true! parser.dirty?

  # Force full reparse
  parser.reparse!
  assert.false! parser.dirty?, "should not be dirty after reparse!"

  # All lines should now be in string context
  assert.equal! parser.lines[1].input_stack.map(&:type), [:string_double]
  assert.equal! parser.lines[2].input_stack.map(&:type), [:string_double]
end

# --- mark_dirty! ---

def test_incremental_mark_dirty(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\nz = 3\n")
  assert.false! parser.dirty?

  parser.mark_dirty!(1)
  assert.true! parser.dirty?
  assert.equal! parser.dirty_from, 1
end

def test_incremental_mark_dirty_takes_minimum(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\nz = 3\n")
  parser.mark_dirty!(2)
  parser.mark_dirty!(1)
  assert.equal! parser.dirty_from, 1, "should keep minimum dirty_from"
end

def test_incremental_mark_dirty_clamps_to_zero(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\n")
  parser.mark_dirty!(-5)
  assert.equal! parser.dirty_from, 0
end

def test_incremental_mark_dirty_default_from_zero(_args, assert)
  parser = Parser::Ruby.new("x = 1\ny = 2\n")
  parser.mark_dirty!
  assert.equal! parser.dirty_from, 0
end

# --- reparse! after mark_dirty! ---

def test_incremental_reparse_after_mark_dirty(_args, assert)
  code = "def foo\n  x = 1\nend\n"
  parser = Parser::Ruby.new(code)

  # Stacks are correct, but force a reparse
  parser.mark_dirty!(0)
  parser.reparse!

  # Should converge immediately since nothing changed
  assert.false! parser.dirty?
  # Tokens should be identical (includes trailing newline whitespace)
  assert.equal! parser.lines[0].tokens.map { |t| t[:type] }, [:keyword, :whitespace, :identifier, :whitespace]
end

# --- Stack isolation (deep copy) ---

def test_incremental_stacks_are_deep_copies(_args, assert)
  code = "def foo\n  x = 1\nend\n"
  parser = Parser::Ruby.new(code)

  # Mutating stored stack should not affect other lines
  parser.lines[0].output_stack[0].depth = 999
  assert.equal! parser.lines[1].input_stack[0].depth, 0,
    "input_stack should be an independent deep copy"
end

# --- Opening and closing multi-line constructs ---

def test_incremental_open_then_close_string(_args, assert)
  # Start with normal code
  parser = Parser::Ruby.new("a = 1\nb = 2\nc = 3\n")

  # Open a string on line 0
  parser.replace_lines(0, 1, ["a = \"\n"])
  assert.true! parser.dirty?
  parser.reparse!

  # Now all lines are in string context
  assert.equal! parser.lines[1].input_stack.map(&:type), [:string_double]

  # Close the string by editing line 0 back
  parser.replace_lines(0, 1, ["a = \"hello\"\n"])
  # Output stack of line 0 is now [], matching line 1's old input_stack... wait,
  # line 1's input_stack was [:string_double] from the reparse. So it's dirty.
  assert.true! parser.dirty?
  parser.reparse!
  assert.false! parser.dirty?

  # Lines should be back to normal
  assert.true! parser.lines[1].input_stack.empty?, "should be back to normal"
end

# --- replace_lines with empty new_texts (pure deletion) at start ---

def test_incremental_delete_first_line(_args, assert)
  parser = Parser::Ruby.new("a\nb\nc\n")
  parser.replace_lines(0, 1, [])
  assert.equal! parser.line_count, 2
  assert.equal! parser.lines[0].text, "b\n"
  assert.equal! parser.lines[1].text, "c\n"
end

# --- Heredoc incremental ---

def test_incremental_heredoc_edit_body(_args, assert)
  code = "x = <<~TEXT\n  hello\nTEXT\n"
  parser = Parser::Ruby.new(code)

  assert.equal! parser.lines[0].output_stack.map(&:type), [:heredoc]
  assert.true! parser.lines[2].stack.empty?, "heredoc should be closed"

  # Edit body line - should not change stack
  parser.replace_lines(1, 1, ["  world\n"])
  assert.false! parser.dirty?, "editing heredoc body shouldn't change stack"
  assert.equal! parser.lines[1].tokens[0][:type], :heredoc_line
end

# --- reparse_next_line returns false when not dirty ---

def test_incremental_reparse_next_line_when_clean(_args, assert)
  parser = Parser::Ruby.new("x = 1\n")
  assert.false! parser.reparse_next_line, "should return false when not dirty"
end

# --- Multiple edits ---

def test_incremental_multiple_sequential_edits(_args, assert)
  parser = Parser::Ruby.new("a\nb\nc\nd\n")

  # Edit line 1
  parser.replace_lines(1, 1, ["bb\n"])
  assert.false! parser.dirty?

  # Edit line 2
  parser.replace_lines(2, 1, ["cc\n"])
  assert.false! parser.dirty?

  assert.equal! parser.lines[1].text, "bb\n"
  assert.equal! parser.lines[2].text, "cc\n"
end

# --- replace_lines convergence return (stack matches) ---

def test_incremental_replace_lines_inside_def(_args, assert)
  code = "def foo\n  x = 1\n  y = 2\nend\n"
  parser = Parser::Ruby.new(code)

  # Edit line inside def - stack stays [:def]
  parser.replace_lines(1, 1, ["  x = 99\n"])
  assert.false! parser.dirty?, "editing inside def shouldn't dirty subsequent lines"
  assert.equal! parser.lines[1].output_stack.map(&:type), [:def]
end
