def assert_parses_to(assert, input, expected_tokens, message = nil)
  parser = RubyParser.new(input)
  actual = parser.parse

  error_msg = message || <<~EOS
    Failed to parse: '#{input}'
    Expected: #{expected_tokens.inspect}
    Actual:   #{actual.inspect}
  EOS

  assert.equal! actual, expected_tokens, error_msg
end

def token(type, value, start_pos = 0, end_pos = nil)
  end_pos ||= start_pos + value.length - 1
  { type: type, value: value, start: start_pos, end: end_pos }
end
