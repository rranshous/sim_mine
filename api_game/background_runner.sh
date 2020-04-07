#!/usr/bin/env bash

while true
do
  echo "running games"
  ls saves/*.json | xargs -P1 -L1 bundle exec ruby cli_runner.rb
  echo "done running games; sleeping for one min"
  sleep 60
done
