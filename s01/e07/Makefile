include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e07

# $ equinix_metal facilities get
DATA_CENTRE ?= am6
# Available bare metal servers: https://metal.equinix.com/product/servers/
# $ equinix_metal plans get
INSTANCE_TYPE ?= c3.small.x86
INSTANCE_NAME ?= $(TGIR)-$(USER)
# $ equinix_metal operating-systems get
OS ?= ubuntu_20_04
SSH_USER ?= root

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
	  --ip $(EQUINIX_METAL_INSTANCE_IP) \
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
equinix-metal-ssh-key: | $(EQUINIX_METAL) ## Add SSH key that will be added to all new instances
	@if [[ ! -r "$(SSH_PUBLIC_KEY)" ]] \
	; then \
	  printf "$(BOLD)SSH_PUBLIC_KEY$(NORMAL)$(RED) variable must be set to a public SSH key file path, e.g. ~/.ssh/id_rsa.pub$(NORMAL)\n" \
	  ; exit 1 \
	; fi
	$(EQUINIX_METAL) ssh-key get $(SSH_PUBLIC_KEY_NAME) \
	|| $(EQUINIX_METAL) ssh-key create --key "$$(cat $(SSH_PUBLIC_KEY))" --label $(USER)-$(SSH_PUBLIC_KEY_NAME)

.PHONY: equinix-metal
equinix-metal: | $(EQUINIX_METAL) ## Create a Equinix Metal instance - optional step
	$(EQUINIX_METAL) server create \
	  --facility $(DATA_CENTRE) \
	  --hostname $(INSTANCE_NAME) \
	  --operating-system $(OS) \
	  --plan $(INSTANCE_TYPE) \
	  --project-id $(PROJECT_ID)

INSTANCES = $(EQUINIX_METAL) server get --project-id $(PROJECT_ID)
FIND_INSTANCE_ID = $(JQ) --raw-output '.[] | select(.hostname == "$(INSTANCE_NAME)") | .id'

define EQUINIX_METAL_INSTANCE_IP
$$($(INSTANCES) --json 2>/dev/null \
| $(JQ) --raw-output '.[] | select(.hostname == "$(INSTANCE_NAME)") | .ip_addresses[] | select(.address_family == 4) | select(.public == true) | .address')
endef
.PHONY: equinix-metal-rm
equinix-metal-rm: | $(EQUINIX_METAL) $(JQ) ## Delete the Equinix Metal instance - this deletes everything
	$(EQUINIX_METAL) server delete --id $$($(INSTANCES) --json 2>/dev/null | $(FIND_INSTANCE_ID))

equinix-metal-instances: | $(EQUINIX_METAL) ## List all Equinix Metal instances
	$(INSTANCES) $(ARGS)

equinix-metal-ssh: ## SSH into the Equinix Metal instance
	ssh $(SSH_USER)@$(EQUINIX_METAL_INSTANCE_IP)

SSH_PRIVATE_KEY ?=
.PHONY: k3s
k3s: | $(K3SUP) ## Create a K3S instance on a Linux host - works on any Ubuntu VM
	@if [[ ! -r "$(SSH_PRIVATE_KEY)" ]] \
	; then \
	  printf "$(BOLD)SSH_PRIVATE_KEY$(NORMAL)$(RED) variable must be set to the private SSH key file path, e.g. ~/.ssh/id_rsa$(NORMAL)\n" \
	  ; exit 1 \
	; fi
	$(K3SUP) install \
	  --ip $(EQUINIX_METAL_INSTANCE_IP) \
	  --user $(SSH_USER) \
	  --ssh-key $(SSH_PRIVATE_KEY) \
	  --local-path $(KUBECONFIG) \
	  --k3s-channel $(K3S_CHANNEL)

.PHONY: k3s-monitoring
k3s-monitoring: k3s-prometheus-stack k3s-rabbitmq-grafana ## Integrate Prometheus & Grafana with K3S, including RabbitMQ dashboards

# https://github.com/cablespaghetti/k3s-monitoring
# + https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
#
# Re: manifest_sorter.go:192: info: skipping unknown hook: "crd-install"
# https://github.com/prometheus-community/helm-charts/issues/155#issuecomment-706743032
#
# helm search repo --versions prometheus-community/kube-prometheus-stack
KUBE_PROMETHEUS_STACK_VERSION ?= 10.3.1
.PHONY: k3s-prometheus-stack
k3s-prometheus-stack: | $(KUBECONFIG) $(HELM)
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) upgrade prometheus prometheus-community/kube-prometheus-stack \
	  --install \
	  --version $(KUBE_PROMETHEUS_STACK_VERSION) \
	  --values k8s/prometheus-operator/values.yml
	$(KUBECTL) apply --filename k8s/prometheus-operator/traefik-servicemonitor.yml --filename k8s/prometheus-operator/traefik-dashboard.yml

# https://grafana.com/orgs/rabbitmq
.PHONY: k3s-rabbitmq-grafana
k3s-rabbitmq-grafana: | $(KUBECONFIG)
	$(KUBECTL) apply \
	  --filename k8s/prometheus-operator/rabbitmq-overview-dashboard.yml \
	  --filename k8s/prometheus-operator/rabbitmq-quorum-queues-raft-dashboard.yml \
	  --filename k8s/prometheus-operator/rabbitmq-perftest.yml \
	  --filename k8s/prometheus-operator/erlang-distribution-dashboard.yml \
	  --filename k8s/prometheus-operator/erlang-memory-allocators.yml

k3s-access-grafana: | $(KUBECONFIG) ## Access Grafana running in K3S
	$(OPEN) http://$(EQUINIX_METAL_INSTANCE_IP)

.PHONY: rabbitmq-classic
rabbitmq-classic: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster & workload that uses Classic Queues

.PHONY: rabbitmq-quorum
rabbitmq-quorum: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster & workload that uses Quorum Queues

.PHONY: rabbitmq-stream
rabbitmq-quorum: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster & workload that uses Stream Queues

.PHONY: rabbitmq-rm-%
rabbitmq-rm-%: | $(KUBECONFIG) ## Delete one of the deployed RabbitMQ clusters & associated workloads: classic, quorum or stream

.PHONY: tmp
tmp::

tmp/k3s-monitoring:
	git clone https://github.com/cablespaghetti/k3s-monitoring $(@)
tmp:: tmp/k3s-monitoring

tmp/prometheus-community-helm-charts:
	git clone https://github.com/prometheus-community/helm-charts $(@)
tmp:: tmp/prometheus-community-helm-charts

