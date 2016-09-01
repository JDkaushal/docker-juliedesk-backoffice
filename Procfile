web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: rake jobs:work
resque_messages_threads: env TERM_CHILD=1 bundle exec rake resque:work QUEUE=messages_threads

log: tail -f log/development.log
