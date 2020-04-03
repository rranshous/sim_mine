module Sim
  class Runner
    def run_sim game_name: nil, sim_params: {}
      loader = HistoryLoader.new
      saver = HistorySaver.new
      sim = Sim.new
      data = loader.load from: save_path(game_name: game_name), to: sim
      if sim_params[:miner_count]
        sim.set_miner_count sim_params[:miner_count].to_i
      end
      if sim_params[:processor_count]
        sim.set_processor_count sim_params[:processor_count].to_i
      end
      if sim_params[:seller_count]
        sim.set_seller_count sim_params[:seller_count].to_i
      end
      previous_sim_data = nil
      current_sim_data = saver.create_data from: sim
      current_sim_data.last_work_timestamp = data.last_work_timestamp
      current_sim_data.save_timestamp = data.save_timestamp
      file_path = save_path game_name: game_name
      last_work_timestamp = data.last_work_timestamp || data.save_timestamp
      missed_cycles = (Time.now.to_i - last_work_timestamp) / SECONDS_PER_CYCLE
      if sim.endstate?
        missed_cycles = 0
      end
      if missed_cycles == 0
        last_saved_data = loader.get_historical_data index: -1, from: file_path
        puts "last_saved_data: #{last_saved_data}"
        previous_sim_data = last_saved_data || current_sim_data
      else
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
      return OpenStruct.new(previous_sim_data: previous_sim_data,
                            current_sim_data: current_sim_data,
                            cycles_run: missed_cycles,
                            sim_endstate: sim.endstate?)
    end
  end
end
