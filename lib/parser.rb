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

    def initialize(input, stack = [])
      @input = input
      @pos = 0
      @tokens = []
      @stack = stack.dup
      @last_significant_token = nil
      @prev_significant_token = nil
      @seen_non_whitespace = false  # Track if we've seen non-whitespace on this line
    end

    def parse # continue_parse
      while @pos < @input.length
        if @stack.empty?
          start_parse
        else
          case @stack.last.type
            when :string_double then continue_string_double(@pos)
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
      return self if @input.nil? || @input.empty?

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
      elsif char == '%'
        parse_percent_literal
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
          @pos += 2 if @pos + 1 < @input.length
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
          return
        else
          @pos += 1
        end
      end

      # Incomplete string - emit what we have
      add_token(:string, string_start, @pos - 1) if @pos > string_start
    end

    def start_interpolation
      add_token(:interpolation_start, @pos, @pos + 1) # skip #{
      @pos += 2
      @stack << Frame.new(:interpolation, 1)
      start_parse
    end

    def continue_array
      while @pos < @input.length
        char = @input[@pos]

        case char
        when '['
          # TODO: emit new array frames
          @stack.last.depth += 1
          start_parse
        when ']'
          # TODO: pop array frames
          # Let parse_operator handle depth decrement and popping via pop_bracket_frame
          start_parse
          # Check if frame was popped (stack empty or different frame type)
          return if @stack.empty? || @stack.last.type != :array
        else
          start_parse
        end
      end
    end

    def continue_hash
      while @pos < @input.length
        char = @input[@pos]

        case char
        when '{'
          @stack.last.depth += 1
          start_parse
        when '}'
          # Let parse_operator handle depth decrement and popping via pop_bracket_frame_smart
          start_parse
          # Check if frame was popped (stack empty or different frame type)
          return if @stack.empty? || @stack.last.type != :hash
        else
          start_parse
        end
      end
    end

    def continue_paren
      while @pos < @input.length
        char = @input[@pos]

        case char
        when '('
          @stack.last.depth += 1
          start_parse
        when ')'
          # Let parse_operator handle depth decrement and popping via pop_bracket_frame
          start_parse
          # Check if frame was popped (stack empty or different frame type)
          return if @stack.empty? || @stack.last.type != :paren
        else
          start_parse
        end
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
    end

    def parse_symbol
      start_pos = @pos
      @pos += 1 # skip ':'

      # Symbol can be quoted or identifier-like
      if @pos < @input.length
        if @input[@pos] == '"' || @input[@pos] == "'"
          # Quoted symbol like :"foo bar"
          quote = @input[@pos]
          @pos += 1
          @pos += 1 while @pos < @input.length && @input[@pos] != quote
          @pos += 1 if @pos < @input.length # skip closing quote
        else
          # Regular symbol like :foo
          @pos += 1 while @pos < @input.length && identifier_char?(@input[@pos])
        end
      end

      add_token(:symbol, start_pos, @pos - 1)
    end

    # TODO: fix this method
    def parse_operator
      op = find_operator(@input[@pos..])

      add_token(:operator, @pos, @pos + op.length - 1)
      @pos += op.length

      # Handle bracket frame push/pop (only when not inside string/interpolation)
      # TODO: this method should never be called in a string.
      # TODO: for interpolation we should be pushing these.
      raise "This shouldn't be a string" if %i[string_double string_single].include?(@stack.last&.type)

      case op
      when '['
        # Only push if not already inside an array frame
        push_array_frame unless @stack.last&.type == :array
        @last_significant_token = :bracket_open
      when ']'
        pop_bracket_frame(:array)
      when '{'
        # Only push if not already inside a hash frame
        unless @stack.last&.type == :hash
          # TODO: block_context
          if block_context?
            # For Phase 3: push_block_frame
            # For now, treat as hash
            push_hash_frame
          else
            push_hash_frame
          end
        end
        @last_significant_token = :brace_open
      when '}'
        pop_bracket_frame_smart
      when '('
        # Only push if not already inside a paren frame
        push_paren_frame unless @stack.last&.type == :paren
        @last_significant_token = :paren_open
      when ')'
        pop_bracket_frame(:paren)
      else
        update_last_significant_token(op)
      end
      # else
      #   update_last_significant_token(char)
      # end
    end

    def parse_identifier
      start_pos = @pos
      first_char = @input[@pos]

      @pos += 1 while @pos < @input.length && identifier_char?(@input[@pos])

      value = @input[start_pos..@pos - 1]

      # Determine token type: constant (starts with uppercase), keyword, or identifier
      token_type = if first_char >= 'A' && first_char <= 'Z'
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

      # Track identifier for hash vs block detection
      if token_type == :identifier
        @prev_significant_token = @last_significant_token
        @last_significant_token = :identifier
      end
    end

    def parse_global
      start_pos = @pos
      @pos += 1  # skip $

      # Special globals like $$, $!, $?, $0-$9, etc.
      if @pos < @input.length
        char = @input[@pos]
        if char == '$' || char == '!' || char == '?' || char == '&' || char == '`' ||
           char == "'" || char == '+' || char == '~' || char == '=' || char == '/' ||
           char == '\\' || char == ',' || char == ';' || char == '.' || char == '<' ||
           char == '>' || char == '*' || char == '@' || char == ':' ||
           (char >= '0' && char <= '9')
          @pos += 1
        elsif identifier_start?(char)
          # Regular global like $gtk, $my_var
          while @pos < @input.length && identifier_char?(@input[@pos])
            @pos += 1
          end
        end
      end

      add_token(:global, start_pos, @pos - 1)
    end

    def parse_percent_literal
      start_pos = @pos
      @pos += 1 # skip %

      return parse_operator if @pos >= @input.length

      # Get the type character (w, W, i, I, q, Q, r, s, x, etc.)
      type_char = @input[@pos] # TODO: use type_char
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

      # Find the closing delimiter
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

      add_token(:array_literal, start_pos, @pos - 1)
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
        @stack << Frame.new(:do_block, 0)
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
      end_keywords = [:def, :class, :module, :if, :unless, :case, :while, :until, :for, :do_block, :begin]

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
    # TODO: inline and kill
    def push_array_frame
      @stack << Frame.new(:array, 1)
    end

    def push_hash_frame
      @stack << Frame.new(:hash, 1)
    end

    def push_paren_frame
      @stack << Frame.new(:paren, 1)
    end

    def pop_bracket_frame(expected_type)
      return unless @stack.last

      if @stack.last.type == expected_type
        @stack.last.depth -= 1
        @stack.pop if @stack.last.depth == 0
      end
    end

    def pop_bracket_frame_smart
      # Pops either :hash or :do_block frame (for } closer)
      return unless @stack.last

      if [:hash, :do_block].include?(@stack.last.type)
        @stack.last.depth -= 1
        @stack.pop if @stack.last.depth == 0
      end
    end

    # TODO: we'll also need closing_square ], and closing_paren )
    def parse_closing_brace
      case @stack.last&.type
      when :interpolation
        @stack.pop
        @tokens << { type: :interpolation_end, value: '}', start: @pos, end: @pos }
        @pos += 1
      when :hash
        @stack.pop
        # TODO: hash_end so we can colorize brackets
        @tokens << { type: :operator, value: '}', start: @pos, end: @pos }
        @pos += 1
      else
        # TODO: handle others (block, lambda)
        # TODO: error type
        raise "Unhandled closing type #{@stack.last&.type.inspect}"
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
        # interpolation_allowed = (quote == '"')  # NOW: remove Double-quoted allows interpolation, single doesn't
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

    def update_last_significant_token(char)
      @prev_significant_token = @last_significant_token

      case char
      when ',' then @last_significant_token = :comma
      when '=>' then @last_significant_token = :hash_rocket
      when ':' then @last_significant_token = :colon
      when '=' then @last_significant_token = :assignment
      when '.' then @last_significant_token = :dot
      else
        # Other operators don't affect hash vs block detection
      end
    end
  end

  class Ruby
    attr_reader :lines

    def initialize(input)
      stack = []
      @lines = input.lines.map do |line|
        # TODO: should i be stripping new lines off of this?
        parser = RubyLine.new(line, stack).parse
        stack = parser.stack
        parser
      end
    end
  end
end
