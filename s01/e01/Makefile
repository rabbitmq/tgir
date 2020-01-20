include ../../Makefile

DOCKER_NETWORK := tgir-s01e01

# https://hub.docker.com/_/rabbitmq?tab=tags
DOCKER_RABBITMQ_IMAGE := rabbitmq:3.7.23-management
    # https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
DOCKER_RABBITMQ_PERFTEST_IMAGE := pivotalrabbitmq/perf-test:2.10.0-ubuntu

.PHONY: network
network: $(DOCKER)
	@$(DOCKER) network inspect $(DOCKER_NETWORK) 1>/dev/null \
	|| $(DOCKER) network create $(DOCKER_NETWORK)

.PHONY: 3-nodes-production-rmq1-server
3-nodes-production-rmq1-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
3-nodes-production-rmq1-server: _rabbitmq_server ## Start RabbitMQ node 1/3

.PHONY: 3-nodes-production-rmq2-server
3-nodes-production-rmq2-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
3-nodes-production-rmq2-server: _rabbitmq_server ## Start RabbitMQ node 2/3

.PHONY: 3-nodes-production-rmq3-server
3-nodes-production-rmq3-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
3-nodes-production-rmq3-server: _rabbitmq_server ## Start RabbitMQ node 3/3

.PHONY: _rabbitmq_server
_rabbitmq_server: $(DOCKER) network
	$(DOCKER) run --interactive --tty \
	  --cpus 2 \
	  --env RABBITMQ_ERLANG_COOKIE=$(DOCKER_NETWORK) \
	  --hostname $(RABBITMQ_HOSTNAME) \
	  --memory 8G \
	  --name $(RABBITMQ_HOSTNAME) \
	  --network $(DOCKER_NETWORK) \
	  --publish :15672 \
	  --volume $(CURDIR)/3-nodes-production/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro \
	  --volume $(CURDIR)/3-nodes-production/rabbitmq-definitions.json:/etc/rabbitmq/rabbitmq-definitions.json:ro \
	  $(DOCKER_RABBITMQ_IMAGE)

.PHONY: 3-nodes-production-rmq1-clients
3-nodes-production-rmq1-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
3-nodes-production-rmq1-clients: _rabbitmq_clients ## Start clients for RabbitMQ node 1/3

.PHONY: 3-nodes-production-rmq2-clients
3-nodes-production-rmq2-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
3-nodes-production-rmq2-clients: _rabbitmq_clients ## Start clients for RabbitMQ node 2/3

.PHONY: _rabbitmq_clients
_rabbitmq_clients: $(DOCKER) network
	$(DOCKER) run --interactive --tty \
	  --cpus 1 \
	  --hostname $(RABBITMQ_HOSTNAME)-clients \
	  --memory 2G \
	  --name $(RABBITMQ_HOSTNAME)-clients \
	  --network $(DOCKER_NETWORK) \
	  $(DOCKER_RABBITMQ_PERFTEST_IMAGE) \
	  --auto-delete false \
	  --confirm 1 \
	  --confirm-timeout 10 \
	  --consumer-latency 1000000 \
	  --consumers 4000 \
	  --consumers-thread-pools 10 \
	  --flag persistent \
	  --heartbeat-sender-threads 10 \
	  --metrics-prometheus \
	  --nio-threads 10 \
	  --nio-thread-pool 20 \
	  --producers 4000 \
	  --publishing-interval 10 \
	  --producer-random-start-delay 120 \
	  --producer-scheduler-threads 10 \
	  --queue-args x-max-length=1000 \
	  --queue-pattern '$(RABBITMQ_HOSTNAME)-q%d' \
	  --queue-pattern-from 1 \
	  --queue-pattern-to 4000 \
	  --servers-startup-timeout 60 \
	  --size 1000 \
	  --uri "amqp://guest:guest@$(RABBITMQ_HOSTNAME):5672/%2f"

