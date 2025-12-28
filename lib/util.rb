module Parser
  module Util
    extend self

    # TODO: spaceship operator <=>, safe navigation &, stabby lambda ->
    OPERATORS_3 = ['<=>'].freeze
    OPERATORS_2 = ['=>', '==', '!=', '<=', '>=', '<<', '>>', '&&', '||'].freeze
    OPERATORS_1 = [
      '+', '-', '*', '/', '%', '=', '<', '>', '!', '&', '|', '^', '~',
      '(', ')', '[', ']', '{', '}', ',', '.', ':', ';', '?'
    ].freeze
    OPERATORS_1_STR = OPERATORS_1.join.freeze

    KEYWORDS = %w[
      alias and begin break case class def defined?
      do else elsif end ensure false for if in
      module next nil not or redo rescue retry
      return self super then true undef unless until
      when while yield
    ].freeze

    WHITESPACE = " \t\n\r".freeze
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
      OPERATORS_1_STR.include?(char)
    end

    def find_operator(str)
      OPERATORS_3.find { _1 == str[0, 3] } ||
        OPERATORS_2.find { _1 == str[0, 2] } ||
        OPERATORS_1.find { _1 == str[0] }
    end
  end
end
