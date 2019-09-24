
NAME=backoffice
TEST_KEY=sezdzeidfjepodfkzepodfkzepokd
TEST_ENCRYPTION_KEY_BASE64=MTIzNDU2NzgxMjM0NTY3ODEyMzQ1Njc4MTIzNDU2Nzg=

test_project:
	make test_prologue; make test_job; make test_epilogue

test_prologue:
	if [ -f config/database.yml ]; then mv config/database.yml config/database.yml.cache; fi
	echo "default: &default\n\
	  adapter: postgresql\n\
	  encoding: unicode\n\
	  pool: 5\n\
	archive_test:\n\
	  <<: *default\n\
	  host: 127.0.0.1\n\
	  username: postgres\n\
	  password: password\n\
	  database: archive_test\n\
	  port: 15432\n\
	test:\n\
	  <<: *default\n\
	  host: 127.0.0.1\n\
	  username: postgres\n\
	  password: password\n\
	  database: test\n\
	  port: 15432\n\
	" > config/database.yml

	docker run -d -p 15432:5432 --rm --name postgres-$(NAME)-test -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=test postgres:9.6-alpine

	sleep 5

	yarn install

	# Set higher open file limit for rails 5.2 rspec tests
	ulimit -n 1024

	RAILS_ENV=test bundle exec rake db:migrate
	RAILS_ENV=archive_test bundle exec rake db:create
	RAILS_ENV=archive_test bundle exec rake db:migrate

test_job:
	RAILS_ENV=test API_KEY=$(TEST_KEY) SLASH_ENCRYPTION_KEY=$(TEST_ENCRYPTION_KEY_BASE64) bundle exec rspec

test_epilogue:
	docker stop postgres-$(NAME)-test
	if [ -f config/database.yml.cache ]; then mv config/database.yml.cache config/database.yml; fi

analyze:
	bundle exec bundle-audit update
	dependency-check --project "$(NAME)" --scan .
	open dependency-check-report.html
	bundle exec brakeman