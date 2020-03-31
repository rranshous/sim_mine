module ProductMover
  def order from: nil, amt: 0
    from.produce to: self, amt: amt
  end

  def produce to: nil, amt: 0
    to_produce = [amt, available_product].min
    to.receive from: self, amt: to_produce
    self.product -= to_produce
  end

  def receive from: nil, amt: 0
    self.product += amt
  end

  def available_product
    product
  end
end

module Creditor
  def charge to: nil, amt: 0
    to.make_payment to: self, amt: amt
  end

  def make_payment to: nil, amt: 0
    to_pay = [available_credits, amt].min
    to.receive_payment from: self, amt: to_pay
    self.credits -= to_pay
    to_pay
  end

  def receive_payment from: nil, amt: 0
    self.credits += amt
  end

  def available_credits
    credits
  end
end

class Mine
  attr_accessor :product
  include ProductMover

  def initialize
    self.product = 0
  end

  def available_product
    [product, max_per_work].min
  end

  def max_per_work
    10
  end
end

class Crew
  include ProductMover
  include Creditor

  attr_accessor :source, :size, :product

  def initialize
    self.size = 0
    self.product = 0
  end

  def do_work sim: nil
    received = charge to: sim, amt: size
    order from: source, amt: received
  end

  def receive_payment from: nil, amt: 0
  end
end

class SellCrew < Crew
  include Creditor

  attr_accessor :credits

  def initialize
    super
    self.credits = 0
  end

  def do_work sim: nil
    super
    sell_product sim: sim
  end

  def sell_product sim: nil
    sell_amt = sell_price * product
    self.credits += sell_amt
    make_payment to: sim, amt: sell_amt
    self.product = 0
  end

  def sell_price
    10
  end
end

class Sim

  include Creditor

  attr_accessor :extraction_crew, :processing_crew, :sell_crew, :mine,
                :credits

  def initialize
    self.credits = 100
    self.mine = Mine.new
    self.mine.product = 100
    self.extraction_crew = Crew.new
    self.extraction_crew.size = 1
    self.extraction_crew.source = mine
    self.processing_crew = Crew.new
    self.processing_crew.source = extraction_crew
    self.processing_crew.size = 1
    self.sell_crew = SellCrew.new
    self.sell_crew.source = processing_crew
    self.sell_crew.size = 1
  end

  def run_work_cycle
    sell_crew.do_work sim: self
    processing_crew.do_work sim: self
    extraction_crew.do_work sim: self
  end


  def set_miner_count amt
    extraction_crew.size = amt
  end

  def get_miner_count
    extraction_crew.size
  end

  def get_miner_product
    extraction_crew.product
  end

  def set_processor_count amt
    processing_crew.size = amt
  end

  def get_processor_count
    processing_crew.size
  end

  def get_processor_product
    processing_crew.product
  end

  def set_seller_count amt
    sell_crew.size = amt
  end

  def get_seller_count
    sell_crew.size
  end

  def get_seller_product
    sell_crew.product
  end

  def get_mine_product
    mine.product
  end

  def get_earned
    credits
  end
  
end
