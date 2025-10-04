class RubyParser
  OPERATORS = [
    '=>', '==', '!=', '<=', '>=', '<<', '>>', '&&', '||',
    '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~',
    '(', ')', '[', ']', '{', '}', ',', '.', ':', ';', '?'
  ]

  KEYWORDS = [
    'alias', 'and', 'begin', 'break', 'case', 'class', 'def', 'defined?',
    'do', 'else', 'elsif', 'end', 'ensure', 'false', 'for', 'if', 'in',
    'module', 'next', 'nil', 'not', 'or', 'redo', 'rescue', 'retry',
    'return', 'self', 'super', 'then', 'true', 'undef', 'unless', 'until',
    'when', 'while', 'yield'
  ]

  def initialize(input)
    @input = input
    @pos = 0
    @tokens = []
  end

  def parse
    return [] if @input.nil? || @input.empty?

    while @pos < @input.length
      char = @input[@pos]

      if whitespace?(char)
        parse_whitespace
      elsif digit?(char)
        parse_number
      elsif char == '#'
        parse_comment
      elsif char == '"'
        parse_string_double
      elsif char == "'"
        parse_string_single
      elsif char == ':'
        parse_symbol
      elsif operator_start?(char)
        parse_operator
      elsif identifier_start?(char)
        parse_identifier
      else
        @pos += 1
      end
    end

    @tokens
  end

  private

  def whitespace?(char)
    char == ' ' || char == "\t" || char == "\n" || char == "\r"
  end

  def digit?(char)
    char >= '0' && char <= '9'
  end

  def identifier_start?(char)
    (char >= 'a' && char <= 'z') ||
    (char >= 'A' && char <= 'Z') ||
    char == '_'
  end

  def identifier_char?(char)
    identifier_start?(char) || digit?(char) || char == '?' || char == '!'
  end

  def operator_start?(char)
    OPERATORS.any? { |op| op[0] == char }
  end

  def parse_whitespace
    start_pos = @pos
    while @pos < @input.length && whitespace?(@input[@pos])
      @pos += 1
    end
    add_token(:whitespace, start_pos, @pos - 1)
  end

  def parse_number
    start_pos = @pos

    # Parse integer or decimal part with optional underscores
    while @pos < @input.length
      char = @input[@pos]
      if digit?(char)
        @pos += 1
      elsif char == '_' && @pos + 1 < @input.length && digit?(@input[@pos + 1])
        # Allow underscore only if followed by a digit
        @pos += 1
      elsif char == '.' && @pos + 1 < @input.length && digit?(@input[@pos + 1])
        # Allow decimal point only if followed by a digit
        @pos += 1
      else
        break
      end
    end

    add_token(:number, start_pos, @pos - 1)
  end

  def parse_comment
    start_pos = @pos
    while @pos < @input.length && @input[@pos] != "\n"
      @pos += 1
    end
    add_token(:comment, start_pos, @pos - 1)
  end

  def parse_string_double
    start_pos = @pos
    @pos += 1  # skip opening quote

    while @pos < @input.length
      char = @input[@pos]
      if char == '\\'
        @pos += 2  # skip escape sequence
      elsif char == '"'
        @pos += 1  # include closing quote
        break
      else
        @pos += 1
      end
    end

    add_token(:string, start_pos, @pos - 1)
  end

  def parse_string_single
    start_pos = @pos
    @pos += 1  # skip opening quote

    while @pos < @input.length
      char = @input[@pos]
      if char == '\\'
        @pos += 2  # skip escape sequence
      elsif char == "'"
        @pos += 1  # include closing quote
        break
      else
        @pos += 1
      end
    end

    add_token(:string, start_pos, @pos - 1)
  end

  def parse_symbol
    start_pos = @pos
    @pos += 1  # skip ':'

    # Symbol can be quoted or identifier-like
    if @pos < @input.length
      if @input[@pos] == '"' || @input[@pos] == "'"
        # Quoted symbol like :"foo bar"
        quote = @input[@pos]
        @pos += 1
        while @pos < @input.length && @input[@pos] != quote
          @pos += 1
        end
        @pos += 1 if @pos < @input.length  # skip closing quote
      else
        # Regular symbol like :foo
        while @pos < @input.length && identifier_char?(@input[@pos])
          @pos += 1
        end
      end
    end

    add_token(:symbol, start_pos, @pos - 1)
  end

  def parse_operator
    start_pos = @pos

    # Try to match multi-character operators first
    if @pos + 1 < @input.length
      two_char = @input[@pos..@pos + 1]
      if OPERATORS.include?(two_char)
        @pos += 2
        add_token(:operator, start_pos, @pos - 1)
        return
      end
    end

    # Single character operator
    @pos += 1
    add_token(:operator, start_pos, @pos - 1)
  end

  def parse_identifier
    start_pos = @pos
    while @pos < @input.length && identifier_char?(@input[@pos])
      @pos += 1
    end

    value = @input[start_pos..@pos - 1]
    token_type = KEYWORDS.include?(value) ? :keyword : :identifier
    add_token(token_type, start_pos, @pos - 1)
  end

  def add_token(type, start_pos, end_pos)
    value = @input[start_pos..end_pos]
    @tokens << { type: type, value: value, start: start_pos, end: end_pos }
  end
end
