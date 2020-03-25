include ../../Makefile

JOBS_IN_PARALLEL ?= 6

ifeq ($(PLATFORM),Darwin)
ERL ?= /usr/local/bin/erl
$(ERL):
	brew install erlang
else
ERL ?= /usr/bin/erl
$(ERL):
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
deps: | $(ERL) $(MIX) rabbitmq-public-umbrella ## Resolve all dependencies

rabbitmq-public-umbrella: ## Setup a local copy for developing RabbitMQ
	git clone https://github.com/rabbitmq/rabbitmq-public-umbrella.git $@
	&& time make -C $@ up -j $(JOBS_IN_PARALLEL)

.PHONY: which-release-series
which-release-series: | deps ## Show which release series we are currently on
	make -C rabbitmq-public-umbrella show-branch

.PHONY: switch-to-3.8.x
switch-to-3.8.x: | deps ## Switch local copy to v3.8.x
	cd rabbitmq-public-umbrella \
	&& git checkout v3.8.x \
	&& time make up -j $(JOBS_IN_PARALLEL) BRANCH=v3.8.x

.PHONY: switch-to-3.9.x
switch-to-3.9.x: | deps ## Switch local copy to v3.9.x
	cd rabbitmq-public-umbrella \
	&& git checkout master \
	&& time make up -j $(JOBS_IN_PARALLEL) BRANCH=master

.PHONY: dev-server
dev-server: | deps ## Run dev rabbitmq-server
	make -C rabbitmq-public-umbrella/deps/rabbit run-broker

.PHONY: dev-server-all-plugins
dev-server-all-plugins: | deps ## Run dev rabbitmq-server with all plugins
	make -C rabbitmq-public-umbrella/deps/rabbitmq_server_release run-broker RABBITMQ_LOGS=-

.PHONY: show-ctls
show-ctls: | deps ## Show where to find CTLs
	ls rabbitmq-public-umbrella/deps/rabbit/sbin/

.PHONY: checkout-pr2279
checkout-pr2279: | switch-to-3.9.x ## Checkout the correct source for rabbitmq-server & rabbitmq-common
	cd rabbitmq-public-umbrella/deps/rabbit && git checkout startup_memory_fix
	cd rabbitmq-public-umbrella/deps/rabbit_common && git checkout worker_pool_dispatch_sync

.PHONY: docker-image
docker-image: | deps ## Build & publish a Docker image of a custom RabbitMQ build
	make -C rabbitmq-public-umbrella/deps/rabbitmq_server_release docker-image PROJECT_VERSION=3.9-$(shell date -u +'%Y%m%d')
