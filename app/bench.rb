require 'lib/parser.rb'

WHITESPACE_STR = " \t\n\r".freeze
WHITESPACE_CHARS = WHITESPACE_STR.chars.freeze
NUM_STR = '0123456789'.freeze
IDENTIFIER_STR = ((('a'..'z').to_a + ('A'..'Z').to_a).join + '_').freeze
CHARS = (WHITESPACE_CHARS + IDENTIFIER_STR.chars + NUM_STR.chars).freeze


def tick args
  if args.tick_count == 1
    # GTK.console.show
    GTK.benchmark iterations: 1_000_000,
      using_lt_gt: lambda {
        char = CHARS.sample
        (char >= 'a' && char <= 'z') ||
        (char >= 'A' && char <= 'Z') ||
        char == '_'
      },
      using_str_include: lambda {
        char = CHARS.sample
        IDENTIFIER_STR.include?(char)
      }
  end

  # *** using_str_include: total: 300ms, perc: 0% slower, diff: 0ms.
  # *** using_lt_gt: total: 431ms, perc: 44% slower, diff: 131ms.
end

# def tick args
#   if args.tick_count == 1
#     # GTK.console.show
#     GTK.benchmark iterations: 1_000_000,
#       using_lt_gt: lambda {
#         char = CHARS.sample
#         char >= '0' && char <= '9'
#       },
#       using_str_include: lambda {
#         char = CHARS.sample
#         NUM_STR.include?(char)
#       }
#   end

#   # *** using_str_include: total: 278ms, perc: 0% slower, diff: 0ms.
#   # *** using_lt_gt: total: 370ms, perc: 33% slower, diff: 92ms.
# end

# def tick args
#   if args.tick_count == 1
#     # GTK.console.show
#     GTK.benchmark iterations: 1_000_000,
#       using_equals: lambda {
#         char = CHARS.sample
#         char == ' ' || char == "\t" || char == "\n" || char == "\r"
#       },
#       using_str_include: lambda {
#         char = CHARS.sample
#         WHITESPACE_STR.include?(char)
#       },
#       using_arr_include: lambda {
#         char = CHARS.sample
#         WHITESPACE_CHARS.include?(char)
#       }

#     # *** using_str_include: total: 276ms, perc: 0% slower, diff: 0ms.
#     # *** using_equals: total: 397ms, perc: 44% slower, diff: 121ms.
#     # *** using_arr_include: total: 844ms, perc: 206% slower, diff: 568ms.
#   end
# end
