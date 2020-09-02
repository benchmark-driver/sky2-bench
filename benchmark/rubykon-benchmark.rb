require_relative 'rubykon/lib/rubykon'

iterations = 1_000
t = Time.now

game_state_19 = Rubykon::GameState.new Rubykon::Game.new(19)
mcts = MCTS::MCTS.new
mcts.start game_state_19, iterations

p(iterations / (Time.now - t))
