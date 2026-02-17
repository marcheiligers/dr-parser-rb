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
  ivar: { r: 224, g: 108, b: 117 },         # Red
  cvar: { r: 224, g: 108, b: 117 },         # Red
  interpolation_start: { r: 86, g: 182, b: 194 },  # Cyan
  interpolation_end: { r: 86, g: 182, b: 194 },    # Cyan
  array_literal: { r: 152, g: 195, b: 121 }, # Green
  heredoc_start: { r: 152, g: 195, b: 121 },  # Green
  heredoc_line: { r: 152, g: 195, b: 121 },   # Green
  heredoc_end: { r: 152, g: 195, b: 121 },    # Green
  backtick: { r: 152, g: 195, b: 121 },       # Green
  regex: { r: 152, g: 195, b: 121 },          # Green
  lambda: { r: 197, g: 134, b: 192 }          # Purple
}

DEFAULT_COLOR = { r: 224, g: 224, b: 224 }

INITIAL_CODE = <<~CODE
class Demo
  def hello
    puts "world"
  end

  def add(a, b)
    a + b
  end
end
CODE

DEMO_CYCLE = 1320   # 22 seconds at 60fps
REPARSE_RATE = 6    # reparse one dirty line every 6 ticks

def tick(args)
  args.outputs.background_color = [40, 44, 52]

  args.state.edits ||= $gtk.parse_json_file('app/sample.json')

  demo_tick = args.state.tick_count % DEMO_CYCLE

  # Reset at cycle start
  if demo_tick == 0
    args.state.parser = Parser::Ruby.new(INITIAL_CODE)
    args.state.edit_index = 0
    args.state.status = 'Loaded initial code'
    args.state.status_tick = 0
  end

  parser = args.state.parser
  edits = args.state.edits

  # Apply scheduled edits
  while args.state.edit_index < edits.length
    edit = edits[args.state.edit_index]
    break if edit['tick'] > demo_tick
    parser.replace_lines(edit['start'], edit['count'], edit['lines'])
    args.state.status = edit['label']
    args.state.status_tick = demo_tick
    args.state.edit_index += 1
  end

  # Background reparse: one line every REPARSE_RATE ticks
  if demo_tick % REPARSE_RATE == 0 && parser.dirty?
    parser.reparse_next_line
  end

  render_all(args, parser, demo_tick)
end

def render_all(args, parser, demo_tick)
  # Title
  args.outputs.labels << {
    x: 640, y: 700,
    text: 'Incremental Parser Demo',
    size_px: 22, alignment_enum: 1,
    r: 200, g: 200, b: 200
  }

  # Subtitle
  args.outputs.labels << {
    x: 640, y: 674,
    text: 'Watch dirty lines propagate and converge',
    size_px: 13, alignment_enum: 1,
    r: 100, g: 100, b: 100
  }

  # Divider
  args.outputs.lines << { x: 620, y: 10, x2: 620, y2: 650, r: 60, g: 60, b: 60 }

  render_code(args, parser)
  render_status(args, parser, demo_tick)

  args.outputs.primitives << GTK.framerate_diagnostics_primitives
end

def render_code(args, parser)
  line_height = 24
  y_start = 636
  x_code = 55
  size = 14

  parser.lines.each_with_index do |line, i|
    y = y_start - (i * line_height)

    # Dirty line background
    if parser.dirty_from && i >= parser.dirty_from
      args.outputs.solids << {
        x: 38, y: y - 6, w: 572, h: line_height,
        r: 100, g: 30, b: 30, a: 140
      }
    end

    # Line number
    args.outputs.labels << {
      x: 18, y: y,
      text: (i + 1).to_s.rjust(2),
      size_px: 11,
      r: 70, g: 70, b: 70
    }

    # Render tokens
    x_offset = x_code
    line.tokens.each do |tok|
      display = tok[:value].chomp
      next if display.empty?

      w, _ = $gtk.calcstringbox(display, size_px: size)

      unless tok[:type] == :whitespace
        color = COLORS[tok[:type]] || DEFAULT_COLOR
        args.outputs.labels << {
          x: x_offset, y: y,
          text: display,
          size_px: size,
          **color
        }
      end

      x_offset += w
    end

    # Stack indicator
    unless line.stack.empty?
      stack_text = line.stack.map(&:type).join(', ')
      args.outputs.labels << {
        x: 608, y: y,
        text: "[#{stack_text}]",
        size_px: 9, alignment_enum: 2,
        r: 60, g: 60, b: 60
      }
    end
  end
end

def render_status(args, parser, demo_tick)
  x = 650
  y = 636
  gap = 26

  # Last action
  args.outputs.labels << {
    x: x, y: y,
    text: 'Last Action:',
    size_px: 14,
    r: 140, g: 140, b: 140
  }
  y -= 20

  status = args.state.status || ''
  age = demo_tick - (args.state.status_tick || 0)
  brightness = 220 - [[age, 120].min, 0].max
  args.outputs.labels << {
    x: x, y: y,
    text: status,
    size_px: 14,
    r: brightness, g: brightness, b: brightness
  }
  y -= gap + 8

  # Dirty state
  args.outputs.labels << {
    x: x, y: y,
    text: 'Parse State:',
    size_px: 14,
    r: 140, g: 140, b: 140
  }
  y -= 20

  if parser.dirty?
    args.outputs.labels << {
      x: x, y: y,
      text: "Dirty from line #{parser.dirty_from + 1}",
      size_px: 14,
      r: 224, g: 108, b: 117
    }
  else
    args.outputs.labels << {
      x: x, y: y,
      text: 'Clean (converged)',
      size_px: 14,
      r: 152, g: 195, b: 121
    }
  end
  y -= gap + 8

  # Stats
  args.outputs.labels << {
    x: x, y: y,
    text: 'Stats:',
    size_px: 14,
    r: 140, g: 140, b: 140
  }
  y -= 20

  total_tokens = parser.lines.inject(0) { |s, l| s + l.tokens.length }
  max_depth = parser.lines.map { |l| l.stack.length }.max || 0

  [
    "Lines: #{parser.line_count}",
    "Tokens: #{total_tokens}",
    "Max stack depth: #{max_depth}"
  ].each do |stat|
    args.outputs.labels << {
      x: x, y: y,
      text: stat,
      size_px: 14,
      r: 171, g: 178, b: 191
    }
    y -= 22
  end

  # Legend
  y -= 16
  args.outputs.labels << {
    x: x, y: y,
    text: 'Legend:',
    size_px: 14,
    r: 140, g: 140, b: 140
  }
  y -= 22
  args.outputs.solids << { x: x, y: y - 4, w: 14, h: 14, r: 100, g: 30, b: 30, a: 140 }
  args.outputs.labels << {
    x: x + 20, y: y,
    text: 'Needs reparse',
    size_px: 12,
    r: 120, g: 120, b: 120
  }

  # Progress
  y -= 36
  pct = (demo_tick * 100) / DEMO_CYCLE
  args.outputs.labels << {
    x: x, y: y,
    text: "Demo: #{pct}% (loops every #{DEMO_CYCLE / 60}s)",
    size_px: 11,
    r: 70, g: 70, b: 70
  }
end
