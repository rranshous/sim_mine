require_relative '../sim'

class Runner
  def run_sim game_name: nil, sim_params: {}, file_path: nil
    loader = Sim::HistoryLoader.new
    saver = Sim::HistorySaver.new
    sim = Sim::Sim.new
    file_path ||= save_path game_name: game_name
    data = loader.load from: file_path, to: sim
    if update_config(sim, sim_params)
      to_save = saver.create_data from: sim
      copy_timestamps from: data, to: to_save
      saver.save_data data: to_save, to: file_path
    end
    previous_sim_data = nil
    current_sim_data = saver.create_data from: sim
    copy_timestamps from: data, to: current_sim_data
    next_run_in = calc_seconds_until_next_run loader: loader, file_path: file_path
    missed_cycles = calc_missed_cycles next_run_in: next_run_in
    if missed_cycles == 0 || sim.endstate?
      puts "SKIPPING RUN"
      last_data = previous_runs_data loader, file_path, current_sim_data
      previous_sim_data = last_data || current_sim_data
    else
      puts "RUNNING CYCLES: #{missed_cycles}"
      missed_cycles.times do
        unless sim.endstate?
          previous_sim_data = current_sim_data
          sim.run_work_cycle
          current_sim_data = saver.create_data from: sim
          current_sim_data.last_work_timestamp = Time.now.to_i
          saver.save_data data: current_sim_data, to: file_path
        end
      end
    end
    if sim.endstate?
      missed_cycles = 0
    end
    next_run_in = calc_seconds_until_next_run loader: loader, file_path: file_path
    return OpenStruct.new(previous_sim_data: previous_sim_data,
                          current_sim_data: current_sim_data,
                          cycles_run: missed_cycles,
                          sim_endstate: sim.endstate?,
                          next_run_in: next_run_in
                         )
  end

  def update_config sim, config
    did_update = false
    if config[:miner_count]
      sim.set_miner_count config[:miner_count].to_i
      did_update = true
    end
    if config[:processor_count]
      sim.set_processor_count config[:processor_count].to_i
      did_update = true
    end
    if config[:seller_count]
      sim.set_seller_count config[:seller_count].to_i
      did_update = true
    end
    did_update
  end

  def calc_seconds_until_next_run loader: nil, file_path: nil
    sim_data = loader.get_data from: file_path
    if sim_data.reached_endstate
      return nil
    end
    first_sim_data = nil
    if sim_data.last_work_timestamp.nil?
      first_sim_data = loader.get_historical_data index: 0, from: file_path
    end
    first_sim_data ||= sim_data
    last_work_timestamp = sim_data.last_work_timestamp || first_sim_data.save_timestamp
    last_work_timestamp + SECONDS_PER_CYCLE - Time.now.to_i
  end

  def calc_missed_cycles next_run_in: nil
    if next_run_in.nil? || next_run_in > 0
      return 0
    end
    (next_run_in.abs.to_f / SECONDS_PER_CYCLE).ceil
  end

  def copy_timestamps from: nil, to: nil
    to.last_work_timestamp = from.last_work_timestamp
    to.save_timestamp = from.save_timestamp
  end

  def previous_runs_data loader, file_path, current_sim_data
    -1.downto(-1000) do |i|
      saved_data = loader.get_historical_data index: i, from: file_path
      return nil if saved_data.nil?
      if saved_data.last_work_timestamp != current_sim_data.last_work_timestamp
        return saved_data
      end
    end
    nil
  end
end
