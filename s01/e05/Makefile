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
DOCTL := /usr/local/bin/doctl
$(DOCTL):
	brew install doctl

$(DOCTL_CONFIG_DIR):
	mkdir -p $(DOCTL_CONFIG_DIR)

$(DOCTL_CONFIG): $(DOCTL_CONFIG_DIR) | $(DOCTL)
	$(DOCTL) auth init

.PHONY: env
env: $(DOCTL_CONFIG)
	@echo "export XDG_CONFIG_HOME=\"$(XDG_CONFIG_HOME)\""
	@echo "export DIGITALOCEAN_ACCESS_TOKEN=\"$(DIGITALOCEAN_ACCESS_TOKEN)\""

.PHONY: k8s
k8s: $(DOCTL_CONFIG) ## Create K8S cluster
	time $(DOCTL) kubernetes cluster create $(NAMESPACE) \
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

.PHONY: droplets
droplets: $(DOCTL_CONFIG) ## Show all running droplets
	$(DOCTL) compute droplet list
