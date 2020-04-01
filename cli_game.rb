require_relative 'sim'

def ask_i question, default: 0
  print question + "[#{default}]: "
  answer = gets.chomp
  answer.empty? ? default : answer.to_i
end

class CliGame
  attr_accessor :sim, :outstanding_cycles

  def initialize
    self.outstanding_cycles = 0
  end

  def set_inputs
    sim.set_miner_count ask_i('How many miners should we have?',
                              default: sim.get_miner_count)
    sim.set_processor_count ask_i('How many processors should we have?',
                                  default: sim.get_processor_count)
    sim.set_seller_count ask_i('How many sellers should we have?',
                               default: sim.get_seller_count)
    self.outstanding_cycles = ask_i('How many cycles should we run?', default: 1)
  end

  def run_work_cycle
    outstanding_cycles.times do
      sim.run_work_cycle()
    end
    outstanding_cycles = 0
  end

  def output_report
    puts '-' * 50
    puts "remaining to be mined: #{sim.get_mine_product}"
    puts "mined resources[#{sim.get_miner_count}]: #{sim.get_miner_product}"
    puts "processed resouces[#{sim.get_processor_count}]: #{sim.get_processor_product}"
    puts "sellers[#{sim.get_seller_count}]"
    puts "credits earned: #{sim.get_earned}"
    puts '-' * 50
  end
end

game = CliGame.new
game.sim = Sim::Sim.new

loop do
  game.output_report()
  game.set_inputs()
  game.run_work_cycle()
end
