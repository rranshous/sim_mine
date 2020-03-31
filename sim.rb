module Source
  def take from: nil, amt: 0
    from.give to: self, amt: amt
  end

  def give to: nil, amt: 0
    to_give = [amt, product].min
    self.product -= to_give
    to.receive amt: to_give
  end
end

class Mine
  attr_accessor :product
  include Source
end

class Crew
  include Source

  attr_accessor :source, :size, :product

  def initialize
    self.size = 0
    self.product = 0
  end

  def do_work
    take from: source, amt: size
  end

  def receive amt: 0
    self.product += amt
  end
end

class Sim

  attr_accessor :extraction_crew, :processing_crew, :sell_crew, :mine

  def initialize
    self.mine = Mine.new
    self.mine.product = 100
    self.extraction_crew = Crew.new
    self.extraction_crew.size = 1
    self.extraction_crew.source = mine
    self.processing_crew = Crew.new
    self.processing_crew.source = extraction_crew
    self.processing_crew.size = 1
    self.sell_crew = Crew.new
    self.sell_crew.source = processing_crew
    self.sell_crew.size = 1
  end

  def run_work_cycle
    extraction_crew.do_work
    processing_crew.do_work
    sell_crew.do_work
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
  
end
