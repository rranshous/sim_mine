require 'sinatra'
require "sinatra/json"
require 'json'
require_relative 'sim'

SECONDS_PER_CYCLE = 30

get '/game' do
  '''
  <html><head>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
  <script>
    function createGame() {
      let gameName = $("#create_game_name").val();
      console.log("createGame name:", gameName);
      $.post("/api/game", JSON.stringify({ gameName: gameName }), function(result, _, xhr) {
        console.log("createGame result:", result);
        location.href="/game/"+gameName;
      });
    };
  </script>
  </head><body>
  <label>create game <input type="text" id="create_game_name"></label>
  <button onClick="createGame()">Create</button>
  </body></html>
  '''
end

get '/game/:game_name' do |game_name|
  '''
  <html><head>
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
  <script>

    let gameName = "''' + game_name + '''";

    function loadGame() {
      console.log("loadGame name:", gameName);
      $.get("/api/game/"+gameName, function(result) {
        console.log("loadGame result:", result);
        $("#game_missed_cycles").text(result.missed_cycles);
        $("#game_name").text(result.game_name);
        let simData = result.current_sim_data;
        Object.keys(result.current_sim_data).forEach(function(key) {
          let el = $("#sim_"+key);
          if(el.length) {
            console.debug("setting game data:", key, simData[key]);
            if(el.is("input")) {
              el.val(simData[key]);
            } else {
              el.text(simData[key]);
            }
          }
        });
      });
    };

    function runGame() {
      console.log("runGame name:", gameName);
      let data = {
        minerCount: $("#sim_miner_count").val(),
        processorCount: $("#sim_processor_count").val(),
        sellerCount: $("#sim_seller_count").val()
      };
      let url = "/api/game/"+gameName+"/run_to_current";
      $.post(url, JSON.stringify(data), function(result) {
        console.log("runGame result:", result);
        loadGame();
      });
    };

    $(function() { loadGame(); });
  </script>
  </head><body>
  <h3>Game <span id="game_name"></span></h3>
  <p>
    Credits: <span id="sim_credits"></span><br/>
    Mine: <span id="sim_mine_product"></span> left<br/>
    Hired Miners: <input type="text" id="sim_miner_count"></input><br/>
    Mined Yesterday: <span id="sim_miner_product"></span><br/>
    Hired Smelters: <input type="text" id="sim_processor_count"></input><br/>
    Smelted Yesterday: <span id="sim_processor_product"></span><br/>
    Hired Brokers: <input type="text" id="sim_seller_count"></input><br/>
  </p>
  <button onClick="runGame()">Update Hired Workers</button>
  </body></html>
  '''
end


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

post '/api/game/:game_name/run_to_current' do |game_name|
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
  loader = Sim::Loader.new
  saver = Sim::Saver.new
  sim = Sim::Sim.new
  data = loader.load from: save_path(game_name: game_name), to: sim
  last_work_timestamp = data.last_work_timestamp || data.save_timestamp
  missed_cycles = (Time.now.to_i - last_work_timestamp) / SECONDS_PER_CYCLE
  sim.set_miner_count sim_params[:miner_count].to_i if sim_params[:miner_count]
  sim.set_processor_count sim_params[:processor_count].to_i if sim_params[:processor_count]
  sim.set_seller_count sim_params[:seller_count].to_i if sim_params[:seller_count]
  log "running [#{game_name}] #{missed_cycles} cycles"
  missed_cycles.times do
    sim.run_work_cycle
  end
  new_data = saver.create_data from: sim
  new_data.last_work_timestamp = Time.now.to_i if missed_cycles > 0
  saver.save_data to: save_path(game_name: game_name), data: new_data
  return OpenStruct.new(previous_sim_data: data, current_sim_data: new_data,
                        cycles_run: missed_cycles)
end

def save_path game_name: nil
  "./saves/#{game_name}_save.json"
end

def log msg
  print "#{msg}\n"
end
