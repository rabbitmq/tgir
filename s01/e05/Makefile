include ../../Makefile

NAMESPACE := tgir-s01e05-$(USER)
K8S_NODE_SIZE ?= s-2vcpu-4gb
K8S_REGION ?= lon1

XDG_CONFIG_HOME := $(CURDIR)/.config
export XDG_CONFIG_HOME
DOCTL_CONFIG_DIR := $(XDG_CONFIG_HOME)/doctl
DOCTL_CONFIG := $(DOCTL_CONFIG_DIR)/config.yaml
ifneq ($(wildcard $(DOCTL_CONFIG)),)
DIGITALOCEAN_ACCESS_TOKEN := $(shell awk '/access-token/ { print $$2 }' < $(DOCTL_CONFIG))
export DIGITALOCEAN_ACCESS_TOKEN
endif
KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/.kube
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

DOCTL := /usr/local/bin/doctl
$(DOCTL):
	brew install doctl

# Do not use kubectl installed by Docker for Desktop, this will typically be an older version than kubernetes-cli
# Use the latest installed kubernetes-cli
KUBECTL := $(lastword $(wildcard /usr/local/Cellar/kubernetes-cli/*/bin/kubectl))
$(KUBECTL):
	brew install kubernetes-cli

YQ := /usr/local/bin/yq
$(YQ):
	brew install yq
yq: $(YQ)

$(DOCTL_CONFIG_DIR):
	mkdir -p $(@)

K9S := /usr/local/bin/k9s
$(K9S):
	brew install derailed/k9s/k9s
k9s: $(K9S) ## Interact with K8S via terminal UI
	$(K9S)

$(DOCTL_CONFIG): $(DOCTL_CONFIG_DIR) | $(DOCTL)
	$(DOCTL) --config $(DOCTL_CONFIG) auth init

$(KUBECONFIG_DIR):
	mkdir -p $(@)

$(KUBECONFIG): $(KUBECTL) k8s

.PHONY: env
define ENV
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export DIGITALOCEAN_ACCESS_TOKEN="$(DIGITALOCEAN_ACCESS_TOKEN)"
export KUBECONFIG="$(KUBECONFIG)"
unalias k; alias k=kubectl
unalias d; alias d=doctl
unalias m; alias m=make
endef
export ENV
env: $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Configure shell env
	@echo "$$ENV"

.PHONY: k8s
k8s: $(DOCTL_CONFIG) ## Create K8S cluster
	$(DOCTL) kubernetes cluster get $(NAMESPACE) \
	|| time $(DOCTL) kubernetes cluster create $(NAMESPACE) \
	  --tag TGIR \
	  --size $(K8S_NODE_SIZE) \
	  --region $(K8S_REGION)

.PHONY: k8s-ls
k8s-ls: $(DOCTL_CONFIG) ## List K8S clusters
	$(DOCTL) kubernetes cluster list

.PHONY: k8s-rm
k8s-rm: $(DOCTL_CONFIG) ## Delete K8S cluster
	time $(DOCTL) kubernetes cluster delete $(NAMESPACE)

.PHONY: k8s-node-sizes
k8s-node-sizes: $(DOCTL_CONFIG) ## Show all size options for K8S nodes
	$(DOCTL) kubernetes options sizes

.PHONY: k8s-regions
k8s-regions: $(DOCTL_CONFIG) ## Show all regions where K8S can be deployed
	$(DOCTL) kubernetes options regions

.PHONY: drops
drops: $(DOCTL_CONFIG) ## Show all Droplets (aka VMs)
	$(DOCTL) compute droplet list

.PHONY: lbs
lbs: $(DOCTL_CONFIG) ## Show all Load Balancers
	$(DOCTL) compute load-balancer list

.PHONY: vols
vols: $(DOCTL_CONFIG) ## Show all Volumes
	$(DOCTL) compute volume list

.PHONY: deploy
deploy: $(DOCTL_CONFIG) $(KUBECONFIG) ## Deploy the simplest RabbitMQ on K8S
	$(KUBECTL) apply --filename $(CURDIR)/k8s/statefulset.yml

.PHONY: shell
shell: $(KUBECONFIG) ## Open shell in RabbitMQ node
	$(KUBECTL) exec -it rabbitmq-0 -- /bin/bash

.PHONY: public
public: $(KUBECONFIG) ## Make simplest RabbitMQ on K8S public
	$(KUBECTL) apply --filename $(CURDIR)/k8s/service.yml

.PHONY: persistent
persistent: $(KUBECONFIG) | $(YQ) ## Give RabbitMQ on K8S persistent storage
	$(KUBECTL) apply --filename $(CURDIR)/k8s/persistentvolumeclaim.yml
	$(YQ) merge $(CURDIR)/k8s/statefulset* | $(KUBECTL) apply --filename -

.PHONY: benchmark
benchmark: $(KUBECONFIG) ## Benchmark simplest RabbitMQ on K8S
	$(KUBECTL) create --filename $(CURDIR)/k8s/job.benchmark.yml
