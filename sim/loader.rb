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
      populate_sim from: game_data, to: to
      game_data
    end

    def populate_sim from: nil, to: nil
      to.credits = from.credits
      to.set_mine_product from.mine_product
      to.set_miner_count from.miner_count
      to.set_miner_product from.miner_product
      to.set_processor_count from.processor_count
      to.set_processor_product from.processor_product
      to.set_seller_count from.seller_count
      to.set_seller_product from.seller_product
    end

    def get_data from: nil
      if !File.exists? from
        return nil
      end

      puts "Loading saved game: #{from}"
      game_data = Data.new
      File.open(from, 'r') do |fh|
        JSON.load(fh.read).each do |k, v|
          game_data[k] = v
        end
      end
      game_data
    end
  end
end
