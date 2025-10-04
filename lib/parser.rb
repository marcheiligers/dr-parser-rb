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
        # Check if this is :: (scope operator), part of namespace, hash syntax, or a symbol
        if @pos + 1 < @input.length
          next_char = @input[@pos + 1]
          if next_char == ':' || (next_char >= 'A' && next_char <= 'Z') || whitespace?(next_char) || next_char == '}'
            # :: or :Constant or hash syntax (a: value) - treat as operator
            parse_operator
          else
            parse_symbol
          end
        else
          parse_operator
        end
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
    string_start = @pos
    @pos += 1  # skip opening quote

    while @pos < @input.length
      char = @input[@pos]

      if char == '\\'
        # Check for escaped interpolation
        if @pos + 1 < @input.length && @input[@pos + 1] == '#'
          @pos += 2  # skip \#
        else
          @pos += 2  # skip other escape sequence
        end
      elsif char == '#' && @pos + 1 < @input.length && @input[@pos + 1] == '{'
        # Found interpolation - emit string token up to here
        if @pos > string_start
          add_token(:string, string_start, @pos - 1)
        end

        # Parse interpolation
        parse_interpolation

        # Continue with next string segment
        string_start = @pos
      elsif char == '"'
        # Emit final string token including closing quote
        add_token(:string, string_start, @pos)
        @pos += 1
        return
      else
        @pos += 1
      end
    end

    # Incomplete string - emit what we have
    if @pos > string_start
      add_token(:string, string_start, @pos - 1)
    end
  end

  def parse_interpolation
    # Emit interpolation start token
    interp_start = @pos
    @pos += 2  # skip #{
    add_token(:interpolation_start, interp_start, @pos - 1)

    # Track brace depth to handle nested braces
    brace_depth = 1

    # Parse tokens inside interpolation
    while @pos < @input.length && brace_depth > 0
      char = @input[@pos]

      if char == '{'
        brace_depth += 1
        parse_operator
      elsif char == '}'
        brace_depth -= 1
        if brace_depth == 0
          # Emit interpolation end token
          add_token(:interpolation_end, @pos, @pos)
          @pos += 1
        else
          parse_operator
        end
      elsif whitespace?(char)
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
        # Check if this is :: (scope operator), part of namespace, hash syntax, or a symbol
        if @pos + 1 < @input.length
          next_char = @input[@pos + 1]
          if next_char == ':' || (next_char >= 'A' && next_char <= 'Z') || whitespace?(next_char) || next_char == '}'
            # :: or :Constant or hash syntax (a: value) - treat as operator
            parse_operator
          else
            parse_symbol
          end
        else
          parse_operator
        end
      elsif operator_start?(char)
        parse_operator
      elsif identifier_start?(char)
        parse_identifier
      else
        @pos += 1
      end
    end
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
    first_char = @input[@pos]

    while @pos < @input.length && identifier_char?(@input[@pos])
      @pos += 1
    end

    value = @input[start_pos..@pos - 1]

    # Determine token type: constant (starts with uppercase), keyword, or identifier
    if first_char >= 'A' && first_char <= 'Z'
      token_type = :constant
    elsif KEYWORDS.include?(value)
      token_type = :keyword
    else
      token_type = :identifier
    end

    add_token(token_type, start_pos, @pos - 1)
  end

  def add_token(type, start_pos, end_pos)
    value = @input[start_pos..end_pos]
    @tokens << { type: type, value: value, start: start_pos, end: end_pos }
  end
end
