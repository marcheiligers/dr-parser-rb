module Parser
  module Util
    extend self

    # TODO: spaceship operator <=>, safe navigation &, stabby lambda ->
    OPERATORS = [
      '=>', '==', '!=', '<=', '>=', '<<', '>>', '&&', '||',
      '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~',
      '(', ')', '[', ']', '{', '}', ',', '.', ':', ';', '?'
    ].freeze

    KEYWORDS = %w[
      alias and begin break case class def defined?
      do else elsif end ensure false for if in
      module next nil not or redo rescue retry
      return self super then true undef unless until
      when while yield
    ].freeze

    WHITESPACE = " \t\n\r"
    NUMBER = '0123456789'.freeze
    IDENTIFIER = ((('a'..'z').to_a + ('A'..'Z').to_a).join + '_').freeze

    def whitespace?(char)
      WHITESPACE.include?(char)
    end

    def digit?(char)
      NUMBER.include?(char)
    end

    def identifier_start?(char)
      IDENTIFIER.include?(char)
    end

    def identifier_char?(char)
      identifier_start?(char) || digit?(char) || char == '?' || char == '!'
    end

    def operator_start?(char)
      OPERATORS.any? { |op| op[0] == char }
    end
  end
end
