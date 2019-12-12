include ../Makefile

DOCKER_NETWORK := 1212

# https://hub.docker.com/_/rabbitmq/tags
RABBITMQ_DOCKER_IMAGE := rabbitmq:3.8.2-management
RABBITMQ_CONTAINER_NAME := getstarted
# RABBITMQ_CONTAINER_NAME := getstarted0
RABBITMQ_MANAGEMENT_PORT := 15672
RABBITMQ_PROMETHEUS_PORT := 15692

# https://hub.docker.com/r/prom/prometheus/tags
PROMETHEUS_DOCKER_IMAGE := prom/prometheus:v2.14.0
PROMETHEUS_CONTAINER_NAME := prometheus
PROMETHEUS_PORT := 9090

# https://hub.docker.com/r/grafana/grafana/tags
GRAFANA_DOCKER_IMAGE := grafana/grafana:6.4.5
GRAFANA_CONTAINER_NAME := grafana
GRAFANA_PORT := 3000

# https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
PERFTEST_DOCKER_IMAGE := pivotalrabbitmq/perf-test:2.9.1
PERFTEST_CONTAINER_NAME := perftest

.PHONY: network
network: $(DOCKER)
	@$(DOCKER) network inspect $(DOCKER_NETWORK) 1>/dev/null \
	|| $(DOCKER) network create $(DOCKER_NETWORK)

.PHONY: rabbitmq
rabbitmq: $(DOCKER) network ## Start a single RabbitMQ node
	$(DOCKER) run -it --rm \
	  --name $(RABBITMQ_CONTAINER_NAME) \
	  --hostname $(RABBITMQ_CONTAINER_NAME) \
	  --network $(DOCKER_NETWORK) \
	  -p $(RABBITMQ_MANAGEMENT_PORT):$(RABBITMQ_MANAGEMENT_PORT) \
	  -p $(RABBITMQ_PROMETHEUS_PORT):$(RABBITMQ_PROMETHEUS_PORT) \
	  $(RABBITMQ_DOCKER_IMAGE)

.PHONY: rabbitmq_exec
rabbitmq_exec: $(DOCKER) ## Open a shell on the RabbitMQ node
	$(DOCKER) exec -it $(RABBITMQ_CONTAINER_NAME) bash

.PHONY: rabbitmq_enable_prometheus
rabbitmq_enable_prometheus: $(DOCKER) ## Enable rabbitmq_prometheus plugin
	$(DOCKER) exec -it $(RABBITMQ_CONTAINER_NAME) rabbitmq-plugins enable rabbitmq_prometheus

.PHONY: prometheus
prometheus: $(DOCKER) network ## Start a Prometheus instance
	$(DOCKER) run -it --rm \
	  --name $(PROMETHEUS_CONTAINER_NAME) \
	  --hostname $(PROMETHEUS_CONTAINER_NAME) \
	  --network $(DOCKER_NETWORK) \
	  -p $(PROMETHEUS_PORT):$(PROMETHEUS_PORT) \
	  $(PROMETHEUS_DOCKER_IMAGE)

.PHONY: prometheus_exec
prometheus_exec: $(DOCKER) ## Open a shell on the Prometheus instance
	$(DOCKER) exec -it $(PROMETHEUS_CONTAINER_NAME) sh

.PHONY: grafana
grafana: $(DOCKER) network ## Start a Grafana instance
	$(DOCKER) run -it --rm \
	  --name $(GRAFANA_CONTAINER_NAME) \
	  --hostname $(GRAFANA_CONTAINER_NAME) \
	  --network $(DOCKER_NETWORK) \
	  -p $(GRAFANA_PORT):$(GRAFANA_PORT) \
	  $(GRAFANA_DOCKER_IMAGE)

.PHONY: perftest
perftest: $(DOCKER) network ## Put load on the RabbitMQ node
	$(DOCKER) run -it --rm \
	  --name $(PERFTEST_CONTAINER_NAME) \
	  --hostname $(PERFTEST_CONTAINER_NAME) \
	  --network $(DOCKER_NETWORK) \
	  $(PERFTEST_DOCKER_IMAGE) \
	  --uri amqp://guest:guest@$(RABBITMQ_CONTAINER_NAME) \
	  --producers 2 \
	  --confirm 10 \
	  --variable-rate 10:30 \
	  --variable-rate 20:20 \
	  --consumers 2 \
	  --consumer-rate 30 \
	  --qos 50 \
	  --multi-ack-every 10 \
	  --queue-args x-max-length=1000
