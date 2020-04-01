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

  def get_inputs
    self.name = ask('What is the game name?')
    self.outstanding_work_cycles = ask_i('How many work cycles do you want to run?',
                                         default: 1)
    sim.set_miner_count ask_i('How many miners should we have?',
                              default: sim.get_miner_count)
    sim.set_processor_count ask_i('How many processors should we have?',
                                  default: sim.get_processor_count)
    sim.set_seller_count ask_i('How many sellers should we have?',
                               default: sim.get_seller_count)
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

GameData = Struct.new(:credits, :mine_product,
                      :miner_count, :miner_product,
                      :processor_count, :processor_product,
                      :seller_count, :seller_product, keyword_init: true)

class Loader
  def load from: nil, to: nil
    if !File.exists? from
      puts "starting new game"
      return
    end

    puts "Loading saved game"
    game_data = GameData.new
    File.open(from, 'r') do |fh|
      JSON.load(fh.read).each do |k, v|
        game_data[k] = v
      end
    end

    to.credits = game_data.credits
    to.set_mine_product game_data.mine_product
    to.set_miner_count game_data.miner_count
    to.set_miner_product game_data.miner_product
    to.set_processor_count game_data.processor_count
    to.set_processor_product game_data.processor_product
    to.set_seller_count game_data.seller_count
    to.set_seller_product game_data.seller_product
  end
end

class Saver
  def save to: nil, from: nil
    game_data = GameData.new
    game_data.credits = from.credits
    game_data.mine_product = from.get_mine_product
    game_data.miner_count = from.get_miner_count
    game_data.miner_product = from.get_miner_product
    game_data.processor_count = from.get_processor_count
    game_data.processor_product = from.get_processor_product
    game_data.seller_count = from.get_seller_count
    game_data.seller_product = from.get_seller_product

    puts "Saving game"
    File.open(to, 'w') do |fh|
      fh.write JSON.dump(game_data.to_h)
    end
  end
end

game = SaveGame.new
game.saver = Saver.new
game.loader = Loader.new
game.sim = Sim.new

game.get_inputs
game.load
game.output_reports
game.run_work
game.output_reports
game.save
