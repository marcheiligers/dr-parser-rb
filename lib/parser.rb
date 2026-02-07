require_relative 'util'

module Parser
  class RubyLine
    include Util

    attr_reader :tokens, :stack

    # For Heredocs:
    #   depth = 0 => no interpolation (single quoted delimiter)
    #   depth = anything else => interpolation
    #   modifier = nil, - or ~ (>>, ->> or ~>>)
    Frame = Struct.new(:type, :depth, :name, :modifier)

    BRACKET_FRAMES = %i[array hash paren].freeze
    ENDABLE_FRAMES = %i[begin case class def do_block for if lambda module unless until while].freeze
    OTHER_FRAMES = %i[backtick heredoc interpolation percent_interp regex string_double].freeze

    def initialize(input, stack = [])
      @input = input
      @pos = 0
      @tokens = []
      @stack = stack.dup
      @last_significant_token = nil
      @prev_significant_token = nil
      @seen_non_whitespace = false  # Track if we've seen non-whitespace on this line
      @endless_method_possible = false  # Track if we might be in an endless method def
    end

    def parse # continue_parse
      while @pos < @input.length
        if @stack.empty?
          start_parse
        else
          case @stack.last.type
            when :string_double then continue_string_double(@pos)
            when :backtick then continue_backtick(@pos)
            when :percent_interp then continue_percent_interp(@pos)
            when :regex then continue_regex(@pos)
            when :interpolation then start_parse
            when :array then continue_array
            when :hash then continue_hash
            when :paren then continue_paren
            when :def then continue_def
            when :class then continue_class
            when :module then continue_module
            when :if then continue_if
            when :unless then continue_unless
            when :case then continue_case
            when :while then continue_while
            when :until then continue_until
            when :for then continue_for
            when :do_block then continue_do_block
            when :lambda then continue_lambda
            when :begin then continue_begin
            when :heredoc then continue_heredoc
            else raise "Unexpected Frame #{@stack.last.type}"
          end
        end
      end

      self
    end

    private

    def start_parse
      return if @input.nil? || @pos >= @input.length

      char = @input[@pos]

      if whitespace?(char)
        parse_whitespace
      elsif digit?(char)
        parse_number
      elsif char == '#'
        parse_comment
      elsif char == '"'
        start_string_double
      elsif char == "'"
        parse_string_single
      elsif char == '?'
        parse_character_literal_or_operator
      elsif char == '%'
        parse_percent_literal
      elsif char == '`'
        start_backtick
      elsif char == '@'
        parse_instance_or_class_variable
      elsif char == '$'
        parse_global
      elsif char == '}'
        parse_closing_brace
        return # Go back to whatever the containing thing was, if anything
      elsif char == ':'
        # Check if this is :: (scope operator), part of namespace, hash syntax, or a symbol
        if @pos + 1 < @input.length
          next_char = @input[@pos + 1]
          # TODO: This looks weird. Thanks, Claude
          if next_char == ':' || (next_char >= 'A' && next_char <= 'Z') || whitespace?(next_char) || next_char == '}'
            # :: or :Constant or hash syntax (a: value) - treat as operator
            parse_operator
          else
            parse_symbol
          end
        else
          parse_operator
        end
      elsif char == '<' && @pos + 1 < @input.length && @input[@pos + 1] == '<'
        # Check for heredoc
        if heredoc_start?
          start_heredoc
        else
          parse_operator
        end
      elsif char == '/' && regex_start_context?
        start_regex
      elsif operator_start?(char)
        parse_operator
      elsif identifier_start?(char)
        parse_identifier
      else
        # TODO: Umm, we're just ignoring stuff we don't recognize
        @pos += 1
      end
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

      # Check for prefix-based literals: 0x (hex), 0b (binary), 0o (octal)
      if @input[@pos] == '0' && @pos + 1 < @input.length
        prefix = @input[@pos + 1]
        if prefix == 'x' || prefix == 'X'
          @pos += 2
          @pos += 1 while @pos < @input.length && hex_char?(@input[@pos])
          add_token(:number, start_pos, @pos - 1)
          return
        elsif prefix == 'b' || prefix == 'B'
          @pos += 2
          @pos += 1 while @pos < @input.length && (@input[@pos] == '0' || @input[@pos] == '1' || @input[@pos] == '_')
          add_token(:number, start_pos, @pos - 1)
          return
        elsif prefix == 'o' || prefix == 'O'
          @pos += 2
          @pos += 1 while @pos < @input.length && ((@input[@pos] >= '0' && @input[@pos] <= '7') || @input[@pos] == '_')
          add_token(:number, start_pos, @pos - 1)
          return
        end
      end

      # Parse integer or decimal part with optional underscores
      while @pos < @input.length
        char = @input[@pos]
        if digit?(char)
          @pos += 1
        elsif char == '_' && @pos + 1 < @input.length && digit?(@input[@pos + 1])
          @pos += 1
        elsif char == '.' && @pos + 1 < @input.length && digit?(@input[@pos + 1])
          @pos += 1
        else
          break
        end
      end

      # Check for scientific notation (e.g., 1e10, 1.5e-3, 2E+5)
      if @pos < @input.length && (@input[@pos] == 'e' || @input[@pos] == 'E')
        @pos += 1
        # Optional sign
        if @pos < @input.length && (@input[@pos] == '+' || @input[@pos] == '-')
          @pos += 1
        end
        @pos += 1 while @pos < @input.length && digit?(@input[@pos])
      end

      add_token(:number, start_pos, @pos - 1)
      @last_significant_token = :number
    end

    def parse_comment
      start_pos = @pos
      while @pos < @input.length && @input[@pos] != "\n"
        @pos += 1
      end
      add_token(:comment, start_pos, @pos - 1)
    end

    def start_string_double
      @stack << Frame.new(:string_double)
      string_start = @pos
      @pos += 1 # skip opening quote
      continue_string_double(string_start)
    end

    def continue_string_double(string_start)
      while @pos < @input.length
        char = @input[@pos]

        if char == '\\'
          # Escaped
          @pos += 2
        elsif char == '#' && @input[@pos + 1] == '{'
          # Interpolation
          add_token(:string, string_start, @pos - 1) if @pos > string_start
          start_interpolation
          return
        elsif char == '"'
          add_token(:string, string_start, @pos)
          @pos += 1
          raise "Expected :string_double but got #{@stack.last.type}" unless @stack.last.type == :string_double

          @stack.pop
          @last_significant_token = :string
          return
        else
          @pos += 1
        end
      end

      # Incomplete string - emit what we have
      add_token(:string, string_start, @pos - 1) if @pos > string_start
    end

    def start_backtick
      @stack << Frame.new(:backtick)
      string_start = @pos
      @pos += 1 # skip opening backtick
      continue_backtick(string_start)
    end

    def continue_backtick(string_start)
      while @pos < @input.length
        char = @input[@pos]

        if char == '\\'
          @pos += 2
        elsif char == '#' && @pos + 1 < @input.length && @input[@pos + 1] == '{'
          add_token(:backtick, string_start, @pos - 1) if @pos > string_start
          start_interpolation
          return
        elsif char == '`'
          add_token(:backtick, string_start, @pos)
          @pos += 1
          @stack.pop
          return
        else
          @pos += 1
        end
      end

      # Incomplete backtick string
      add_token(:backtick, string_start, @pos - 1) if @pos > string_start
    end

    def continue_percent_interp(string_start)
      frame = @stack.last
      closing = frame.name
      opening = case closing
                when ')' then '('
                when ']' then '['
                when '}' then '{'
                when '>' then '<'
                else nil
                end
      token_type = frame.modifier

      while @pos < @input.length
        char = @input[@pos]

        if char == '\\'
          @pos += 2
        elsif char == '#' && @pos + 1 < @input.length && @input[@pos + 1] == '{'
          add_token(token_type, string_start, @pos - 1) if @pos > string_start
          start_interpolation
          return
        elsif opening && char == opening
          frame.depth += 1
          @pos += 1
        elsif char == closing
          if frame.depth > 0
            frame.depth -= 1
            @pos += 1
          else
            add_token(token_type, string_start, @pos)
            @pos += 1
            @stack.pop
            return
          end
        else
          @pos += 1
        end
      end

      # Incomplete - emit what we have
      add_token(token_type, string_start, @pos - 1) if @pos > string_start
    end

    def start_interpolation
      add_token(:interpolation_start, @pos, @pos + 1) # skip #{
      @pos += 2
      @stack << Frame.new(:interpolation, 1)
      start_parse
    end

    def continue_array
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :array
      end
    end

    def continue_hash
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :hash
      end
    end

    def continue_paren
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :paren
      end
    end

    def continue_def
      while @pos < @input.length
        char = @input[@pos]

        # Check for keywords that might nest or close this frame
        if identifier_start?(char)
          # This will parse the identifier/keyword and handle_keyword_frame will manage depth
          start_parse
          # Check if frame was popped (stack empty or different frame type)
          return if @stack.empty? || @stack.last.type != :def
        else
          start_parse
        end
      end
    end

    def continue_class
      while @pos < @input.length
        char = @input[@pos]

        # Check for keywords that might nest or close this frame
        if identifier_start?(char)
          # This will parse the identifier/keyword and handle_keyword_frame will manage depth
          start_parse
          # Check if frame was popped (stack empty or different frame type)
          return if @stack.empty? || @stack.last.type != :class
        else
          start_parse
        end
      end
    end

    def continue_module
      while @pos < @input.length
        char = @input[@pos]

        # Check for keywords that might nest or close this frame
        if identifier_start?(char)
          # This will parse the identifier/keyword and handle_keyword_frame will manage depth
          start_parse
          # Check if frame was popped (stack empty or different frame type)
          return if @stack.empty? || @stack.last.type != :module
        else
          start_parse
        end
      end
    end

    def continue_if
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :if
      end
    end

    def continue_unless
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :unless
      end
    end

    def continue_case
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :case
      end
    end

    def continue_while
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :while
      end
    end

    def continue_until
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :until
      end
    end

    def continue_for
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :for
      end
    end

    def continue_do_block
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :do_block
      end
    end

    def continue_lambda
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :lambda
      end
    end

    def continue_begin
      while @pos < @input.length
        start_parse
        return if @stack.empty? || @stack.last.type != :begin
      end
    end

    def continue_heredoc
      # Check if current line matches delimiter (with or without indentation based on modifier)
      line_to_check = case @stack.last.modifier
                      when '-', '~' # <<- or <<~ allow indented closing delimiter
                        @input.strip
                      else # << requires exact match
                        @input.chomp # Remove trailing newline but keep leading whitespace
                      end

      if line_to_check == @stack.last.name
        add_token(:heredoc_end, 0, @input.length - 1)
        @stack.pop
        @pos = @input.length
      elsif @stack.last.depth == 0
        add_token(:heredoc_line, 0, @input.length - 1)
        @pos = @input.length  # Consume the entire line
      else
        continue_heredoc_with_interpolation
      end
    end

    def continue_heredoc_with_interpolation
      string_start = @pos

      while @pos < @input.length
        char = @input[@pos]

        if char == '\\'
          # Escaped
          @pos += 2  # skip escape sequence
        elsif char == '#' && @pos + 1 < @input.length && @input[@pos + 1] == '{'
          # Interpolation
          add_token(:heredoc_line, string_start, @pos - 1) if @pos > string_start
          start_interpolation
          return
        else
          @pos += 1
        end
      end

      add_token(:heredoc_line, string_start, @pos - 1) if @pos > string_start
    end

    def parse_string_single
      start_pos = @pos
      @pos += 1 # skip opening quote

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
      @last_significant_token = :string
    end

    def parse_symbol
      start_pos = @pos
      @pos += 1 # skip ':'

      if @pos < @input.length
        if @input[@pos] == '"'
          # Double-quoted symbol like :"foo #{bar}" - supports interpolation
          # Emit the : and opening " as symbol token, then handle like double-quoted string
          @pos += 1 # skip "
          add_token(:symbol, start_pos, @pos - 1)
          @stack << Frame.new(:string_double)
          continue_string_double(@pos)
          return
        elsif @input[@pos] == "'"
          # Single-quoted symbol like :'foo bar' - no interpolation
          quote = @input[@pos]
          @pos += 1
          while @pos < @input.length && @input[@pos] != quote
            if @input[@pos] == '\\'
              @pos += 2
            else
              @pos += 1
            end
          end
          @pos += 1 if @pos < @input.length # skip closing quote
        else
          # Regular symbol like :foo
          @pos += 1 while @pos < @input.length && identifier_char?(@input[@pos])
        end
      end

      add_token(:symbol, start_pos, @pos - 1)
    end

    def parse_operator
      op = find_operator(@input[@pos..])

      token_type = op == '->' ? :lambda : :operator
      add_token(token_type, @pos, @pos + op.length - 1)
      @pos += op.length

      # Endless method detection: def foo(x) = expr
      @endless_method_possible = false if op == ';'
      if op == '=' && @endless_method_possible && @stack.last&.type == :def
        @stack.pop
        @endless_method_possible = false
      end

      # Handle bracket frame push/pop

      case op
      when '['
        @stack << Frame.new(:array, 0)
        @last_significant_token = :bracket_open
      when ']'
        pop_bracket_frame(:array)
        @last_significant_token = :bracket_close
      when '{'
        @stack << Frame.new(:hash, 0)
        @last_significant_token = :brace_open
      when '('
        @stack << Frame.new(:paren, 0)
        @last_significant_token = :paren_open
      when ')'
        pop_bracket_frame(:paren)
        @last_significant_token = :paren_close
      else
        update_last_significant_token(op)
      end
    end

    def parse_identifier
      start_pos = @pos
      first_char = @input[@pos]

      @pos += 1 while @pos < @input.length && identifier_char?(@input[@pos])

      value = @input[start_pos..@pos - 1]

      # Determine token type: constant (starts with uppercase), keyword, or identifier
      token_type = if value == 'BEGIN' || value == 'END'
                     :keyword
                   elsif first_char >= 'A' && first_char <= 'Z'
                     :constant
                   elsif KEYWORDS.include?(value)
                     :keyword
                   else
                     :identifier
                   end

      add_token(token_type, start_pos, @pos - 1)

      # Handle keyword frames (only when not inside string/interpolation/bracket)
      if token_type == :keyword && !inside_string_or_interpolation? && !inside_bracket_frame?
        handle_keyword_frame(value)
      end

      # Track token type for hash vs block detection and regex disambiguation
      if token_type == :identifier || token_type == :constant
        @prev_significant_token = @last_significant_token
        @last_significant_token = :identifier
      elsif token_type == :keyword
        @prev_significant_token = @last_significant_token
        case value
        when 'self', 'true', 'false', 'nil', 'end'
          @last_significant_token = :keyword_value
        else
          @last_significant_token = :keyword
        end
      end
    end

    def parse_instance_or_class_variable
      start_pos = @pos
      @pos += 1 # skip first @

      # Check for class variable (@@)
      type = :ivar
      if @pos < @input.length && @input[@pos] == '@'
        type = :cvar
        @pos += 1 # skip second @
      end

      # Read identifier part
      while @pos < @input.length && identifier_char?(@input[@pos])
        @pos += 1
      end

      add_token(type, start_pos, @pos - 1)
      @last_significant_token = type
    end

    def parse_global
      start_pos = @pos
      @pos += 1 # skip $

      if @pos < @input.length
        char = @input[@pos]
        # Special globals like $$, $!, $?, $0-$9, etc.
        if global?(char)
          @pos += 1
        elsif identifier_start?(char)
          # Regular global like $gtk, $my_var
          while @pos < @input.length && identifier_char?(@input[@pos])
            @pos += 1
          end
        end
      end

      add_token(:global, start_pos, @pos - 1)
      @last_significant_token = :global
    end

    def parse_character_literal_or_operator
      # ?a is a character literal when ? is followed immediately by a char (no space).
      # x ? y : z is ternary when ? is followed by whitespace.
      if @pos + 1 < @input.length && !whitespace?(@input[@pos + 1])
        # Could be character literal - check previous token to disambiguate
        # After identifier, number, ), ] it's ternary; otherwise character literal
        prev = @last_significant_token
        if prev == :identifier || prev == :number || prev == :paren_close || prev == :bracket_close
          parse_operator
        else
          parse_character_literal
        end
      else
        parse_operator
      end
    end

    def parse_character_literal
      start_pos = @pos
      @pos += 1 # skip ?
      if @pos < @input.length
        if @input[@pos] == '\\'
          @pos += 2 # escape sequence like ?\n
        else
          @pos += 1 # single char like ?a
        end
      end
      add_token(:string, start_pos, @pos - 1)
    end

    def regex_start_context?
      # / is a regex when preceded by operators, keywords, or at start of expression
      # / is division after identifiers, numbers, closing brackets, value-producing keywords
      case @last_significant_token
      when :identifier, :number, :paren_close, :bracket_close, :keyword_value, :ivar, :cvar, :global, :string, :symbol
        false
      else
        true
      end
    end

    def start_regex
      @stack << Frame.new(:regex)
      start_pos = @pos
      @pos += 1 # skip opening /
      continue_regex(start_pos)
    end

    def continue_regex(string_start)
      while @pos < @input.length
        char = @input[@pos]

        if char == '\\'
          @pos += 2
        elsif char == '#' && @pos + 1 < @input.length && @input[@pos + 1] == '{'
          add_token(:regex, string_start, @pos - 1) if @pos > string_start
          start_interpolation
          return
        elsif char == '/'
          # Closing delimiter - consume modifier flags (i, m, x, o, s, u, e, n)
          @pos += 1
          while @pos < @input.length && 'imxosuen'.include?(@input[@pos])
            @pos += 1
          end
          add_token(:regex, string_start, @pos - 1)
          @stack.pop
          return
        else
          @pos += 1
        end
      end

      # Incomplete regex
      add_token(:regex, string_start, @pos - 1) if @pos > string_start
    end

    def parse_percent_literal
      start_pos = @pos
      @pos += 1 # skip %

      return parse_operator if @pos >= @input.length

      # Get the type character (w, W, i, I, q, Q, r, s, x, etc.)
      type_char = @input[@pos]

      # Check if type_char is a valid percent literal type
      unless 'wWiIqQrsxl'.include?(type_char)
        return parse_operator
      end

      @pos += 1

      return parse_operator if @pos >= @input.length

      # Get the delimiter
      delimiter = @input[@pos]
      closing_delimiter = case delimiter
                          when '[' then ']'
                          when '(' then ')'
                          when '{' then '}'
                          when '<' then '>'
                          else delimiter
                          end

      @pos += 1 # skip opening delimiter

      # Interpolating types get frame-based parsing; non-interpolating are single tokens
      if 'QWIxr'.include?(type_char)
        token_type = case type_char
                     when 'Q', 'r' then :string
                     when 'x' then :backtick
                     else :array_literal  # W, I
                     end
        @stack << Frame.new(:percent_interp, 0, closing_delimiter, token_type)
        continue_percent_interp(start_pos)
      else
        # Non-interpolating - consume as single token
        while @pos < @input.length
          if @input[@pos] == '\\'
            @pos += 2 # skip escape sequence
          elsif @input[@pos] == closing_delimiter
            @pos += 1 # include closing delimiter
            break
          else
            @pos += 1
          end
        end

        token_type = case type_char
                     when 'q' then :string
                     when 's' then :symbol
                     else :array_literal  # w, i
                     end

        add_token(token_type, start_pos, @pos - 1)
      end
    end

    def add_token(type, start_pos, end_pos)
      value = @input[start_pos..end_pos]
      @tokens << { type: type, value: value, start: start_pos, end: end_pos }

      # Track non-whitespace tokens
      @seen_non_whitespace = true unless type == :whitespace
    end

    def modifier_keyword?(keyword)
      # Modifier keywords appear after other tokens on the same line
      # Block keywords appear at line start (possibly after whitespace)
      # Check if there are non-whitespace tokens before this keyword
      # (the keyword token has already been added to @tokens, so check all tokens except the last)
      @tokens[0..-2].any? { |t| t[:type] != :whitespace }
    end

    # Helper methods for keyword frame management

    def handle_keyword_frame(keyword)
      # Handle special keywords that don't start/end frames
      # TODO: actually, these should pop the existing frame and push a new one
      case keyword
      when 'elsif', 'else'
        # These continue the current if/unless/case frame, don't push/pop
        return
      when 'when'
        # Continues case frame
        return
      when 'rescue', 'ensure'
        # Continues begin frame
        return
      when 'then'
        # Optional part of if/case/when, ignore
        return
      end

      # Handle the keyword to push a new frame (or pop for 'end')
      # TODO: for syntax hghlighting i don't care about the name on the frame
      case keyword
      when 'def'
        # Peek ahead to get method name
        method_name = peek_next_identifier
        @stack << Frame.new(:def, 0, method_name)
        @endless_method_possible = true
      when 'class'
        # Peek ahead to get class name
        class_name = peek_next_constant
        @stack << Frame.new(:class, 0, class_name)
      when 'module'
        # Peek ahead to get module name
        module_name = peek_next_constant
        @stack << Frame.new(:module, 0, module_name)
      when 'if'
        return if modifier_keyword?(keyword)
        @stack << Frame.new(:if, 0)
      when 'unless'
        return if modifier_keyword?(keyword)
        @stack << Frame.new(:unless, 0)
      when 'case'
        @stack << Frame.new(:case, 0)
      when 'while'
        return if modifier_keyword?(keyword)
        @stack << Frame.new(:while, 0)
      when 'until'
        return if modifier_keyword?(keyword)
        @stack << Frame.new(:until, 0)
      when 'for'
        @stack << Frame.new(:for, 0)
      when 'begin'
        @stack << Frame.new(:begin, 0)
      when 'do'
        # Check if preceded by `lambda` to push :lambda frame
        prev_token = @tokens[0..-2].reverse.find { |t| t[:type] != :whitespace }
        if prev_token && prev_token[:value] == 'lambda'
          @stack << Frame.new(:lambda, 0)
        else
          @stack << Frame.new(:do_block, 0)
        end
      when 'end'
        pop_end_frame
      end
    end

    def peek_next_identifier
      # Skip whitespace to find next identifier
      saved_pos = @pos
      @pos += 1 while @pos < @input.length && whitespace?(@input[@pos])

      return nil if @pos >= @input.length

      # Check if next token is an identifier
      if identifier_start?(@input[@pos])
        start_pos = @pos
        @pos += 1 while @pos < @input.length && identifier_char?(@input[@pos])
        name = @input[start_pos..@pos - 1]
        @pos = saved_pos  # Restore position
        return name
      end

      @pos = saved_pos  # Restore position
      nil
    end

    def peek_next_constant
      # Skip whitespace to find next constant
      saved_pos = @pos
      @pos += 1 while @pos < @input.length && whitespace?(@input[@pos])

      return nil if @pos >= @input.length

      # Check if next token is a constant (starts with uppercase)
      char = @input[@pos]
      if char >= 'A' && char <= 'Z'
        start_pos = @pos
        @pos += 1 while @pos < @input.length && identifier_char?(@input[@pos])
        name = @input[start_pos..@pos - 1]
        @pos = saved_pos  # Restore position
        return name
      end

      @pos = saved_pos  # Restore position
      nil
    end

    # TODO: add the elsif, rescue, ensure etc frames
    def pop_end_frame
      # Find topmost frame that expects 'end'
      return if @stack.empty?

      frame = @stack.last

      # Keywords that pair with 'end'
      end_keywords = [:def, :class, :module, :if, :unless, :case, :while, :until, :for, :do_block, :begin, :lambda]

      # TODO: this makes no sense
      if end_keywords.include?(frame.type)
        if frame.depth > 0
          frame.depth -= 1
        else
          @stack.pop
        end
      end
    end

    # Helper methods for bracket frame management

    def pop_bracket_frame(expected_type)
      while BRACKET_FRAMES.include?(@stack.last&.type)
        frame = @stack.pop
        return if frame.type == expected_type
      end
    end

    def pop_bracket_frame_smart
      # Pops either :hash or :do_block frame (for } closer)
      return unless @stack.last

      if [:hash, :do_block].include?(@stack.last.type)
        @stack.pop
      end
    end

    def parse_closing_brace
      case @stack.last&.type
      when :interpolation
        @stack.pop
        @tokens << { type: :interpolation_end, value: '}', start: @pos, end: @pos }
        @pos += 1
      when :hash
        @stack.pop
        @tokens << { type: :operator, value: '}', start: @pos, end: @pos }
        @pos += 1
      else
        # Graceful error recovery for mismatched or unexpected }
        @tokens << { type: :operator, value: '}', start: @pos, end: @pos }
        @pos += 1
      end
    end

    def block_context?
      # After identifier without parens, { is likely a block
      @last_significant_token == :identifier &&
        ![:paren_open, :comma, :bracket_open, :hash_rocket, :colon].include?(@prev_significant_token)
    end

    # TODO: Kill
    def inside_string_or_interpolation?
      return false if @stack.empty?
      [:string_double, :interpolation].include?(@stack.last.type)
    end

    def inside_bracket_frame?
      return false if @stack.empty?
      [:array, :hash, :paren].include?(@stack.last.type)
    end

    def heredoc_start?
      # After <<, check if what follows looks like a heredoc delimiter
      # Could be: <<DELIMITER, <<-DELIMITER, <<~DELIMITER
      # Could be quoted: <<"DELIMITER", <<'DELIMITER'
      pos = @pos + 2  # Skip <<

      # Check for - or ~ modifier
      if pos < @input.length && (@input[pos] == '-' || @input[pos] == '~')
        pos += 1
      end

      # Check for delimiter start
      return false if pos >= @input.length

      char = @input[pos]
      # Delimiter can start with letter, underscore, or quote
      identifier_start?(char) || char == '"' || char == "'"
    end

    def start_heredoc
      start_pos = @pos
      @pos += 2 # skip <<

      # Check for - or ~ modifier
      indent_modifier = nil
      if @pos < @input.length && (@input[@pos] == '-' || @input[@pos] == '~')
        indent_modifier = @input[@pos]
        @pos += 1
      end

      # Read delimiter
      delimiter = ''
      if @pos < @input.length && (@input[@pos] == '"' || @input[@pos] == "'")
        # Quoted delimiter
        quote = @input[@pos]
        @pos += 1
        while @pos < @input.length && @input[@pos] != quote
          delimiter += @input[@pos]
          @pos += 1
        end
        @pos += 1 if @pos < @input.length  # Skip closing quote
      else
        # Unquoted delimiter - read identifier characters only
        while @pos < @input.length && identifier_char?(@input[@pos])
          delimiter += @input[@pos]
          @pos += 1
        end
      end

      @stack << Frame.new(:heredoc, quote == "'" ? 0 : 1, delimiter, indent_modifier)

      # Token for heredoc start
      add_token(:heredoc_start, start_pos, @pos - 1)

      # Continue parsing the rest of this line normally (not as heredoc content)
      # Heredoc content only starts on the NEXT line
      # TODO: this could result in other frames being added, which would be a syntax error
      while @pos < @input.length
        start_parse
      end
    end

    def update_last_significant_token(op)
      @prev_significant_token = @last_significant_token

      case op
      when ',' then @last_significant_token = :comma
      when '=>' then @last_significant_token = :hash_rocket
      when ':' then @last_significant_token = :colon
      when '=' then @last_significant_token = :assignment
      when '.' then @last_significant_token = :dot
      else @last_significant_token = :operator
      end
    end
  end

  ParsedLine = Struct.new(:text, :tokens, :input_stack, :output_stack) do
    alias_method :stack, :output_stack
  end

  class Ruby
    attr_reader :lines, :dirty_from

    def initialize(input)
      stack = []
      @lines = input.lines.map do |line|
        input_stack = deep_copy_stack(stack)
        parser = RubyLine.new(line, stack).parse
        stack = parser.stack
        ParsedLine.new(line, parser.tokens, input_stack, deep_copy_stack(stack))
      end
      # Ensure at least one line for empty input
      if @lines.empty?
        parser = RubyLine.new('', []).parse
        @lines = [ParsedLine.new('', parser.tokens, [], deep_copy_stack(parser.stack))]
      end
      @dirty_from = nil
    end

    def dirty?
      !@dirty_from.nil?
    end

    def line_count
      @lines.length
    end

    def replace_lines(start, count, new_texts)
      # Determine input stack for first new line
      input_stack = start > 0 ? @lines[start - 1].output_stack : []

      # Save the input stack of the first unchanged line after the edit (if any)
      old_next = start + count
      old_next_input = old_next < @lines.length ? @lines[old_next].input_stack : nil

      # Parse each new line sequentially
      stack = input_stack
      new_parsed = new_texts.map do |text|
        is = deep_copy_stack(stack)
        parser = RubyLine.new(text, stack).parse
        stack = parser.stack
        ParsedLine.new(text, parser.tokens, is, deep_copy_stack(stack))
      end

      # Splice new ParsedLines into @lines
      @lines[start, count] = new_parsed

      # Determine if subsequent lines are dirty from this edit
      first_unchanged = start + new_parsed.length
      new_dirty = nil
      if first_unchanged < @lines.length
        last_output = new_parsed.empty? ? input_stack : new_parsed.last.output_stack
        unless stacks_equal?(last_output, old_next_input)
          new_dirty = first_unchanged
        end
      end

      # Merge with existing dirty_from
      # Adjust existing dirty_from for line count changes
      delta = new_texts.length - count
      if @dirty_from
        if @dirty_from >= old_next
          # Existing dirty was after the edit range - adjust for line count change
          @dirty_from += delta
        elsif @dirty_from >= start
          # Existing dirty was inside the edited range - it's been replaced
          @dirty_from = nil
        end
        # If before start, keep as-is
      end

      # Combine: take the earliest dirty
      if new_dirty
        @dirty_from = @dirty_from.nil? ? new_dirty : [@dirty_from, new_dirty].min
      end

      # Validate: check if dirty_from is actually dirty
      if @dirty_from && @dirty_from < @lines.length
        prev_output = @dirty_from > 0 ? @lines[@dirty_from - 1].output_stack : []
        @dirty_from = nil if stacks_equal?(prev_output, @lines[@dirty_from].input_stack)
      end
    end

    def reparse_next_line
      return false if @dirty_from.nil?
      if @dirty_from >= @lines.length
        @dirty_from = nil
        return false
      end

      line = @lines[@dirty_from]
      new_input = @dirty_from > 0 ? @lines[@dirty_from - 1].output_stack : []

      # Convergence check: if input stack hasn't changed, no need to reparse
      if stacks_equal?(new_input, line.input_stack)
        @dirty_from = nil
        return false
      end

      # Reparse the line
      old_output = line.output_stack
      parser = RubyLine.new(line.text, new_input).parse
      @lines[@dirty_from] = ParsedLine.new(
        line.text, parser.tokens,
        deep_copy_stack(new_input),
        deep_copy_stack(parser.stack)
      )

      # Check convergence
      if stacks_equal?(parser.stack, old_output)
        @dirty_from = nil
      else
        @dirty_from += 1
        @dirty_from = nil if @dirty_from >= @lines.length
      end

      dirty?
    end

    def mark_dirty!(from = 0)
      from = [[from, 0].max, @lines.length - 1].min
      @dirty_from = @dirty_from.nil? ? from : [from, @dirty_from].min
    end

    def reparse!
      while dirty?
        reparse_next_line
      end
    end

    private

    def deep_copy_stack(stack)
      stack.map { |f| RubyLine::Frame.new(f.type, f.depth, f.name, f.modifier) }
    end

    def stacks_equal?(a, b)
      return true if a.equal?(b)
      return false unless a.length == b.length

      a.length.times do |i|
        fa = a[i]
        fb = b[i]
        return false unless fa.type == fb.type && fa.depth == fb.depth && fa.name == fb.name && fa.modifier == fb.modifier
      end
      true
    end
  end
end
