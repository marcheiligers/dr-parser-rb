require_relative 'test_helpers'

# ---- Multiline if tests ------------------------------------------------------

def test_multiline_if_basic(_args, assert)
  parser1 = RubyLineParser.new('if true').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = RubyLineParser.new('end', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_if_with_elsif(_args, assert)
  parser1 = RubyLineParser.new('if x > 5').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = RubyLineParser.new('  puts "big"', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:if])

  parser3 = RubyLineParser.new('elsif x > 0', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:if])

  parser4 = RubyLineParser.new('  puts "small"', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:if])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_if_with_else(_args, assert)
  parser1 = RubyLineParser.new('if condition').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = RubyLineParser.new('  x = 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:if])

  parser3 = RubyLineParser.new('else', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:if])

  parser4 = RubyLineParser.new('  x = 2', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:if])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_unless_basic(_args, assert)
  parser1 = RubyLineParser.new('unless false').parse
  assert.equal!(parser1.stack.map(&:type), [:unless])

  parser2 = RubyLineParser.new('  puts "yes"', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:unless])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_modifier_if_does_not_push_frame(_args, assert)
  parser1 = RubyLineParser.new('puts "hi" if true').parse
  assert.true!(parser1.stack.empty?)
end

def test_modifier_unless_does_not_push_frame(_args, assert)
  parser1 = RubyLineParser.new('return unless valid?').parse
  assert.true!(parser1.stack.empty?)
end

# ---- Multiline case tests ----------------------------------------------------

def test_multiline_case_basic(_args, assert)
  parser1 = RubyLineParser.new('case x').parse
  assert.equal!(parser1.stack.map(&:type), [:case])

  parser2 = RubyLineParser.new('when 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:case])

  parser3 = RubyLineParser.new('  puts "one"', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:case])

  parser4 = RubyLineParser.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_case_with_multiple_when(_args, assert)
  parser1 = RubyLineParser.new('case value').parse
  assert.equal!(parser1.stack.map(&:type), [:case])

  parser2 = RubyLineParser.new('when :a', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:case])

  parser3 = RubyLineParser.new('  x = 1', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:case])

  parser4 = RubyLineParser.new('when :b', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:case])

  parser5 = RubyLineParser.new('  x = 2', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:case])

  parser6 = RubyLineParser.new('end', parser5.stack).parse
  assert.true!(parser6.stack.empty?)
end

def test_multiline_case_with_else(_args, assert)
  parser1 = RubyLineParser.new('case n').parse
  assert.equal!(parser1.stack.map(&:type), [:case])

  parser2 = RubyLineParser.new('when 0', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:case])

  parser3 = RubyLineParser.new('else', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:case])

  parser4 = RubyLineParser.new('  puts "other"', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:case])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

# ---- Multiline loop tests ----------------------------------------------------

def test_multiline_while_basic(_args, assert)
  parser1 = RubyLineParser.new('while true').parse
  assert.equal!(parser1.stack.map(&:type), [:while])

  parser2 = RubyLineParser.new('  x += 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:while])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_until_basic(_args, assert)
  parser1 = RubyLineParser.new('until done?').parse
  assert.equal!(parser1.stack.map(&:type), [:until])

  parser2 = RubyLineParser.new('  process', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:until])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_for_basic(_args, assert)
  parser1 = RubyLineParser.new('for i in 1..10').parse
  assert.equal!(parser1.stack.map(&:type), [:for])

  parser2 = RubyLineParser.new('  puts i', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:for])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_modifier_while_does_not_push_frame(_args, assert)
  parser1 = RubyLineParser.new('sleep 0.1 while running?').parse
  assert.true!(parser1.stack.empty?)
end

def test_modifier_until_does_not_push_frame(_args, assert)
  parser1 = RubyLineParser.new('wait until ready?').parse
  assert.true!(parser1.stack.empty?)
end

# ---- Multiline do block tests ------------------------------------------------

def test_multiline_do_block_basic(_args, assert)
  parser1 = RubyLineParser.new('items.each do').parse
  assert.equal!(parser1.stack.map(&:type), [:do_block])

  parser2 = RubyLineParser.new('  puts item', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:do_block])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_do_block_with_params(_args, assert)
  parser1 = RubyLineParser.new('arr.map do |x|').parse
  assert.equal!(parser1.stack.map(&:type), [:do_block])

  parser2 = RubyLineParser.new('  x * 2', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:do_block])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

# ---- Multiline begin/rescue tests --------------------------------------------

def test_multiline_begin_basic(_args, assert)
  parser1 = RubyLineParser.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = RubyLineParser.new('  risky_operation', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = RubyLineParser.new('end', parser2.stack).parse
  assert.true!(parser3.stack.empty?)
end

def test_multiline_begin_with_rescue(_args, assert)
  parser1 = RubyLineParser.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = RubyLineParser.new('  try_it', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = RubyLineParser.new('rescue', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:begin])

  parser4 = RubyLineParser.new('  handle_error', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:begin])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_begin_with_ensure(_args, assert)
  parser1 = RubyLineParser.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = RubyLineParser.new('  do_work', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = RubyLineParser.new('ensure', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:begin])

  parser4 = RubyLineParser.new('  cleanup', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:begin])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_begin_full(_args, assert)
  parser1 = RubyLineParser.new('begin').parse
  assert.equal!(parser1.stack.map(&:type), [:begin])

  parser2 = RubyLineParser.new('  risky', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:begin])

  parser3 = RubyLineParser.new('rescue StandardError', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:begin])

  parser4 = RubyLineParser.new('  handle', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:begin])

  parser5 = RubyLineParser.new('else', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:begin])

  parser6 = RubyLineParser.new('  success', parser5.stack).parse
  assert.equal!(parser6.stack.map(&:type), [:begin])

  parser7 = RubyLineParser.new('ensure', parser6.stack).parse
  assert.equal!(parser7.stack.map(&:type), [:begin])

  parser8 = RubyLineParser.new('  cleanup', parser7.stack).parse
  assert.equal!(parser8.stack.map(&:type), [:begin])

  parser9 = RubyLineParser.new('end', parser8.stack).parse
  assert.true!(parser9.stack.empty?)
end

# ---- Nested control flow tests -----------------------------------------------

def test_nested_if_in_while(_args, assert)
  parser1 = RubyLineParser.new('while running').parse
  assert.equal!(parser1.stack.map(&:type), [:while])

  parser2 = RubyLineParser.new('  if check', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:while, :if])

  parser3 = RubyLineParser.new('    action', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:while, :if])

  parser4 = RubyLineParser.new('  end', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:while])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_nested_case_in_def(_args, assert)
  parser1 = RubyLineParser.new('def process').parse
  assert.equal!(parser1.stack.map(&:type), [:def])

  parser2 = RubyLineParser.new('  case type', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def, :case])

  parser3 = RubyLineParser.new('  when :a', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def, :case])

  parser4 = RubyLineParser.new('    handle_a', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:def, :case])

  parser5 = RubyLineParser.new('  end', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:def])

  parser6 = RubyLineParser.new('end', parser5.stack).parse
  assert.true!(parser6.stack.empty?)
end

def test_do_block_in_if(_args, assert)
  parser1 = RubyLineParser.new('if ready').parse
  assert.equal!(parser1.stack.map(&:type), [:if])

  parser2 = RubyLineParser.new('  items.each do |i|', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:if, :do_block])

  parser3 = RubyLineParser.new('    process i', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:if, :do_block])

  parser4 = RubyLineParser.new('  end', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:if])

  parser5 = RubyLineParser.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end
