require_relative 'test_helpers'

# ---- Multiline method definition tests ------------------------------------------

def test_multiline_def_basic(_args, assert)
  parser1 = Parser::RubyLine.new('def foo').parse
  assert.equal!(parser1.stack.map(&:type), [:def])
  assert.equal!(parser1.stack.last.name, 'foo')
  assert.equal!(parser1.stack.last.depth, 0)

  parser2 = Parser::RubyLine.new('end', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
  assert.false!(parser1.stack.empty?)  # We dup the stack
end

def test_multiline_def_with_body(_args, assert)
  parser1 = Parser::RubyLine.new('def calculate').parse
  assert.equal!(parser1.stack.map(&:type), [:def])

  parser2 = Parser::RubyLine.new('  x = 1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def])

  parser3 = Parser::RubyLine.new('  y = 2', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_def_with_nested_if(_args, assert)
  parser1 = Parser::RubyLine.new('def check').parse
  assert.equal!(parser1.stack.map(&:type), [:def])
  assert.equal!(parser1.stack.last.depth, 0)

  parser2 = Parser::RubyLine.new('  if true', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def, :if])

  parser3 = Parser::RubyLine.new('    puts "yes"', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def, :if])

  parser4 = Parser::RubyLine.new('  end', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:def])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_def_with_nested_def(_args, assert)
  parser1 = Parser::RubyLine.new('def outer').parse
  assert.equal!(parser1.stack.map(&:type), [:def])
  assert.equal!(parser1.stack.last.depth, 0)

  parser2 = Parser::RubyLine.new('  def inner', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:def, :def])

  parser3 = Parser::RubyLine.new('  end', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:def])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

# ---- Multiline class definition tests -------------------------------------------

def test_multiline_class_basic(_args, assert)
  parser1 = Parser::RubyLine.new('class Foo').parse
  assert.equal!(parser1.stack.map(&:type), [:class])
  assert.equal!(parser1.stack.last.name, 'Foo')
  assert.equal!(parser1.stack.last.depth, 0)

  parser2 = Parser::RubyLine.new('end', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_class_with_method(_args, assert)
  parser1 = Parser::RubyLine.new('class MyClass').parse
  assert.equal!(parser1.stack.map(&:type), [:class])

  parser2 = Parser::RubyLine.new('  def method1', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:class, :def])

  parser3 = Parser::RubyLine.new('    x = 1', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:class, :def])

  parser4 = Parser::RubyLine.new('  end', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:class])

  parser5 = Parser::RubyLine.new('end', parser4.stack).parse
  assert.true!(parser5.stack.empty?)
end

def test_multiline_class_nested(_args, assert)
  parser1 = Parser::RubyLine.new('class Outer').parse
  assert.equal!(parser1.stack.map(&:type), [:class])
  assert.equal!(parser1.stack.last.depth, 0)

  parser2 = Parser::RubyLine.new('  class Inner', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:class, :class])

  parser3 = Parser::RubyLine.new('  end', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:class])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

# ---- Multiline module definition tests ------------------------------------------

def test_multiline_module_basic(_args, assert)
  parser1 = Parser::RubyLine.new('module Bar').parse
  assert.equal!(parser1.stack.map(&:type), [:module])
  assert.equal!(parser1.stack.last.name, 'Bar')
  assert.equal!(parser1.stack.last.depth, 0)

  parser2 = Parser::RubyLine.new('end', parser1.stack).parse
  assert.true!(parser2.stack.empty?)
end

def test_multiline_module_with_method(_args, assert)
  parser1 = Parser::RubyLine.new('module MyModule').parse
  assert.equal!(parser1.stack.map(&:type), [:module])

  parser2 = Parser::RubyLine.new('  def helper', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:module, :def])

  parser3 = Parser::RubyLine.new('  end', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:module])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_module_nested(_args, assert)
  parser1 = Parser::RubyLine.new('module Outer').parse
  assert.equal!(parser1.stack.map(&:type), [:module])

  parser2 = Parser::RubyLine.new('  module Inner', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:module, :module])

  parser3 = Parser::RubyLine.new('  end', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:module])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

# ---- Mixed tests -----------------------------------------------------------------

def test_multiline_class_with_module(_args, assert)
  parser1 = Parser::RubyLine.new('class Foo').parse
  assert.equal!(parser1.stack.map(&:type), [:class])

  parser2 = Parser::RubyLine.new('  module Bar', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:class, :module])

  parser3 = Parser::RubyLine.new('  end', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:class])

  parser4 = Parser::RubyLine.new('end', parser3.stack).parse
  assert.true!(parser4.stack.empty?)
end

def test_multiline_complex_nesting(_args, assert)
  parser1 = Parser::RubyLine.new('class Game').parse
  assert.equal!(parser1.stack.map(&:type), [:class])

  parser2 = Parser::RubyLine.new('  def tick', parser1.stack).parse
  assert.equal!(parser2.stack.map(&:type), [:class, :def])

  parser3 = Parser::RubyLine.new('    if player.alive?', parser2.stack).parse
  assert.equal!(parser3.stack.map(&:type), [:class, :def, :if])

  parser4 = Parser::RubyLine.new('      while enemies.any?', parser3.stack).parse
  assert.equal!(parser4.stack.map(&:type), [:class, :def, :if, :while])

  parser5 = Parser::RubyLine.new('      end', parser4.stack).parse
  assert.equal!(parser5.stack.map(&:type), [:class, :def, :if])

  parser6 = Parser::RubyLine.new('    end', parser5.stack).parse
  assert.equal!(parser6.stack.map(&:type), [:class, :def])

  parser7 = Parser::RubyLine.new('  end', parser6.stack).parse
  assert.equal!(parser7.stack.map(&:type), [:class])

  parser8 = Parser::RubyLine.new('end', parser7.stack).parse
  assert.true!(parser8.stack.empty?)
end
