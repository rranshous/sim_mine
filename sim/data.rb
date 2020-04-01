module Sim
  Data = Struct.new(:save_timestamp, :credits, :mine_product,
                    :miner_count, :miner_product,
                    :processor_count, :processor_product,
                    :seller_count, :seller_product, keyword_init: true)
end