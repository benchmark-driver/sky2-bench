require_relative 'rubykon/lib/rubykon'

iterations = 1_000
t = Process.clock_gettime(Process::CLOCK_MONOTONIC)

game_state_19 = Rubykon::GameState.new Rubykon::Game.new(19)
mcts = MCTS::MCTS.new
mcts.start game_state_19, iterations

p(iterations / (Process.clock_gettime(Process::CLOCK_MONOTONIC) - t))
