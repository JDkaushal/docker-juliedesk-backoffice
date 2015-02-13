web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: rake jobs:work
log: tail -f log/development.log
