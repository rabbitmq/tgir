include ../../Makefile

NAMESPACE := tgir-s01e06-$(USER)

XDG_CONFIG_HOME := $(CURDIR)/.config
export XDG_CONFIG_HOME
KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

ifeq ($(PLATFORM),Darwin)
# Do not use kubectl installed by Docker for Desktop, this will typically be an older version than kubernetes-cli
# Use the latest installed kubernetes-cli
KUBECTL ?= $(lastword $(wildcard /usr/local/Cellar/kubernetes-cli/*/bin/kubectl))
$(KUBECTL):
	brew install kubernetes-cli
else
KUBECTL ?= /usr/bin/kubectl
$(KUBECTL):
	$(error Please install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl)
endif
.PHONY: kubectl
kubectl: $(KUBECTL)

ifeq ($(PLATFORM),Darwin)
YQ ?= /usr/local/bin/yq
$(YQ):
	brew install yq
else
YQ ?= /usr/bin/yq
$(YQ):
	$(error Please install yq: https://github.com/mikefarah/yq#install)
endif
.PHONY: yq
yq: $(YQ)

ifeq ($(PLATFORM),Darwin)
K9S ?= /usr/local/bin/k9s
$(K9S):
	brew install derailed/k9s/k9s
else
K9S ?= /usr/bin/k9s
$(K9S):
	$(error Please install k9s: https://github.com/derailed/k9s#installation)
endif

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with K8S via terminal UI
	$(K9S) --namespace default

$(KUBECONFIG_DIR):
	mkdir -p $(@)
$(KUBECONFIG): | $(KUBECONFIG_DIR) $(KUBECTL) $(DOCTL)
	$(DOCTL) kubernetes cluster kubeconfig save $(NAMESPACE)

.PHONY: env
define ENV
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export KUBECONFIG="$(KUBECONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias m 2>/dev/null; alias m=make
endef
export ENV
env: | $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)"
	@echo "$$ENV"

.PHONY: k8s
k8s: | $(KUBECONFIG_DIR) ## Create K8S cluster

.PHONY: k8s-ls
k8s-ls: | ## List K8S clusters

.PHONY: k8s-rm
k8s-rm: | ## Delete K8S cluster

.PHONY: k8s-node-sizes
k8s-node-sizes: | ## Show all size options for K8S nodes

.PHONY: k8s-regions
k8s-regions: | ## Show all regions where K8S can be deployed

.PHONY: vms
vms: | ## Show all VMs (aka Compute Engine instances)

.PHONY: lbs
lbs: | ## Show all Load Balancers

.PHONY: vols
vols: | ## Show all Volumes

.PHONY: resources
resources: lbs vms vols ## Show all resources

.PHONY: rabbitmq
rabbitmq: | $(KUBECONFIG) ## Deploy a RabbitMQ cluster on K8S

.PHONY: rabbitmq-rm
rabbitmq-rm: | $(KUBECONFIG) ## Delete RabbitMQ and all linked resources

.PHONY: rabbitmq-workload
rabbitmq-workload: | $(KUBECONFIG) ## Deploy a RabbitMQ publishing & consuming workload

.PHONY: all
all: k8s rabbitmq ## Create K8S cluster & deploy RabbitMQ

.PHONY: clean
clean: rabbitmq-rm k8s-rm ## Delete RabbitMQ and all linked resources, then delete K8S cluster
