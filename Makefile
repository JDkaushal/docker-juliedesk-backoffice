
NAME=backoffice
TEST_KEY=sezdzeidfjepodfkzepodfkzepokd
TEST_ENCRYPTION_KEY_BASE64=MTIzNDU2NzgxMjM0NTY3ODEyMzQ1Njc4MTIzNDU2Nzg=

test_project:
	make test_job; make test_epilogue

test_job:
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
	test:\n\
	  <<: *default\n\
	  host: 127.0.0.1\n\
	  username: postgres\n\
	  password: password\n\
	  database: test\n\
	" > config/database.yml

	docker run -d -p 5432:5432 --rm --name postgres-$(NAME)-test -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=password -e POSTGRES_DB=archive_test postgres:9.6-alpine

	sleep 5

	yarn install
	RAILS_ENV=test bundle exec rake db:setup
	RAILS_ENV=archive_test bundle exec rake db:setup

	RAILS_ENV=test API_ENABLED=true ADMIN_PANEL_ENABLED=true DASHBOARD_TEMPORARY_PASSWORD_ENCRYPTION_KEY=$(TEST_KEY) JULIE_ALIASES_CREDENTIALS_KEY=$(TEST_KEY) API_KEY=$(TEST_KEY) CLIENT_MANAGER_API_TOKEN=$(TEST_KEY) GOOGLE_API_KEY=$(TEST_KEY) SLASH_ENCRYPTION_KEY=$(TEST_ENCRYPTION_KEY_BASE64) bundle exec rspec

test_epilogue:
	docker stop postgres-$(NAME)-test
	if [ -f config/database.yml.cache ]; then mv config/database.yml.cache config/database.yml; fi