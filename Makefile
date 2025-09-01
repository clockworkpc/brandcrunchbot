COMPOSE=docker compose exec web

test:
	$(COMPOSE) bundle exec rspec --format documentation

bash:
	$(COMPOSE) bash

bundle install:
	$(COMPOSE) bundle install

changelog:
	$(COMPOSE) bundle exec rake changelog:update

console:
	$(COMPOSE) bundle exec rails console

db-create:
	$(COMPOSE) bundle exec rails db:create

docs:
	$(COMPOSE) bundle exec rails docs:generate

generate:
	$(COMPOSE) bundle exec rails generate

guard:
	docker compose exec -e GUARD_GROUP=default web bundle exec guard

guard-focus:
	docker compose exec -e GUARD_GROUP=focus web bundle exec guard

migrate:
	$(COMPOSE) bundle exec rails db:migrate

routes:
	$(COMPOSE) bundle exec rails routes

security:
	$(COMPOSE) bundle exec brakeman

tasks:
	$(COMPOSE) bundle exec rake -T
