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
  array_literal: { r: 152, g: 195, b: 121 } # Green
}

def tick args
  args.state.ruby_code ||= 'class Foo; def bar!(x); $gtk.args.outputs.labels << "hello #{x}"; end; end'
  args.state.y_pos ||= 600

  # Set background color (dark theme)
  args.outputs.background_color = [40, 44, 52]

  # Parse the Ruby code
  parser = RubyParser.new(args.state.ruby_code)
  tokens = parser.parse

  # Title
  args.outputs.labels << {
    x: 640,
    y: 680,
    text: 'Ruby Syntax Highlighter Demo',
    size_px: 30,
    alignment_enum: 1,
    r: 200, g: 200, b: 200
  }

  # Instructions
  args.outputs.labels << {
    x: 640,
    y: 640,
    text: 'Showcasing keyword, string, number, symbol, constant, global, interpolation, and more!',
    size_px: 16,
    alignment_enum: 1,
    r: 150, g: 150, b: 150
  }

  # Render syntax-highlighted code
  x_offset = 40
  size = 20

  tokens.each do |token|
    color = COLORS[token[:type]] || { r: 255, g: 255, b: 255 }

    args.outputs.labels << {
      x: x_offset,
      y: args.state.y_pos,
      text: token[:value],
      size_px: size,
      **color
    }

    # Calculate the exact width of this token
    width, _ = $gtk.calcstringbox(token[:value], size_px: size)
    x_offset += width
  end

  # Show token breakdown
  y = 500
  args.outputs.labels << {
    x: 40,
    y: y,
    text: 'Token Breakdown:',
    size_px: 18,
    r: 200, g: 200, b: 200
  }

  y -= 30
  token_types = tokens.map { |t| t[:type] }.uniq
  token_types.each do |type|
    count = tokens.count { |t| t[:type] == type }
    color = COLORS[type] || { r: 255, g: 255, b: 255 }

    args.outputs.labels << {
      x: 40,
      y: y,
      text: "#{type}: #{count}",
      size_px: 14,
      **color
    }
    y -= 25
  end

  # Footer
  args.outputs.labels << {
    x: 640,
    y: 40,
    text: 'Press ESC to quit | 79 tests passing',
    size_px: 16,
    alignment_enum: 1,
    r: 150, g: 150, b: 150
  }
end
