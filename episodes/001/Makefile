include ../Makefile

NAMESPACE := tgir-001

# https://hub.docker.com/_/rabbitmq/tags
RABBITMQ_DOCKER_IMAGE := rabbitmq:3.8.2-management
RABBITMQ_CONTAINER_NAME := $(NAMESPACE)-rabbitmq
RABBITMQ_MANAGEMENT_PORT := 15672
RABBITMQ_PROMETHEUS_PORT := 15692

# https://hub.docker.com/r/prom/prometheus/tags
PROMETHEUS_DOCKER_IMAGE := prom/prometheus:v2.14.0
PROMETHEUS_CONTAINER_NAME := $(NAMESPACE)-prometheus
PROMETHEUS_PORT := 9090

.PHONY: rabbitmq
rabbitmq: $(DOCKER)
	@$(DOCKER) run -it --rm -p $(RABBITMQ_MANAGEMENT_PORT):$(RABBITMQ_MANAGEMENT_PORT) -p $(RABBITMQ_PROMETHEUS_PORT):$(RABBITMQ_PROMETHEUS_PORT) --name $(RABBITMQ_CONTAINER_NAME) $(RABBITMQ_DOCKER_IMAGE)

.PHONY: rabbitmq_exec
rabbitmq_exec: $(DOCKER)
	@$(DOCKER) exec -it $(RABBITMQ_CONTAINER_NAME) bash

.PHONY: rabbitmq_metrics
rabbitmq_metrics:
	@$(OPEN) http://localhost:$(RABBITMQ_PROMETHEUS_PORT)/metrics

.PHONY: prometheus
prometheus: $(DOCKER)
	@$(DOCKER) run -it --rm -p $(PROMETHEUS_PORT):$(PROMETHEUS_PORT) --name $(PROMETHEUS_CONTAINER_NAME) $(PROMETHEUS_DOCKER_IMAGE)

.PHONY: prometheus_exec
prometheus_exec: $(DOCKER)
	@$(DOCKER) exec -it $(PROMETHEUS_CONTAINER_NAME) sh

.PHONY: prometheus_targets
prometheus_targets:
	@$(OPEN) http://localhost:$(PROMETHEUS_PORT)/targets
