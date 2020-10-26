include ../../Makefile

TGIR := tgir-s01e07
CLUSTER := $(TGIR)-$(USER)

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

# TODO:
# https://github.com/packethost/packet-cli/releases
# https://github.com/alexellis/k3sup/releases

RABBITMQ_DEFAULT_USER ?= $(USER)
RABBITMQ_DEFAULT_PASS ?= $(TGIR)
RABBITMQ_ERLANG_COOKIE ?= $(CLUSTER)

$(KUBECONFIG_DIR):
	mkdir -p $(@)
$(KUBECONFIG): | $(KUBECTL) $(KUBECONFIG_DIR) $(CLOUDSDK_CONFIG)
	$(GCLOUD) container clusters get-credentials $(CLUSTER)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K3S instance via a terminal UI
	$(K9S) --all-namespaces

.PHONY: k9
k9: | $(K9S) $(KUBECONFIG)
	$(K9S) --namespace default --headless

define ENV
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export KUBECONFIG="$(KUBECONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias m 2>/dev/null; alias m=make
endef
export ENV
.PHONY: env
env:: | $(CLOUDSDK_CONFIG) $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)" OR source .env
	@echo "$$ENV"

.PHONY: equinix-metal
equinix-metal: | $(EQUINIX_METAL_CLI) ## Create a Equinix Metal instance - optional step

.PHONY: equinix-metal-rm
equinix-metal-rm: | $(K3S) ## Delete the Equinix Metal instance that we have created - this deletes everything

.PHONY: k3s
k3s: | $(K3SUP) ## Create a K3S instance on a Linux host - works on any Ubuntu VM

.PHONY: generate-secrets
generate-secrets::

.PHONY: rabbitmq-classic
rabbitmq-classic: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster & workload that uses Classic Queues

.PHONY: rabbitmq-quorum
rabbitmq-quorum: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster & workload that uses Quorum Queues

.PHONY: rabbitmq-stream
rabbitmq-quorum: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster & workload that uses Stream Queues

.PHONY: rabbitmq-rm-%
rabbitmq-rm-%: | $(KUBECONFIG) ## Delete one of the deployed RabbitMQ clusters & associated workloads: classic, quorum or stream

.PHONY: kube-prometheus
kube-prometheus: | $(KUBECONFIG) ## Integrate Prometheus & Grafana with K3S, including RabbitMQ dashboards
