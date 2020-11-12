include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e09

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG
$(KUBECONFIG_DIR):
	@mkdir -p $(@)
$(KUBECONFIG): | $(KUBECTL) $(KUBECONFIG_DIR)
.PHONY: kubeconfig
kubeconfig: $(KUBECONFIG)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K8S instance via a terminal UI
	$(K9S) --all-namespaces

define ENV
export PATH=$(LOCAL_BIN):$$PATH
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export KUBECONFIG="$(KUBECONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias m 2>/dev/null; alias m=make
endef
export ENV
.PHONY: env
env:: | $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)" OR source .env
	@echo "$$ENV"

.PHONY: chaos-operator
chaos-operator: | $(KUBECONFIG) ## Install Chaos Mesh Operator
	$(CURL) -sSL https://mirrors.chaos-mesh.org/latest/install.sh | bash

MONITORING_DIR := monitoring-stack
.PHONY: monitoring-stack
monitoring-stack: ## Deploy a monitoring stack
	$(DOCKER) run --rm -v $(MONITORING_DIR):$(MONITORING_DIR) --workdir $(MONITORING_DIR) quay.io/coreos/jsonnet-ci ./build.sh monitoringstack.jsonnet
	$(KUBECTL) apply --filename $(MONITORING_DIR)/manifests/setup
	$(KUBECTL) apply --filename $(MONITORING_DIR)/manifests
	$(KUBECTL) apply --filename $(MONITORING_DIR)/rabbitmq

# https://github.com/rabbitmq/cluster-operator/releases
RABBITMQ_OPERATOR_VERSION := 0.49.0

.PHONY: rabbitmq-operator
rabbitmq-operator: | $(KUBECONFIG) ## Install RabbitMQ Cluster Operator into K8S
	$(KUBECTL) apply --filename https://github.com/rabbitmq/cluster-operator/releases/download/$(RABBITMQ_OPERATOR_VERSION)/cluster-operator.yml

# TODO: Make this not GKE-specific
.PHONY: rabbitmq-production-cluster
rabbitmq-production-cluster: | rabbitmq-operator ## Install the production-ready RabbitMQ cluster
	$(KUBECTL) apply --namespace rabbitmq-system --filename https://raw.githubusercontent.com/rabbitmq/cluster-operator/$(RABBITMQ_OPERATOR_VERSION)/docs/examples/production-ready/ssd-gke.yaml
	$(KUBECTL) apply --namespace rabbitmq-system --filename https://raw.githubusercontent.com/rabbitmq/cluster-operator/$(RABBITMQ_OPERATOR_VERSION)/docs/examples/production-ready/rabbitmq.yaml
