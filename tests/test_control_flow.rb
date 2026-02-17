require_relative 'test_helpers'

# ---- Multiline if tests ------------------------------------------------------

def test_multiline_if_basic(_args, assert)
  parser1 = Parser::RubyLine.new('if true').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = Parser::RubyLine.new('end', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_if_with_elsif(_args, assert)
  parser1 = Parser::RubyLine.new('if x > 5').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = Parser::RubyLine.new('  puts "big"', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:if])

  parser3 = Parser::RubyLine.new('elsif x > 0', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:if])

  parser4 = Parser::RubyLine.new('  puts "small"', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:if])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_if_with_else(_args, assert)
  parser1 = Parser::RubyLine.new('if condition').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = Parser::RubyLine.new('  x = 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:if])

  parser3 = Parser::RubyLine.new('else', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:if])

  parser4 = Parser::RubyLine.new('  x = 2', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:if])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_unless_basic(_args, assert)
  parser1 = Parser::RubyLine.new('unless false').parse
  assert.equal!(parser1.stack.map(&:type), [:unless])

  parser2 = Parser::RubyLine.new('  puts "yes"', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:unless])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_modifier_if_does_not_push_frame(_args, assert)
  parser1 = Parser::RubyLine.new('puts "hi" if true').parse
  assert.true!(parser1.stack.empty?)
end

def test_modifier_unless_does_not_push_frame(_args, assert)
  parser1 = Parser::RubyLine.new('return unless valid?').parse
  assert.true!(parser1.stack.empty?)
end

# ---- Multiline case tests ----------------------------------------------------

def test_multiline_case_basic(_args, assert)
  parser1 = Parser::RubyLine.new('case x').parse
  assert.equal!(parser1.stack.map(&:type), [:case])

  parser2 = Parser::RubyLine.new('when 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:case])

  parser3 = Parser::RubyLine.new('  puts "one"', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:case])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_case_with_multiple_when(_args, assert)
  parser1 = Parser::RubyLine.new('case value').parse
  assert.equal!(parser1.stack.map(&:type), [:case])

  parser2 = Parser::RubyLine.new('when :a', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:case])

  parser3 = Parser::RubyLine.new('  x = 1', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:case])

  parser4 = Parser::RubyLine.new('when :b', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:case])

  parser5 = Parser::RubyLine.new('  x = 2', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:case])

  parser6 = Parser::RubyLine.new('end', parser5.stack).parse
  assert.true!(parser6.stack.empty?)
end

def test_multiline_case_with_else(_args, assert)
  parser1 = Parser::RubyLine.new('case n').parse
  assert.equal!(parser1.stack.map(&:type), [:case])

  parser2 = Parser::RubyLine.new('when 0', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:case])

  parser3 = Parser::RubyLine.new('else', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:case])

  parser4 = Parser::RubyLine.new('  puts "other"', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:case])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

# ---- Multiline loop tests ----------------------------------------------------

def test_multiline_while_basic(_args, assert)
  parser1 = Parser::RubyLine.new('while true').parse
  assert.equal!(parser1.stack.map(&:type), [:while])

  parser2 = Parser::RubyLine.new('  x += 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:while])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_until_basic(_args, assert)
  parser1 = Parser::RubyLine.new('until done?').parse
  assert.equal!(parser1.stack.map(&:type), [:until])

  parser2 = Parser::RubyLine.new('  process', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:until])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_for_basic(_args, assert)
  parser1 = Parser::RubyLine.new('for i in 1..10').parse
  assert.equal!(parser1.stack.map(&:type), [:for])

  parser2 = Parser::RubyLine.new('  puts i', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:for])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_modifier_while_does_not_push_frame(_args, assert)
  parser1 = Parser::RubyLine.new('sleep 0.1 while running?').parse
  assert.true!(parser1.stack.empty?)
end

def test_modifier_until_does_not_push_frame(_args, assert)
  parser1 = Parser::RubyLine.new('wait until ready?').parse
  assert.true!(parser1.stack.empty?)
end

# ---- Multiline do block tests ------------------------------------------------

def test_multiline_do_block_basic(_args, assert)
  parser1 = Parser::RubyLine.new('items.each do').parse
  assert.equal!(parser1.stack.map(&:type), [:do_block])

  parser2 = Parser::RubyLine.new('  puts item', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:do_block])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_do_block_with_params(_args, assert)
  parser1 = Parser::RubyLine.new('arr.map do |x|').parse
  assert.equal!(parser1.stack.map(&:type), [:do_block])

  parser2 = Parser::RubyLine.new('  x * 2', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:do_block])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

# ---- Multiline begin/rescue tests --------------------------------------------

def test_multiline_begin_basic(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = Parser::RubyLine.new('  risky_operation', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = Parser::RubyLine.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_begin_with_rescue(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = Parser::RubyLine.new('  try_it', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = Parser::RubyLine.new('rescue', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:begin])

  parser4 = Parser::RubyLine.new('  handle_error', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:begin])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_begin_with_ensure(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = Parser::RubyLine.new('  do_work', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = Parser::RubyLine.new('ensure', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:begin])

  parser4 = Parser::RubyLine.new('  cleanup', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:begin])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_begin_full(_args, assert)
  parser1 = Parser::RubyLine.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = Parser::RubyLine.new('  risky', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = Parser::RubyLine.new('rescue StandardError', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:begin])

  parser4 = Parser::RubyLine.new('  handle', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:begin])

  parser5 = Parser::RubyLine.new('else', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:begin])

  parser6 = Parser::RubyLine.new('  success', parser5.stack).parse
  assert.equal!(parser6.stack.map(&:type), [:begin])

  parser7 = Parser::RubyLine.new('ensure', parser6.stack).parse
  assert.equal!(parser7.stack.map(&:type), [:begin])

  parser8 = Parser::RubyLine.new('  cleanup', parser7.stack).parse
  assert.equal!(parser8.stack.map(&:type), [:begin])

  parser9 = Parser::RubyLine.new('end', parser8.stack).parse
  assert.true!(parser9.stack.empty?)
end

# ---- Nested control flow tests -----------------------------------------------

def test_nested_if_in_while(_args, assert)
  parser1 = Parser::RubyLine.new('while running').parse
  assert.equal!(parser1.stack.map(&:type), [:while])

  parser2 = Parser::RubyLine.new('  if check', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:while, :if])

  parser3 = Parser::RubyLine.new('    action', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:while, :if])

  parser4 = Parser::RubyLine.new('  end', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:while])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_nested_case_in_def(_args, assert)
  parser1 = Parser::RubyLine.new('def process').parse
  assert.equal!(parser1.stack.map(&:type), [:def])

  parser2 = Parser::RubyLine.new('  case type', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def, :case])

  parser3 = Parser::RubyLine.new('  when :a', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def, :case])

  parser4 = Parser::RubyLine.new('    handle_a', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:def, :case])

  parser5 = Parser::RubyLine.new('  end', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:def])

  parser6 = Parser::RubyLine.new('end', parser5.stack).parse
  assert.true!(parser6.stack.empty?)
end

def test_do_block_in_if(_args, assert)
  parser1 = Parser::RubyLine.new('if ready').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = Parser::RubyLine.new('  items.each do |i|', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:if, :do_block])

  parser3 = Parser::RubyLine.new('    process i', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:if, :do_block])

  parser4 = Parser::RubyLine.new('  end', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:if])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end
