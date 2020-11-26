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
#export KUBECONFIG

$(KUBECONFIG_DIR):
	@mkdir -p $(@)
$(KUBECONFIG): | $(KUBECONFIG_DIR) $(KUBECTL) $(DOCTL)
	$(DOCTL_WITH_CONFIG) kubernetes cluster kubeconfig save $(DKE_CLUSTER)
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
DOCTL_WITH_CONFIG = $(DOCTL) --config $(DOCTL_CONFIG)
$(DOCTL_CONFIG): | $(DOCTL_CONFIG_DIR) $(DOCTL)
	$(DOCTL_WITH_CONFIG) auth init

.PHONY: dke
dke: | $(DOCTL_CONFIG) $(KUBECONFIG_DIR) ## Create Digital Ocean Kubernetes cluster
	$(DOCTL_WITH_CONFIG) kubernetes cluster get $(DKE_CLUSTER) \
	|| time $(DOCTL_WITH_CONFIG) kubernetes cluster create $(DKE_CLUSTER) \
	   --region $(DKE_REGION) \
	   --size $(DKE_NODES_TYPE) \
	   --version $(DKE_VERSION) \
	   --count $(DKE_NODES_COUNT) \
	   --auto-upgrade \
	   --maintenance-window saturday=20:00

.PHONY: dke-ls
dke-ls: | $(DOCTL_CONFIG) ## List K8S clusters
	$(DOCTL_WITH_CONFIG) kubernetes cluster list

.PHONY: dke-rm
dke-rm: | $(DOCTL_CONFIG) ## Delete K8S cluster
	$(DOCTL_WITH_CONFIG) kubernetes cluster delete $(DKE_CLUSTER)

.PHONY: dke-regions
dke-regions: | $(DOCTL_CONFIG) ## Show all regions where Digital Ocean Kubernetes can be deployed
	$(DOCTL_WITH_CONFIG) kubernetes options regions

.PHONY: dke-sizes
dke-sizes: | $(DOCTL_CONFIG) ## Show all size options for DKE nodes
	$(DOCTL_WITH_CONFIG) kubernetes options sizes

.PHONY: dke-versions
dke-versions: | $(DOCTL_CONFIG) ## Show all size options for DKE nodes
	$(DOCTL_WITH_CONFIG) kubernetes options versions


.PHONY: deploy-traefik
deploy-traefik: ## Deploy Traefik version 2.x
	helm repo add traefik https://helm.traefik.io/traefik
	helm repo update
	helm install traefik traefik/traefik -f dist/values.yaml

.PHONY: deploy-prepare-env
deploy-prepare-env: ## Create name space and keys
	kubectl apply -f dist/0_namespace.yaml
	rm -rf tls-gen
	git clone https://github.com/michaelklishin/tls-gen tls-gen
	cd tls-gen/basic && make
	kubectl create secret tls rabbitmq-tls-secrest --cert=tls-gen/basic/result/server_certificate.pem --key=tls-gen/basic/result/server_key.pem -n tgir-s01e08
	kubectl create secret generic ca-secret --from-file=ca.crt=tls-gen/basic/result/ca_certificate.pem -n tgir-s01e08

.PHONY: deploy-rabbitmq-clusters
deploy-rabbitmq-clusters: ## Deploy the rabbitmq operator 1.1 and two rabbitmq clusters
	kubectl create -f dist/1_cluster-operator.yml
	kubectl create -f dist/2_rabbitmq_clusters.yaml

.PHONY: deploy-rabbitmq-ingresses
deploy-rabbitmq-ingresses: ## Deploy HTTPs and AMQPs traefik ingress
	kubectl create -f dist/3_traefik-ingress.yaml

.PHONY: deploy-rabbitmq-test-user
deploy-rabbitmq-test-user: ## Add a test user to make easy the example
	kubectl exec -it -n tgir-s01e08 rabbitmq-bugs-server-0 -- rabbitmqctl add_user test test
	kubectl exec -it -n tgir-s01e08 rabbitmq-bugs-server-0 -- rabbitmqctl set_user_tags test administrator
	kubectl exec -it -n tgir-s01e08 rabbitmq-bugs-server-0 -- rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

.PHONY: deploy
deploy: deploy-traefik deploy-prepare-env deploy-rabbitmq-clusters deploy-rabbitmq-ingresses ## Deploy all the deploy* stack in order

.PHONY: deploy-clean
deploy-clean: ##
	helm uninstall traefik
	kubectl delete namespace tgir-s01e08
	kubectl delete -f dist/1_cluster-operator.yml

