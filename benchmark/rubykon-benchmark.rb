require_relative 'rubykon/lib/rubykon'

t = Time.now

game_state_19 = Rubykon::GameState.new Rubykon::Game.new(19)
mcts = MCTS::MCTS.new
mcts.start game_state_19, 1_000

p Time.now - t
