# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **DragonRuby Game Toolkit** project. DragonRuby is a game engine that uses Ruby for game development, running on a tick-based game loop.

## Development Commands

### Running the game
```bash
./run
```
This navigates to the parent directory and executes `./dragonruby dr-parse-rb`.

### Running tests
```bash
./test [test_file]
```
- Without arguments: runs all tests in `tests/tests.rb`
- With argument: runs specific test file (automatically prefixes with `tests/` and appends `.rb` if needed)
- Tests run with `SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy` for headless execution
- Uses flags: `--test <file> --no-tick`

### Publishing
```bash
./publish
```
Cleans game state files and runs `dragonruby-publish` for packaging the game.

## Project Structure

- **app/main.rb** - Main game loop; contains the `tick` method called every frame (~60fps)
- **app/repl.rb** - REPL/experimentation file for running Ruby code snippets; code executes once on save
- **metadata/** - Game configuration and assets
  - `game_metadata.txt` - Publishing configuration (game ID, version, orientation, rendering settings)
  - `icon.png` - Game icon
- **sprites/** - Image assets
- **sounds/** - Audio assets
- **fonts/** - Font files
- **data/** - Game data files

## DragonRuby Architecture

### The tick method
The core of every DragonRuby game is the `tick` method in `app/main.rb`:
- Called 60 times per second
- Receives `args` object containing game state, inputs, and outputs
- `args.state` - Persistent game state (survives across ticks)
- `args.inputs` - Keyboard, mouse, controller inputs
- `args.outputs` - Rendering targets (labels, sprites, primitives)

### State management
- Use `args.state.variable_name ||= value` pattern to initialize state variables
- State persists between ticks automatically
- All state is in-memory; use file I/O for persistence

### Rendering
DragonRuby uses hash-based rendering:
- Labels: `args.outputs.labels << { x:, y:, text:, size_px:, anchor_x:, anchor_y: }`
- Sprites: `args.outputs.sprites << { x:, y:, w:, h:, path: }`
- Coordinate system: (0,0) is bottom-left, default resolution is 1280x720

### REPL workflow
Code in `app/repl.rb` executes once when saved. Use `repl do ... end` blocks (or `xrepl` to disable) for experimentation.

## Testing Framework

### Test Structure
- Tests are located in `tests/` directory
- `tests/tests.rb` is the main entry point that requires all test files
- Individual test files follow the pattern `test_*.rb`
- Each test file should `require_relative 'test_helpers'` if using shared helpers

### Writing Tests
Test functions follow this signature:
```ruby
def test_function_name(_args, assert)
  assert.equal! actual, expected, "Optional error message"
  assert.true! condition, "Optional error message"
  assert.false! condition, "Optional error message"
end
```

Key points:
- Test functions must start with `test_`
- First parameter is `_args` (DragonRuby args object, usually unused in tests)
- Second parameter is `assert` object with assertion methods
- Use `assert.equal!`, `assert.true!`, `assert.false!` for assertions
- Error messages are optional but helpful for debugging

### Test Helpers
Create reusable test helpers in `tests/test_helpers.rb`:
- Build test objects with predefined state
- Create assertion helpers for complex validations
- Share common test utilities across test files

### Running Tests
```bash
./test                    # Run all tests
./test test_parser        # Run specific test file
```

## Development Notes

- The parent directory contains the DragonRuby engine executables
- Hot-reloading is enabled - changes to Ruby files reload automatically
- Game coordinates use bottom-left origin (not top-left like many frameworks)
- Default resolution is 1280x720 (landscape)
- **No regex support** - DragonRuby uses mruby which doesn't include regex
- Library code should be placed in `lib/` directory
