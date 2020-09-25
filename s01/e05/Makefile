include ../../Makefile

NAMESPACE := tgir-s01e05-$(USER)
K8S_REGION ?= lon1

DOCTL_CONFIG_DIR := $(XDG_CONFIG_HOME)/doctl
DOCTL_CONFIG := $(DOCTL_CONFIG_DIR)/config.yaml
ifneq ($(wildcard $(DOCTL_CONFIG)),)
DIGITALOCEAN_ACCESS_TOKEN := $(shell awk '/access-token/ { print $$2 }' < $(DOCTL_CONFIG))
export DIGITALOCEAN_ACCESS_TOKEN
endif
KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

ifeq ($(PLATFORM),Darwin)
DOCTL ?= /usr/local/bin/doctl
$(DOCTL):
	brew install doctl
else
DOCTL ?= /usr/bin/doctl
$(DOCTL):
	$(error Please install doctl: https://github.com/digitalocean/doctl#installing-doctl)
endif
.PHONY: doctl
doctl: $(DOCTL)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with K8S via terminal UI
	$(K9S) --namespace default

$(DOCTL_CONFIG_DIR):
	mkdir -p $(@)
$(DOCTL_CONFIG): | $(DOCTL_CONFIG_DIR) $(DOCTL)
	$(DOCTL) --config $(DOCTL_CONFIG) auth init

$(KUBECONFIG_DIR):
	mkdir -p $(@)
$(KUBECONFIG): | $(KUBECONFIG_DIR) $(KUBECTL) $(DOCTL)
	$(DOCTL) kubernetes cluster kubeconfig save $(NAMESPACE)

define ENV
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export DIGITALOCEAN_ACCESS_TOKEN="$(DIGITALOCEAN_ACCESS_TOKEN)"
export KUBECONFIG="$(KUBECONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias d 2>/dev/null; alias d=doctl
unalias m 2>/dev/null; alias m=make
endef
export ENV
.PHONY: env
env:: | $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)"
	@echo "$$ENV"

.PHONY: k8s
k8s: | $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Create K8S cluster
	$(DOCTL) kubernetes cluster get $(NAMESPACE) \
	|| time $(DOCTL) kubernetes cluster create $(NAMESPACE) \
	   --region $(K8S_REGION) \
	   --auto-upgrade \
	   --maintenance-window saturday=20:00

.PHONY: k8s-ls
k8s-ls: | $(DOCTL_CONFIG) ## List K8S clusters
	$(DOCTL) kubernetes cluster list

.PHONY: k8s-rm
k8s-rm: | $(DOCTL_CONFIG) ## Delete K8S cluster
	$(DOCTL) kubernetes cluster delete $(NAMESPACE)

.PHONY: k8s-node-sizes
k8s-node-sizes: | $(DOCTL_CONFIG) ## Show all size options for K8S nodes
	$(DOCTL) kubernetes options sizes

.PHONY: k8s-regions
k8s-regions: | $(DOCTL_CONFIG) ## Show all regions where K8S can be deployed
	$(DOCTL) kubernetes options regions

.PHONY: vms
vms: | $(DOCTL_CONFIG) ## Show all VMs (aka Droplets)
	$(DOCTL) compute droplet list && echo

.PHONY: lbs
lbs: | $(DOCTL_CONFIG) ## Show all Load Balancers
	$(DOCTL) compute load-balancer list && echo

.PHONY: vols
vols: | $(DOCTL_CONFIG) ## Show all Volumes
	$(DOCTL) compute volume list && echo

.PHONY: resources
resources: lbs vms vols ## Show all resources

.PHONY: rabbitmq
rabbitmq: | $(DOCTL_CONFIG) $(KUBECONFIG) ## Deploy the simplest RabbitMQ on K8S
	$(KUBECTL) apply --filename $(CURDIR)/k8s/statefulset.yml

.PHONY: rabbitmq-rm
rabbitmq-rm: | $(DOCTL_CONFIG) $(KUBECONFIG) ## Delete RabbitMQ and all linked resources
	$(KUBECTL) delete --ignore-not-found=true --filename $(CURDIR)/k8s

.PHONY: shell
shell: | $(KUBECONFIG) ## Open shell in RabbitMQ node
	$(KUBECTL) exec -it rabbitmq-0 -- /bin/bash

.PHONY: public
public: | $(KUBECONFIG) ## Make simplest RabbitMQ on K8S public
	$(KUBECTL) apply --filename $(CURDIR)/k8s/service.yml

.PHONY: persistent
persistent: | $(KUBECONFIG) $(YQ) ## Give RabbitMQ on K8S persistent storage
	$(KUBECTL) apply --filename $(CURDIR)/k8s/persistentvolumeclaim.yml
	$(YQ) merge $(CURDIR)/k8s/statefulset* | $(KUBECTL) apply --filename -

.PHONY: benchmark
benchmark: | public $(KUBECONFIG) ## Benchmark simplest RabbitMQ on K8S
	$(KUBECTL) create --filename $(CURDIR)/k8s/benchmark.job

.PHONY: all
all: k8s persistent public benchmark ## Create K8S cluster, deploy RabbitMQ, make public & persistent, then benchmark

.PHONY: clean
clean: rabbitmq-rm k8s-rm ## Delete RabbitMQ and all linked resources, then delete K8S cluster
