require 'sinatra'
require "sinatra/json"
require 'json'
require_relative '../sim'

SECONDS_PER_CYCLE = 30

# HTML
get '/game/' do
  erb :game_index
end

get '/game/:game_name' do |game_name|
  @game_name = game_name
  erb :game_view
end

# JSON
post '/api/game' do
  post_data = JSON.parse request.body.read
  game_name = post_data['gameName']
  log "creating game: #{game_name}"
  sim = Sim::Sim.new
  saver = Sim::Saver.new
  saver.save to: save_path(game_name: game_name), from: sim
  redirect "/api/game/#{game_name}", 201
end

get '/api/game/:game_name' do |game_name|
  log "getting #{game_name}"
  run_details = run_sim game_name: game_name
  json({
    game_name: game_name,
    missed_cycles: 0, cycles_run: run_details.cycles_run,
    current_sim_data: run_details.current_sim_data.to_h,
    previous_sim_data: run_details.previous_sim_data.to_h
  })
end

post '/api/game/:game_name/update_params' do |game_name|
  body = request.body.read
  post_data = body != '' ? JSON.parse(body) : {}
  log "post_data: #{post_data}" unless post_data.empty?
  sim_params = {}
  if post_data['minerCount']
    sim_params[:miner_count] = post_data['minerCount'].to_i
    log "updating sim miner count: #{sim_params[:miner_count]}"
  end
  if post_data['processorCount']
    sim_params[:processor_count] = post_data['processorCount'].to_i
    log "updating sim processor count: #{sim_params[:processor_count]}"
  end
  if post_data['sellerCount']
    sim_params[:seller_count] = post_data['sellerCount'].to_i
    log "updating sim seller count: #{sim_params[:seller_count]}"
  end
  run_details = run_sim game_name: game_name, sim_params: sim_params
  json({
    game_name: game_name,
    missed_cycles: 0, cycles_run: run_details.cycles_run,
    current_sim_data: run_details.current_sim_data.to_h,
    previous_sim_data: run_details.previous_sim_data.to_h
  })
end

def run_sim game_name: nil, sim_params: {}
  log "running #{game_name}"
  loader = Sim::HistoryLoader.new
  saver = Sim::HistorySaver.new
  sim = Sim::Sim.new
  data = loader.load from: save_path(game_name: game_name), to: sim
  last_work_timestamp = data.last_work_timestamp || data.save_timestamp
  missed_cycles = (Time.now.to_i - last_work_timestamp) / SECONDS_PER_CYCLE
  sim.set_miner_count sim_params[:miner_count].to_i if sim_params[:miner_count]
  sim.set_processor_count sim_params[:processor_count].to_i if sim_params[:processor_count]
  sim.set_seller_count sim_params[:seller_count].to_i if sim_params[:seller_count]
  log "running [#{game_name}] #{missed_cycles} cycles"
  previous_sim_data = nil
  current_sim_data = saver.create_data from: sim
  file_path = save_path game_name: game_name
  if missed_cycles == 0
    last_saved_data = loader.get_historical_data index: -1, from: file_path
    previous_sim_data = last_saved_data || data
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
                        cycles_run: missed_cycles)
end

def save_path game_name: nil
  "./saves/#{game_name}_save.json"
end

def log msg
  print "#{msg}\n"
end
