include ../../Makefile

DOCKER_NETWORK := tgir-s01e01

# https://hub.docker.com/_/rabbitmq?tab=tags
DOCKER_RABBITMQ_37x_IMAGE = rabbitmq:3.7.23-management
DOCKER_RABBITMQ_38x_IMAGE = rabbitmq:3.8.2-management
DOCKER_RABBITMQ_IMAGE = $(DOCKER_RABBITMQ_37x_IMAGE)
# https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
DOCKER_RABBITMQ_PERFTEST_IMAGE := pivotalrabbitmq/perf-test:dev-2020.01.22

NUMBER_OF_QUEUES_PER_NODE := 1000
NUMBER_OF_MESSAGES_PER_QUEUE := 1000
MESSAGE_SIZE := 1000

.PHONY: network
network: $(DOCKER)
	@$(DOCKER) network inspect $(DOCKER_NETWORK) 1>/dev/null \
	|| $(DOCKER) network create $(DOCKER_NETWORK)

.PHONY: rmq1-server
rmq1-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
rmq1-server: _rabbitmq-server ## Start RabbitMQ node 1/3

.PHONY: rmq1-server-38x
rmq1-server-38x: DOCKER_RABBITMQ_IMAGE = $(DOCKER_RABBITMQ_38x_IMAGE)
rmq1-server-38x: rmq1-server ## Start RabbitMQ node 1/3 as 3.8.x

.PHONY: rmq2-server
rmq2-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
rmq2-server: _rabbitmq-server ## Start RabbitMQ node 2/3

.PHONY: rmq3-server
rmq3-server: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
rmq3-server: _rabbitmq-server ## Start RabbitMQ node 3/3

.PHONY: _rabbitmq-server
_rabbitmq-server: $(DOCKER) network
	$(DOCKER) run --interactive --tty \
	  --env RABBITMQ_ERLANG_COOKIE=$(DOCKER_NETWORK) \
	  --hostname $(RABBITMQ_HOSTNAME) \
	  --memory 12G \
	  --name $(RABBITMQ_HOSTNAME) \
	  --network $(DOCKER_NETWORK) \
	  --publish 15672:15672 \
	  --publish 5672:5672 \
	  --rm \
	  --volume $(CURDIR)/3-nodes-production/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf:ro \
	  --volume $(CURDIR)/3-nodes-production/rabbitmq-definitions.json:/etc/rabbitmq/rabbitmq-definitions.json:ro \
	  --volume $(RABBITMQ_HOSTNAME):/var/lib/rabbitmq:rw \
	  $(DOCKER_RABBITMQ_IMAGE)

.PHONY: rmq1-bash
rmq1-bash: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
rmq1-bash: _rabbitmq-bash ## Open bash shell on RabbitMQ node 1/3

.PHONY: rmq2-bash
rmq2-bash: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
rmq2-bash: _rabbitmq-bash ## Open bash shell on RabbitMQ node 2/3

.PHONY: rmq3-bash
rmq3-bash: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
rmq3-bash: _rabbitmq-bash ## Open bash shell on RabbitMQ node 3/3

.PHONY: _rabbitmq-bash
_rabbitmq-bash: $(DOCKER)
	$(DOCKER) exec --interactive --tty \
	  $(RABBITMQ_HOSTNAME) \
	  bash

.PHONY: rmq1-clients
rmq1-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
rmq1-clients: _rabbitmq-clients ## Start clients for RabbitMQ node 1/3

.PHONY: rmq2-clients
rmq2-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
rmq2-clients: _rabbitmq-clients ## Start clients for RabbitMQ node 2/3

.PHONY: rmq3-clients
rmq3-clients: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
rmq3-clients: _rabbitmq-clients ## Start clients for RabbitMQ node 3/3

.PHONY: _rabbitmq-clients
_rabbitmq-clients: $(DOCKER)
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
	  --producers $(NUMBER_OF_QUEUES_PER_NODE) \
	  --publishing-interval 60 \
	  --producer-random-start-delay 120 \
	  --producer-scheduler-threads 10 \
	  --qos 10 \
	  --queue-args 'x-max-length=$(NUMBER_OF_MESSAGES_PER_QUEUE)' \
	  --queue-pattern '$(RABBITMQ_HOSTNAME)-q%d' \
	  --queue-pattern-from 1 \
	  --queue-pattern-to $(NUMBER_OF_QUEUES_PER_NODE) \
	  --servers-startup-timeout 60 \
	  --size $(MESSAGE_SIZE) \
	  --uri "amqp://guest:guest@$(RABBITMQ_HOSTNAME):5672/%2f"

.PHONY: rmq1-messages
rmq1-messages: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq1
rmq1-messages: _message-backlog ## Create message backlog on RabbitMQ node 1/3

.PHONY: rmq2-messages
rmq2-messages: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq2
rmq2-messages: _message-backlog ## Create message backlog on RabbitMQ node 2/3

.PHONY: rmq3-messages
rmq3-messages: RABBITMQ_HOSTNAME = $(DOCKER_NETWORK)-rmq3
rmq3-messages: _message-backlog ## Create message backlog on RabbitMQ node 3/3

.PHONY: _message-backlog
_message-backlog: $(DOCKER) network
	$(DOCKER) run --rm --interactive --tty \
	  --hostname $(RABBITMQ_HOSTNAME)-backlog \
	  --name $(RABBITMQ_HOSTNAME)-backlog \
	  --network $(DOCKER_NETWORK) \
	  $(DOCKER_RABBITMQ_PERFTEST_IMAGE) \
	  --auto-delete false \
	  --consumers 0 \
	  --flag persistent \
	  --pmessages $(NUMBER_OF_MESSAGES_PER_QUEUE) \
	  --producers $(NUMBER_OF_QUEUES_PER_NODE) \
	  --queue-args 'x-max-length=$(NUMBER_OF_MESSAGES_PER_QUEUE)' \
	  --queue-pattern '$(RABBITMQ_HOSTNAME)-q%d' \
	  --queue-pattern-from 1 \
	  --queue-pattern-to $(NUMBER_OF_QUEUES_PER_NODE) \
	  --rate 5 \
	  --servers-startup-timeout 60 \
	  --size $(MESSAGE_SIZE) \
	  --uri "amqp://guest:guest@$(RABBITMQ_HOSTNAME):5672/%2f"
