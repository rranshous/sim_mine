module Sim
  class Saver
    def save to: nil, from: nil
      data = create_data from: from
      save_data to: to, data: data
    end

    def save_data to: nil, data: nil
      data.save_timestamp = Time.now.to_i
      File.open(to, 'w') do |fh|
        fh.write JSON.dump(data.to_h)
      end
      data
    end

    def create_data from: nil
      game_data = Data.new
      game_data.credits = from.credits
      game_data.mine_product = from.get_mine_product
      game_data.miner_count = from.get_miner_count
      game_data.miner_product = from.get_miner_product
      game_data.processor_count = from.get_processor_count
      game_data.processor_product = from.get_processor_product
      game_data.seller_count = from.get_seller_count
      game_data.seller_product = from.get_seller_product
      game_data
    end
  end
end
