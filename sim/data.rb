module Sim
  Data = Struct.new(:last_work_timestamp, :save_timestamp,
                    :reached_endstate,
                    :credits, :mine_product,
                    :miner_count, :miner_product,
                    :processor_count, :processor_product,
                    :seller_count, :seller_product, keyword_init: true)
end
