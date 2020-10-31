include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e07

# $ equinix_metal facilities get
DATA_CENTRE ?= am6
# Available bare metal servers: https://metal.equinix.com/product/servers/
# $ equinix_metal plans get
SERVER_TYPE ?= c3.small.x86
SERVER_NAME ?= $(TGIR)
# $ equinix_metal operating-systems get
OS ?= ubuntu_20_04
SSH_USER ?= root

K3S_HOST ?= $(EQUINIX_METAL_SERVER_IP)

K3S_CHANNEL ?= v1.18

EQUINIX_METAL_RELEASES := https://github.com/packethost/packet-cli/releases
EQUINIX_METAL_VERSION := 0.1.0
EQUINIX_METAL_BIN := packet-$(EQUINIX_METAL_VERSION)-$(platform)-amd64
EQUINIX_METAL_URL := $(EQUINIX_METAL_RELEASES)/download/$(EQUINIX_METAL_VERSION)/packet-$(platform)-amd64
EQUINIX_METAL := $(LOCAL_BIN)/$(EQUINIX_METAL_BIN)
$(EQUINIX_METAL): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(EQUINIX_METAL) "$(EQUINIX_METAL_URL)"
	touch $(EQUINIX_METAL)
	chmod +x $(EQUINIX_METAL)
	$(EQUINIX_METAL) --version | grep $(EQUINIX_METAL_VERSION)
	ln -sf $(EQUINIX_METAL) $(LOCAL_BIN)/equinix_metal
.PHONY: equinix-metal
equinix-metal: $(EQUINIX_METAL)

K3SUP_RELEASES := https://github.com/alexellis/k3sup/releases
K3SUP_VERSION := 0.9.7
K3SUP_BIN := k3sup-$(K3SUP_VERSION)-$(platform)-amd64
K3SUP_URL := $(K3SUP_RELEASES)/download/$(K3SUP_VERSION)/k3sup-$(platform)
K3SUP := $(LOCAL_BIN)/$(K3SUP_BIN)
$(K3SUP): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(K3SUP) "$(K3SUP_URL)"
	touch $(K3SUP)
	chmod +x $(K3SUP)
	$(K3SUP) version | grep $(K3SUP_VERSION)
	ln -sf $(K3SUP) $(LOCAL_BIN)/k3sup
.PHONY: k3sup
k3sup: $(K3SUP)
.PHONY: releases-k3sup
releases-k3sup:
	$(OPEN) $(K3SUP_RELEASES)

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG
$(KUBECONFIG_DIR):
	@mkdir -p $(@)
$(KUBECONFIG): | $(K3SUP) $(KUBECTL) $(KUBECONFIG_DIR)
	$(K3SUP) install \
	  --skip-install \
	  --ip $(K3S_HOST) \
	  --user $(SSH_USER) \
	  --ssh-key $(SSH_PRIVATE_KEY) \
	  --local-path $(KUBECONFIG)
.PHONY: kubeconfig
kubeconfig: $(KUBECONFIG)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K3S instance via a terminal UI
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

PACKET_TOKEN ?=
PROJECT_ID ?=
.envrc:
	@if [[ -z "$(PACKET_TOKEN)" ]] \
	; then \
	  printf "$(BOLD)PACKET_TOKEN$(NORMAL)$(RED) variable must be set so that Equinix Metal CLI operations can run against your Equinix Metal account$(NORMAL)\n" \
	  ; exit 1 \
	; fi
	@if [[ -z "$(PROJECT_ID)" ]] \
	; then \
	  printf "$(BOLD)PROJECT_ID$(NORMAL)$(RED) variable must be set so that Equinix Metal CLI operations can run against your Equinix Metal account$(NORMAL)\n" \
	  ; exit 1 \
	; fi
	@echo "export PACKET_TOKEN=$(PACKET_TOKEN)" > .envrc
	@echo "export PROJECT_ID=$(PACKET_TOKEN)" >> .envrc

SSH_PUBLIC_KEY ?=
SSH_PUBLIC_KEY_NAME = $(notdir $(basename $(SSH_PUBLIC_KEY)))
.PHONY: equinix-metal-ssh-key
equinix-metal-ssh-key: | $(EQUINIX_METAL) ## Add SSH key that will be added to all new servers
	@if [[ ! -r "$(SSH_PUBLIC_KEY)" ]] \
	; then \
	  printf "$(BOLD)SSH_PUBLIC_KEY$(NORMAL)$(RED) variable must be set to a public SSH key file path, e.g. ~/.ssh/id_rsa.pub$(NORMAL)\n" \
	  ; exit 1 \
	; fi
	$(EQUINIX_METAL) ssh-key create --key "$$(cat $(SSH_PUBLIC_KEY))" --label $(USER)-$(SSH_PUBLIC_KEY_NAME)

.PHONY: equinix-metal-server
equinix-metal-server: | $(EQUINIX_METAL) ## Create a Equinix Metal host - optional step
	$(EQUINIX_METAL) server get --id $$($(SERVERS) --json 2>/dev/null | $(FIND_SERVER_ID)) \
	|| $(EQUINIX_METAL) server create \
	  --facility $(DATA_CENTRE) \
	  --hostname $(SERVER_NAME) \
	  --operating-system $(OS) \
	  --plan $(SERVER_TYPE) \
	  --project-id $(PROJECT_ID)

SERVERS = $(EQUINIX_METAL) server get --project-id $(PROJECT_ID)
FIND_SERVER_ID = $(JQ) --raw-output '.[] | select(.hostname == "$(SERVER_NAME)") | .id'

define EQUINIX_METAL_SERVER_IP
$$($(SERVERS) --json 2>/dev/null \
| $(JQ) --raw-output '.[] | select(.hostname == "$(SERVER_NAME)") | .ip_addresses[] | select(.address_family == 4) | select(.public == true) | .address')
endef
.PHONY: equinix-metal-server-rm
equinix-metal-server-rm: | $(EQUINIX_METAL) $(JQ) ## Delete the Equinix Metal server - this deletes everything
	$(EQUINIX_METAL) server delete --id $$($(SERVERS) --json 2>/dev/null | $(FIND_SERVER_ID))

equinix-metal-servers: | $(EQUINIX_METAL) ## List all Equinix Metal servers
	$(SERVERS) $(ARGS)

ssh-k3s: ## SSH into the K3S host
	ssh $(SSH_USER)@$(K3S_HOST)

SSH_PRIVATE_KEY ?=
.PHONY: k3s
k3s: | $(K3SUP) ## Create a K3S instance on a Linux host - works on any Ubuntu VM
	@if [[ ! -r "$(SSH_PRIVATE_KEY)" ]] \
	; then \
	  printf "$(BOLD)SSH_PRIVATE_KEY$(NORMAL)$(RED) variable must be set to the private SSH key file path, e.g. ~/.ssh/id_rsa$(NORMAL)\n" \
	  ; exit 1 \
	; fi
	$(K3SUP) install \
	  --ip $(K3S_HOST) \
	  --user $(SSH_USER) \
	  --ssh-key $(SSH_PRIVATE_KEY) \
	  --local-path $(KUBECONFIG) \
	  --k3s-channel $(K3S_CHANNEL)

# https://github.com/cablespaghetti/k3s-monitoring
# + https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
#
# Re: manifest_sorter.go:192: info: skipping unknown hook: "crd-install"
# https://github.com/prometheus-community/helm-charts/issues/155#issuecomment-706743032
#
# helm search repo --versions prometheus-community/kube-prometheus-stack
KUBE_PROMETHEUS_STACK_VERSION ?= 10.3.1
.PHONY: k3s-monitoring
k3s-monitoring: | $(KUBECONFIG) $(HELM) ## Integrate Prometheus & Grafana with K3S, including system metrics
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) upgrade prometheus prometheus-community/kube-prometheus-stack \
	  --install \
	  --version $(KUBE_PROMETHEUS_STACK_VERSION) \
	  --values k8s/prometheus-stack/values.yml
	$(KUBECTL) apply \
	  --filename k8s/prometheus-stack/traefik-servicemonitor.yml \
	  --filename k8s/prometheus-stack/traefik-grafana-dashboard.yml

k3s-grafana: | $(KUBECONFIG) ## Access Grafana running in K3S
	$(OPEN) http://$(K3S_HOST)

k3s-rabbitmq: k3s-rabbitmq-grafana k3s-rabbitmq-operator rabbitmq-default-metrics rabbitmq-minimal-metrics rabbitmq-prometheus-metrics rabbitmq-quorum rabbitmq-stream ## Deploy all things RabbitMQ in K3S: operator, clusters, workloads & dashboards

# https://grafana.com/orgs/rabbitmq
.PHONY: k3s-rabbitmq-grafana
k3s-rabbitmq-grafana: | $(KUBECONFIG)
	$(KUBECTL) apply \
	  --filename k8s/prometheus-stack/rabbitmq-overview-grafana-dashboard.yml \
	  --filename k8s/prometheus-stack/rabbitmq-quorum-queues-raft-grafana-dashboard.yml \
	  --filename k8s/prometheus-stack/rabbitmq-perftest-grafana-dashboard.yml \
	  --filename k8s/prometheus-stack/erlang-distribution-grafana-dashboard.yml \
	  --filename k8s/prometheus-stack/erlang-memory-allocators-grafana-dashboard.yml

# https://github.com/rabbitmq/cluster-operator/releases
RABBITMQ_OPERATOR_VERSION ?= 0.48.0
k3s-rabbitmq-operator: | $(KUBECONFIG) ## Install RabbitMQ Cluster Operator into K3S
	$(KUBECTL) apply --filename https://github.com/rabbitmq/cluster-operator/releases/download/$(RABBITMQ_OPERATOR_VERSION)/cluster-operator.yml

.PHONY: rabbitmq-default-metrics
rabbitmq-default-metrics: | $(KUBECONFIG) ## Deploy a RabbitMQ with many Classic Queues, Publishers & Consumers and default Management metrics
	$(KUBECTL) apply --filename k8s/rabbitmq/default-metrics.yml

.PHONY: rabbitmq-minimal-metrics
rabbitmq-minimal-metrics: | $(KUBECONFIG) ## Deploy a RabbitMQ with many Classic Queues, Publishers & Consumers and minimal Management metrics
	$(KUBECTL) apply --filename k8s/rabbitmq/minimal-metrics.yml

.PHONY: rabbitmq-prometheus-metrics
rabbitmq-prometheus-metrics: | $(KUBECONFIG) ## Deploy a RabbitMQ with many Classic Queues, Publishers & Consumers and no Management metrics
	$(KUBECTL) apply --filename k8s/rabbitmq/prometheus-metrics.yml

.PHONY: rabbitmq-quorum
rabbitmq-quorum: | $(KUBECONFIG) ## Deploy a RabbitMQ with a Quorum Queue workload
	$(KUBECTL) apply --filename k8s/rabbitmq/quorum.yml

.PHONY: rabbitmq-stream
rabbitmq-stream: | $(KUBECONFIG) ## Deploy a RabbitMQ with a Stream Queue workload
	$(KUBECTL) apply --filename k8s/rabbitmq/stream.yml

.PHONY: rabbitmq-rm-%
rabbitmq-rm-%: | $(KUBECONFIG) ## Delete one of the deployed RabbitMQ clusters & associated workloads: classic, quorum or stream
	$(KUBECTL) delete --filename k8s/rabbitmq/$(*).yml --wait

.PHONY: tmp
tmp::

tmp/k3s-monitoring:
	git clone https://github.com/cablespaghetti/k3s-monitoring $(@)
tmp:: tmp/k3s-monitoring

tmp/prometheus-community-helm-charts:
	git clone https://github.com/prometheus-community/helm-charts $(@)
tmp:: tmp/prometheus-community-helm-charts

