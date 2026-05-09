.PHONY: lint test docker-serve docker-build docker-push prod-up prod-down stack-deploy stack-rm

IMAGE ?= ghcr.io/sherafgan26/lobsters
TAG   ?= latest

test:
	bundle exec rspec
	brakeman -q

lint:
	bundle exec standardrb --fix-unsafely

docker-serve:
	docker compose up --build

docker-build:
	docker build -t $(IMAGE):$(TAG) .

docker-push: docker-build
	docker push $(IMAGE):$(TAG)

prod-up:
	docker compose -f docker-compose.yaml -f docker-compose.prod.yml --env-file .env up -d

prod-down:
	docker compose -f docker-compose.yaml -f docker-compose.prod.yml down

stack-deploy:
	docker stack deploy -c stack.yml --with-registry-auth lobsters

stack-rm:
	docker stack rm lobsters

all: lint test
