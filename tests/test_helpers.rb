def assert_parses_to(assert, input, expected_tokens, message = nil)
  parser = Parser::Ruby.new(input)
  actual = parser.lines.first.tokens

  error_msg = message || <<~EOS
    Failed to parse: '#{input}'
    Expected: #{expected_tokens.inspect}
    Actual:   #{actual.inspect}
  EOS

  assert.equal! actual, expected_tokens, error_msg
  debug_parser(parser)
end

def token(type, value, start_pos = 0, end_pos = nil)
  end_pos ||= start_pos + value.length - 1
  { type: type, value: value, start: start_pos, end: end_pos }
end

def debug_parser(parser)
  parser.lines.each_with_index do |line, i|
    puts "line #{i.to_s.ljust(15)} => #{line.stack.map(&:type)}"
    line.tokens.each do |tok|
      puts "#{tok.type.to_s.ljust(20)} -> #{tok.value}"
    end
  end
end
