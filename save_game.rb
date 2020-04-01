require_relative 'sim'

require 'json'

def ask question, default: nil 
  unless default.nil?
    question += "[#{default}]"
  end
  print question + ": "
  answer = gets.chomp
  answer.empty? ? default : answer
end

def ask_i question, default: nil
  ask(question, default: default).to_i
end

class SaveGame
  attr_accessor :name, :outstanding_work_cycles, :saver, :loader, :sim

  def get_game_name
    self.name = ask('What is the game name?')
  end

  def get_inputs
    sim.set_miner_count ask_i('How many miners should we have?',
                              default: sim.get_miner_count)
    sim.set_processor_count ask_i('How many processors should we have?',
                                  default: sim.get_processor_count)
    sim.set_seller_count ask_i('How many sellers should we have?',
                               default: sim.get_seller_count)
    self.outstanding_work_cycles = ask_i('How many work cycles do you want to run?',
                                         default: 1)
  end

  def run_work
    outstanding_work_cycles.times do
      sim.run_work_cycle()
    end
    outstanding_work_cycles = 0
  end

  def output_reports
    puts '-' * 50
    puts "remaining to be mined: #{sim.get_mine_product}"
    puts "mined resources[#{sim.get_miner_count}]: #{sim.get_miner_product}"
    puts "processed resouces[#{sim.get_processor_count}]: #{sim.get_processor_product}"
    puts "sellers[#{sim.get_seller_count}]"
    puts "credits: #{sim.get_earned}"
    puts '-' * 50
  end

  def save
    saver.save to: save_name, from: sim
  end

  def load
    loader.load from: save_name, to: sim
  end

  def save_name
    "./saves/#{name}_save.json"
  end
end

game = SaveGame.new
game.saver = Sim::Saver.new
game.loader = Sim::Loader.new
game.sim = Sim::Sim.new

game.get_game_name
game.load
game.output_reports
game.get_inputs
game.run_work
game.output_reports
game.save
