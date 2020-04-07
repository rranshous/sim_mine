require 'json'
require_relative 'game'

def log msg
  print "[#{@file_path}] #{msg}\n"
  STDOUT.flush
end

@file_path = ARGV.shift
log "running"

runner = Runner.new
result = runner.run_sim file_path: @file_path

if result.cycles_run > 0
  log "did work cycles: #{result.cycles_run}"
end

log "result: #{JSON.dump({
  previous_sim_data: result.previous_sim_data.to_h,
  current_sim_data: result.current_sim_data.to_h,
  cycles_run: result.cycles_run,
  sim_endstate: result.sim_endstate,
  next_run_in: result.next_run_in
})}"
