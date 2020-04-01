module Sim
  class Loader
    def load from: nil, to: nil
      if !File.exists? from
        puts "starting new game"
        return
      end

      puts "Loading saved game"
      game_data = Data.new
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
end
