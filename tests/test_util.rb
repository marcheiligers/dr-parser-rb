require_relative 'test_helpers'

# ---- find_operator -----------------------------------------------------------

def test_find_operator_three_char(_args, assert)
  assert.equal! Parser::Util.find_operator('<=>'), '<=>'
  assert.equal! Parser::Util.find_operator('<=> '), '<=>'
  assert.equal! Parser::Util.find_operator('<=>x'), '<=>'
  assert.equal! Parser::Util.find_operator(' <=>'), nil
  assert.equal! Parser::Util.find_operator('x<=>'), nil
end

def test_find_operator_two_char(_args, assert)
  assert.equal! Parser::Util.find_operator('=>'), '=>'
  assert.equal! Parser::Util.find_operator('=='), '=='
  assert.equal! Parser::Util.find_operator('<<'), '<<'
  assert.equal! Parser::Util.find_operator('== '), '=='
  assert.equal! Parser::Util.find_operator(' =='), nil
  assert.equal! Parser::Util.find_operator('x=='), nil
end

def test_find_operator_one_char(_args, assert)
  assert.equal! Parser::Util.find_operator('+'), '+'
  assert.equal! Parser::Util.find_operator('('), '('
  assert.equal! Parser::Util.find_operator('.'), '.'
  assert.equal! Parser::Util.find_operator('+ '), '+'
  assert.equal! Parser::Util.find_operator(' +'), nil
  assert.equal! Parser::Util.find_operator('x+'), nil
end

def test_find_operator_precedence(_args, assert)
  # Three-char > two-char > one-char
  assert.equal! Parser::Util.find_operator('<=>'), '<=>'
  assert.equal! Parser::Util.find_operator('=='), '=='
  assert.equal! Parser::Util.find_operator('<x'), '<'
end

# ---- whitespace? -------------------------------------------------------------

def test_whitespace(_args, assert)
  assert.true! Parser::Util.whitespace?(' ')
  assert.true! Parser::Util.whitespace?("\t")
  assert.true! Parser::Util.whitespace?("\n")
  assert.false! Parser::Util.whitespace?('a')
  assert.false! Parser::Util.whitespace?('0')
end

# ---- digit? ------------------------------------------------------------------

def test_digit(_args, assert)
  assert.true! Parser::Util.digit?('0')
  assert.true! Parser::Util.digit?('5')
  assert.true! Parser::Util.digit?('9')
  assert.false! Parser::Util.digit?('a')
  assert.false! Parser::Util.digit?(' ')
end

# ---- identifier_start? -------------------------------------------------------

def test_identifier_start(_args, assert)
  assert.true! Parser::Util.identifier_start?('a')
  assert.true! Parser::Util.identifier_start?('Z')
  assert.true! Parser::Util.identifier_start?('_')
  assert.false! Parser::Util.identifier_start?('0')
  assert.false! Parser::Util.identifier_start?('?')
  assert.false! Parser::Util.identifier_start?(' ')
end

# ---- identifier_char? --------------------------------------------------------

def test_identifier_char(_args, assert)
  assert.true! Parser::Util.identifier_char?('a')
  assert.true! Parser::Util.identifier_char?('Z')
  assert.true! Parser::Util.identifier_char?('_')
  assert.true! Parser::Util.identifier_char?('5')
  assert.true! Parser::Util.identifier_char?('?')
  assert.true! Parser::Util.identifier_char?('!')
  assert.false! Parser::Util.identifier_char?(' ')
  assert.false! Parser::Util.identifier_char?('@')
end

# ---- operator_start? ---------------------------------------------------------

def test_operator_start(_args, assert)
  assert.true! Parser::Util.operator_start?('+')
  assert.true! Parser::Util.operator_start?('(')
  assert.true! Parser::Util.operator_start?('.')
  assert.true! Parser::Util.operator_start?('!')
  assert.false! Parser::Util.operator_start?('a')
  assert.false! Parser::Util.operator_start?('0')
  assert.false! Parser::Util.operator_start?('@')
end
