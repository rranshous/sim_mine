require 'sinatra'
require "sinatra/json"
require 'json'
require_relative '../sim'
require_relative 'game'

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
  runner = Runner.new
  saver.save to: save_path(game_name: game_name), from: sim
  runner.run_sim game_name: game_name
  redirect "/api/game/#{game_name}", 201
end

get '/api/game/:game_name' do |game_name|
  log "getting #{game_name}"
  runner = Runner.new
  run_details = runner.run_sim game_name: game_name
  json({
    game_name: game_name, game_over: run_details.sim_endstate,
    cycles_run: run_details.cycles_run,
    current_sim_data: run_details.current_sim_data.to_h,
    previous_sim_data: run_details.previous_sim_data.to_h,
    next_run_in: run_details.next_run_in
  })
end

post '/api/game/:game_name/update_params' do |game_name|
  runner = Runner.new
  body = request.body.read
  post_data = body != '' ? JSON.parse(body) : {}
  log "post_data: #{post_data}" unless post_data.empty?
  sim_params = {}
  if post_data['minerCount']
    sim_params[:miner_count] = post_data['minerCount'].to_i
  end
  if post_data['processorCount']
    sim_params[:processor_count] = post_data['processorCount'].to_i
  end
  if post_data['sellerCount']
    sim_params[:seller_count] = post_data['sellerCount'].to_i
  end
  run_details = runner.run_sim game_name: game_name, sim_params: sim_params
  json({
    game_name: game_name, game_over: run_details.sim_endstate,
    cycles_run: run_details.cycles_run,
    current_sim_data: run_details.current_sim_data.to_h,
    previous_sim_data: run_details.previous_sim_data.to_h,
    next_run_in: run_details.next_run_in
  })
end


def save_path game_name: nil
  "./saves/#{game_name}_save.json"
end

def log msg
  print "#{msg}\n"
end
