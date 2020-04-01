module Sim
  class Saver
    def save to: nil, from: nil
      game_data = Data.new
      game_data.credits = from.credits
      game_data.mine_product = from.get_mine_product
      game_data.miner_count = from.get_miner_count
      game_data.miner_product = from.get_miner_product
      game_data.processor_count = from.get_processor_count
      game_data.processor_product = from.get_processor_product
      game_data.seller_count = from.get_seller_count
      game_data.seller_product = from.get_seller_product
      game_data.save_timestamp = Time.now.to_i

      puts "Saving game"
      File.open(to, 'w') do |fh|
        fh.write JSON.dump(game_data.to_h)
      end
    end
  end
end
