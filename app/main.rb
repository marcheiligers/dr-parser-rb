require 'lib/parser.rb'

COLORS = {
  keyword: { r: 197, g: 134, b: 192 },      # Purple
  string: { r: 152, g: 195, b: 121 },       # Green
  number: { r: 209, g: 154, b: 102 },       # Orange
  comment: { r: 92, g: 99, b: 112 },        # Gray
  symbol: { r: 86, g: 182, b: 194 },        # Cyan
  constant: { r: 229, g: 192, b: 123 },     # Yellow
  identifier: { r: 224, g: 224, b: 224 },   # White
  operator: { r: 171, g: 178, b: 191 },     # Light gray
  global: { r: 224, g: 108, b: 117 },       # Red
  interpolation_start: { r: 152, g: 195, b: 121 },  # Green
  interpolation_end: { r: 152, g: 195, b: 121 },    # Green
  array_literal: { r: 152, g: 195, b: 121 }, # Green
  heredoc_start: { r: 152, g: 195, b: 121 },  # Green
  heredoc_line: { r: 152, g: 195, b: 121 },   # Green
  heredoc_end: { r: 152, g: 195, b: 121 }     # Green
}

SAMPLE_CODE = <<~RUBYCODE.freeze
  class DragonGame
    PLAYER = 'player'

    def tick(args)
      if args.state.tick_count == 0
        args.state.message = <<~TEXT.capitalize # screaming
          Welcome to DragonRuby!
        TEXT
        args.state.player = {
          x: 640, y: 360,
          sprite: "sprites/\#{PLAYER}.png"
        }
      end

      player = args.state.player
      player.x += 5 if args.inputs.right

      args.outputs.sprites << player
    end
  end
RUBYCODE

def tick args
  # Set background color (dark theme)
  args.outputs.background_color = [40, 44, 52]

  # Title
  args.outputs.labels << {
    x: 640,
    y: 700,
    text: 'Multiline Ruby Parser Demo',
    size_px: 24,
    alignment_enum: 1,
    r: 200, g: 200, b: 200
  }

  # Subtitle
  args.outputs.labels << {
    x: 640,
    y: 670,
    text: 'Stack-based parsing with heredocs, classes, methods, control flow & more!',
    size_px: 14,
    alignment_enum: 1,
    r: 150, g: 150, b: 150
  }

  # Divider line
  args.outputs.lines << {
    x: 640, y: 0,
    x2: 640, y2: 720,
    r: 80, g: 80, b: 80
  }

  # LEFT HALF: Syntax-highlighted code
  y = 630
  line_height = 22
  x_left = 30
  size = 16

  parser = RubyParser.new(SAMPLE_CODE)

  # Render code lines
  parser.lines.each do |line|
    x_offset = x_left
    line.tokens.each do |token|
      color = COLORS[token[:type]] || { r: 255, g: 255, b: 255 }

      args.outputs.labels << {
        x: x_offset,
        y: y,
        text: token[:value],
        size_px: size,
        **color
      }

      # Calculate the exact width of this token
      width, _ = $gtk.calcstringbox(token[:value], size_px: size)
      x_offset += width
    end

    # Show stack state on the right edge of left half
    unless line.stack.empty?
      stack_text = line.stack.map(&:type).join(', ')
      args.outputs.labels << {
        x: 600,
        y: y,
        text: "[#{stack_text}]",
        size_px: 10,
        alignment_enum: 2,
        r: 200, g: 200, b: 200
      }
    end

    y -= line_height
  end

  # RIGHT HALF: Token breakdown and stats
  y_right = 630
  x_right = 670

  args.outputs.labels << {
    x: x_right,
    y: y_right,
    text: 'Token Breakdown',
    size_px: 18,
    r: 200, g: 200, b: 200
  }

  y_right -= 30

  # Collect all tokens
  all_tokens_flat = parser.lines.flat_map { |line| line.tokens }
  token_types = all_tokens_flat.map { |t| t[:type] }.uniq.sort

  token_types.each do |type|
    count = all_tokens_flat.count { |t| t[:type] == type }
    color = COLORS[type] || { r: 255, g: 255, b: 255 }

    args.outputs.labels << {
      x: x_right,
      y: y_right,
      text: "#{type}: #{count}",
      size_px: 14,
      **color
    }
    y_right -= 22
  end

  # Stats section
  y_right -= 20
  args.outputs.labels << {
    x: x_right,
    y: y_right,
    text: 'Parser Stats',
    size_px: 18,
    r: 200, g: 200, b: 200
  }

  y_right -= 30
  stats = [
    "Total lines: #{parser.lines.length}",
    "Total tokens: #{all_tokens_flat.length}",
    "Max stack depth: #{parser.lines.map { |l| l.stack.length }.max || 0}"
  ]

  stats.each do |stat|
    args.outputs.labels << {
      x: x_right,
      y: y_right,
      text: stat,
      size_px: 14,
      r: 180, g: 180, b: 180
    }
    y_right -= 22
  end

  # Footer
  args.outputs.labels << {
    x: 640,
    y: 20,
    text: 'dr-parser-rb 0.0.1 - 154 tests passing',
    size_px: 14,
    alignment_enum: 1,
    r: 150, g: 150, b: 150
  }
end
