include ../../Makefile

DOCKER_NETWORK := tgir-s01e01

# https://hub.docker.com/_/rabbitmq?tab=tags
DOCKER_RABBITMQ_IMAGE := rabbitmq:3.7.23-management
# https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
DOCKER_RABBITMQ_PERFTEST_IMAGE := pivotalrabbitmq/perf-test:2.10.0-ubuntu

NUMBER_OF_QUEUES_PER_NODE := 1000
NUMBER_OF_MESSAGES_PER_QUEUE := 1000
MESSAGE_SIZE := 1000

.PHONY: network
network: $(DOCKER)
	@$(DOCKER) network inspect $(DOCKER_NETWORK) 1>/dev/null \
	|| $(DOCKER) network create $(DOCKER_NETWORK)

.PHONY: 3-nodes-production-rmq1-server
3-nodes-production-rmq1-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
3-nodes-production-rmq1-server: _rabbitmq-server ## Start RabbitMQ node 1/3

.PHONY: 3-nodes-production-rmq2-server
3-nodes-production-rmq2-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
3-nodes-production-rmq2-server: _rabbitmq-server ## Start RabbitMQ node 2/3

.PHONY: 3-nodes-production-rmq3-server
3-nodes-production-rmq3-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
3-nodes-production-rmq3-server: _rabbitmq-server ## Start RabbitMQ node 3/3

.PHONY: _rabbitmq-server
_rabbitmq-server: $(DOCKER) network
	$(DOCKER) run --interactive --tty \
	  --env RABBITMQ_ERLANG_COOKIE=$(DOCKER_NETWORK) \
	  --hostname $(RABBITMQ_HOSTNAME) \
	  --memory 12G \
	  --name $(RABBITMQ_HOSTNAME) \
	  --network $(DOCKER_NETWORK) \
	  --publish :15672 \
	  --volume $(CURDIR)/3-nodes-production/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro \
	  --volume $(CURDIR)/3-nodes-production/rabbitmq-definitions.json:/etc/rabbitmq/rabbitmq-definitions.json:ro \
	  $(DOCKER_RABBITMQ_IMAGE)

.PHONY: 3-nodes-production-rmq1-clients
3-nodes-production-rmq1-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
3-nodes-production-rmq1-clients: _rabbitmq-clients ## Start clients for RabbitMQ node 1/3

.PHONY: 3-nodes-production-rmq2-clients
3-nodes-production-rmq2-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
3-nodes-production-rmq2-clients: _rabbitmq-clients ## Start clients for RabbitMQ node 2/3

.PHONY: 3-nodes-production-rmq3-clients
3-nodes-production-rmq3-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
3-nodes-production-rmq3-clients: _rabbitmq-clients ## Start clients for RabbitMQ node 3/3

.PHONY: _rabbitmq-clients
_rabbitmq-clients: $(DOCKER) network
	$(DOCKER) run --rm --interactive --tty \
	  --cpus 1 \
	  --hostname $(RABBITMQ_HOSTNAME)-clients \
	  --memory 2G \
	  --name $(RABBITMQ_HOSTNAME)-clients \
	  --network $(DOCKER_NETWORK) \
	  $(DOCKER_RABBITMQ_PERFTEST_IMAGE) \
	  --auto-delete false \
	  --confirm 1 \
	  --confirm-timeout 10 \
	  --consumer-latency 10000 \
	  --consumers $(NUMBER_OF_QUEUES_PER_NODE) \
	  --consumers-thread-pools 10 \
	  --flag persistent \
	  --heartbeat-sender-threads 10 \
	  --metrics-prometheus \
	  --nio-threads 10 \
	  --nio-thread-pool 20 \
	  --producers 0 \
	  --publishing-interval 60 \
	  --producer-random-start-delay 120 \
	  --producer-scheduler-threads 10 \
	  --queue-args 'x-max-length=$(NUMBER_OF_MESSAGES_PER_QUEUE)' \
	  --queue-pattern '$(RABBITMQ_HOSTNAME)-q%d' \
	  --queue-pattern-from 1 \
	  --queue-pattern-to $(NUMBER_OF_QUEUES_PER_NODE) \
	  --servers-startup-timeout 60 \
	  --size $(MESSAGE_SIZE) \
	  --uri "amqp://guest:guest@$(RABBITMQ_HOSTNAME):5672/%2f"

.PHONY: 3-nodes-production-rmq1-backlog
3-nodes-production-rmq1-backlog: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
3-nodes-production-rmq1-backlog: _message-backlog ## Create message backlog on RabbitMQ node 1/3

.PHONY: 3-nodes-production-rmq2-backlog
3-nodes-production-rmq2-backlog: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
3-nodes-production-rmq2-backlog: _message-backlog ## Create message backlog on RabbitMQ node 2/3

.PHONY: 3-nodes-production-rmq3-backlog
3-nodes-production-rmq3-backlog: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
3-nodes-production-rmq3-backlog: _message-backlog ## Create message backlog on RabbitMQ node 3/3

.PHONY: _message-backlog
_message-backlog: $(DOCKER) network
	$(DOCKER) run --rm --interactive --tty \
	  --hostname $(RABBITMQ_HOSTNAME)-backlog \
	  --name $(RABBITMQ_HOSTNAME)-backlog \
	  --network $(DOCKER_NETWORK) \
	  $(DOCKER_RABBITMQ_PERFTEST_IMAGE) \
	  --auto-delete false \
	  --confirm 3 \
	  --confirm-timeout 60 \
	  --consumers 0 \
	  --flag persistent \
	  --producers $(NUMBER_OF_QUEUES_PER_NODE) \
	  --queue-args 'x-max-length=$(NUMBER_OF_MESSAGES_PER_QUEUE)' \
	  --queue-pattern '$(RABBITMQ_HOSTNAME)-q%d' \
	  --queue-pattern-from 1 \
	  --queue-pattern-to $(NUMBER_OF_QUEUES_PER_NODE) \
	  --rate 3 \
	  --servers-startup-timeout 60 \
	  --size $(MESSAGE_SIZE) \
	  --uri "amqp://guest:guest@$(RABBITMQ_HOSTNAME):5672/%2f"
