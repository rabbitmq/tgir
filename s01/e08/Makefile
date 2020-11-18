include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e08
DKE_CLUSTER := $(TGIR)
# make dke-regions
# Because Frankfurt is closer to @GSantomaggio than either London or Amsterdam
DKE_REGION ?= fra1

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

$(KUBECONFIG_DIR):
	@mkdir -p $(@)
$(KUBECONFIG): | $(KUBECONFIG_DIR) $(KUBECTL) $(DOCTL)
	$(DOCTL) kubernetes cluster kubeconfig save $(DKE_CLUSTER)
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

DOCTL_RELEASES := https://github.com/digitalocean/doctl/releases
DOCTL_VERSION := 1.52.0
DOCTL_BIN_DIR := doctl-$(DOCTL_VERSION)-$(platform)-amd64
DOCTL_URL := https://github.com/digitalocean/doctl/releases/download/v$(DOCTL_VERSION)/doctl-$(DOCTL_VERSION)-$(platform)-amd64.tar.gz
DOCTL := $(LOCAL_BIN)/$(DOCTL_BIN_DIR)/doctl
$(DOCTL): | $(CURL) $(LOCAL_BIN)
	$(CURL) --progress-bar --fail --location --output $(LOCAL_BIN)/$(DOCTL_BIN_DIR).tar.gz "$(DOCTL_URL)"
	mkdir -p $(LOCAL_BIN)/$(DOCTL_BIN_DIR) && tar zxf $(LOCAL_BIN)/$(DOCTL_BIN_DIR).tar.gz -C $(LOCAL_BIN)/$(DOCTL_BIN_DIR)
	touch $(DOCTL)
	chmod +x $(DOCTL)
	$(DOCTL) version | grep $(DOCTL_VERSION)
	ln -sf $(DOCTL) $(LOCAL_BIN)/doctl
.PHONY: doctl
doctl: $(DOCTL)

DOCTL_CONFIG_DIR := $(XDG_CONFIG_HOME)/doctl
$(DOCTL_CONFIG_DIR):
	mkdir -p $(@)
DOCTL_CONFIG := $(DOCTL_CONFIG_DIR)/config.yaml
$(DOCTL_CONFIG): | $(DOCTL_CONFIG_DIR) $(DOCTL)
	$(DOCTL) --config $(DOCTL_CONFIG) auth init

.PHONY: dke
dke: | $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Create Digital Ocean Kubernetes cluster
	$(DOCTL) --config $(DOCTL_CONFIG) kubernetes cluster get $(DKE_CLUSTER) \
	|| time $(DOCTL) kubernetes cluster create $(DKE_CLUSTER) \
	   --region $(DKE_REGION) \
	   --auto-upgrade \
	   --maintenance-window saturday=20:00

.PHONY: dke-regions
dke-regions: | $(DOCTL_CONFIG) ## Show all regions where Digital Ocean Kubernetes can be deployed
	$(DOCTL) --config $(DOCTL_CONFIG) kubernetes options regions