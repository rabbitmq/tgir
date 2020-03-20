include ../../Makefile

NAMESPACE := tgir-s01e03-$(USER)
JOBS_IN_PARALLEL ?= 8

ifeq ($(PLATFORM),Darwin)
ERLC ?= /usr/local/bin/erlc
$(ERLC):
	brew install erlang
else
ERLC ?= /usr/bin/erlc
$(ERLC):
	$(error Please install Erlang 22 or newer)
endif

ifeq ($(PLATFORM),Darwin)
MIX ?= /usr/local/bin/mix
$(MIX):
	brew install elixir
else
MIX ?= /usr/bin/mix
$(MIX):
	$(error Please install Elixir 1.9 or newer)
endif

.PHONY: deps
deps: $(ERLC) $(MIX) rabbitmq-public-umbrella ## Resolve all dependencies

rabbitmq-public-umbrella: ## Setup a local copy for developing RabbitMQ
	git clone https://github.com/rabbitmq/rabbitmq-public-umbrella.git
	cd %
	$(MAKE) co

.PHONY: switch-to-3.8.x
switch-to-3.8.x: deps ## Switch local copy to v3.8.x
	cd rabbitmq-public-umbrella
	git checkout v3.8.x
	$(MAKE) up --jobs=$(JOBS_IN_PARALLEL) BRANCH=v3.8.x

.PHONY: switch-to-3.9.x
switch-to-3.9.x: deps ## Switch local copy to v3.9.x
	cd rabbitmq-public-umbrella
	git checkout master
	$(MAKE) up --jobs=$(JOBS_IN_PARALLEL) BRANCH=master

.PHONY: dev-server
dev-server: deps ## Run dev rabbitmq-server
	cd rabbitmq-public-umbrella/deps/rabbit
	$(MAKE) run-broker

.PHONY: dev-server-with-plugins
dev-server-with-plugins: deps ## Run dev rabbitmq-server with plugins
	cd rabbitmq-public-umbrella/deps/rabbitmq_prometheus
	$(MAKE) run-broker RABBITMQ_LOGS=-

.PHONY: dev-cluster-start
dev-cluster-start: deps ## Start dev cluster
	cd rabbitmq-public-umbrella/deps/rabbitmq_prometheus
	$(MAKE) start-cluster

.PHONY: dev-cluster-stop
dev-cluster-stop: deps ## Stop dev cluster
	cd rabbitmq-public-umbrella/deps/rabbitmq_prometheus
	$(MAKE) stop-cluster
