include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e08
DKE_CLUSTER := $(TGIR)
DKE_NODES_COUNT ?= 3
# make dke-regions
# Because Frankfurt is closer to @GSantomaggio than either London or Amsterdam
DKE_REGION ?= fra1
# make dke-sizes
DKE_NODES_TYPE ?= s-2vcpu-4gb
# make dke-versions
DKE_VERSION ?= 1.19.3-do.2
# Keeping this in sync with DKE version
KUBECTL_VERSION = 1.19.3

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

$(KUBECONFIG_DIR):
	@mkdir -p $(@)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K8S cluster via a terminal UI
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
DOCTL_VERSION := 1.54.0
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
DOCTL_WITH_CONFIG = $(DOCTL) --config $(DOCTL_CONFIG)
$(DOCTL_CONFIG): | $(DOCTL_CONFIG_DIR) $(DOCTL)
	$(DOCTL_WITH_CONFIG) auth init

.PHONY: all
all:: ## Setup all resources

.PHONY: clean
clean:: ## Remove all installed resources


.PHONY: dke
dke: | $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Create Digital Ocean Kubernetes (DKE) cluster
	$(DOCTL_WITH_CONFIG) kubernetes cluster get $(DKE_CLUSTER) \
	|| time $(DOCTL_WITH_CONFIG) kubernetes cluster create $(DKE_CLUSTER) \
	   --region $(DKE_REGION) \
	   --size $(DKE_NODES_TYPE) \
	   --version $(DKE_VERSION) \
	   --count $(DKE_NODES_COUNT) \
	   --auto-upgrade \
	   --maintenance-window saturday=20:00

$(KUBECONFIG): | $(KUBECONFIG_DIR) $(KUBECTL) $(DOCTL)
	$(DOCTL_WITH_CONFIG) kubernetes cluster kubeconfig save $(DKE_CLUSTER)
.PHONY: kubeconfig
kubeconfig: $(KUBECONFIG)

.PHONY: dke-ls
dke-ls: | $(DOCTL_CONFIG) ## List DKE clusters
	$(DOCTL_WITH_CONFIG) kubernetes cluster list

.PHONY: dke-rm
dke-rm: | $(DOCTL_CONFIG) ## Delete DKE cluster
	$(DOCTL_WITH_CONFIG) kubernetes cluster delete $(DKE_CLUSTER)

.PHONY: dke-regions
dke-regions: | $(DOCTL_CONFIG) ## Show all regions where DKE can be deployed
	$(DOCTL_WITH_CONFIG) kubernetes options regions

.PHONY: dke-sizes
dke-sizes: | $(DOCTL_CONFIG) ## Show all size options for DKE nodes
	$(DOCTL_WITH_CONFIG) kubernetes options sizes

.PHONY: dke-versions
dke-versions: | $(DOCTL_CONFIG) ## Show all size options for DKE nodes
	$(DOCTL_WITH_CONFIG) kubernetes options versions

# helm search repo --versions traefik/traefik
TRAEFIK_VERSION ?= 9.11.0
.PHONY: traefik
traefik: | $(HELM) $(KUBECONFIG) ## Deploy Traefik
	$(HELM) repo add traefik https://helm.traefik.io/traefik
	$(HELM) install traefik traefik/traefik \
	  --version $(TRAEFIK_VERSION) \
	  --values yaml/values.yaml
all:: traefik

traefik-rm: | $(HELM) $(KUBECONFIG) ## Remove Traefik
	$(HELM) uninstall traefik \
	; true
clean:: traefik-rm

# https://github.com/jetstack/cert-manager/releases
CERT_MANAGER_VERSION ?= 1.1.0
CERT_MANAGER_MANIFEST = https://github.com/jetstack/cert-manager/releases/download/v$(CERT_MANAGER_VERSION)/cert-manager.yaml
.PHONY: cert-manager
cert-manager: | kubeconfig
	$(KUBECTL) apply --filename $(CERT_MANAGER_MANIFEST)
all:: cert-manager

cert-manager-rm:
	$(KUBECTL) delete --filename $(CERT_MANAGER_MANIFEST)
clean:: cert-manager-rm

# https://github.com/rabbitmq/cluster-operator/releases
CLUSTER_OPERATOR_VERSION ?= 1.2.0
CLUSTER_OPERATOR_MANIFEST = https://github.com/rabbitmq/cluster-operator/releases/download/v$(CLUSTER_OPERATOR_VERSION)/cluster-operator.yml
.PHONY: cluster-operator
cluster-operator: | kubeconfig
	$(KUBECTL) apply --filename $(CLUSTER_OPERATOR_MANIFEST)
all:: cluster-operator

cluster-operator-rm:
	$(KUBECTL) delete --filename $(CLUSTER_OPERATOR_MANIFEST)
clean:: cluster-operator-rm

.PHONY: rabbitmq-%
rabbitmq-%: | kubeconfig ## Deploy a RabbitMQ cluster
	echo "TODO: create self-signed cert"
	$(KUBECTL) apply --filename yaml/rabbitmq-$(*).yaml
all:: rabbitmq-bugs
all:: rabbitmq-bunny

.PHONY: rabbitmq-%-public
rabbitmq-%-public: | kubeconfig ## Expose RabbitMQ cluster via a public IP
	kubectl apply --filename yaml/rabbitmq-$(*)-public.yaml

.PHONY: rabbitmq-%-public-rm
rabbitmq-%-public-rm: | kubeconfig ## Remove RabbitMQ cluster public IP
	kubectl delete --filename yaml/rabbitmq-$(*)-public.yaml
clean:: rabbitmq-bugs-public-rm
clean:: rabbitmq-bunny-public-rm

.PHONY: rabbitmq-%-rm
rabbitmq-%-rm: | kubeconfig ## Delete a RabbitMQ cluster
	echo "TODO: delete self-signed cert"
	$(KUBECTL) delete --filename yaml/rabbitmq-$(*).yaml
clean:: rabbitmq-bugs-rm
clean:: rabbitmq-bunny-rm

.PHONY: rabbitmq-%-ingress
rabbitmq-%-ingress: | kubeconfig ## Deploy HTTPS and AMQPS Traefik ingress
	echo "TODO: split ingress into HTTP & TCP"
	$(KUBECTL) apply --filename yaml/rabbitmq-$(*)-traefik-ingress.yaml
all:: rabbitmq-bugs-ingress
all:: rabbitmq-bunny-ingress

.PHONY: rabbitmq-%-ingress-rm
rabbitmq-%-ingress-rm: | kubeconfig ## Deploy HTTPS and AMQPS Traefik ingress
	$(KUBECTL) delete --filename yaml/rabbitmq-$(*)-traefik-ingress.yaml
clean:: rabbitmq-bugs-ingress-rm
clean:: rabbitmq-bunny-ingress-rm
