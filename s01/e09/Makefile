include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e09
CLUSTER := $(TGIR)-$(USER)
# Find out what versions are available: make k8s-versions
# K8S versions valid at 25 November 2020
CLUSTER_VERSION ?= 1.18.10-gke.2101
CLUSTER_NODE_VERSION ?= 1.18.10-gke.2101
CLUSTER_RELEASES ?= rapid
CLUSTER_NODE_TYPE ?= n2-standard-4
CLUSTER_NODES_PER_ZONE ?= 2

# You may want to overwrite this with your GCP project, e.g. export GCP_PROJECT=my-project-name
GCP_PROJECT ?= cf-rabbitmq-core
# You may want to overwrite this with your preferred GCP region, e.g. export GCP_REGION=us-east1
GCP_REGION ?= europe-west2

# https://github.com/rabbitmq/cluster-operator/releases
RABBITMQ_OPERATOR_VERSION := v1.1.0

KUBECONFIG_DIR := $(XDG_CONFIG_HOME)/kubectl
KUBECONFIG := $(KUBECONFIG_DIR)/config
export KUBECONFIG

RABBITMQ_DEFAULT_USER ?= $(USER)
RABBITMQ_DEFAULT_PASS ?= $(TGIR)
RABBITMQ_ERLANG_COOKIE ?= $(CLUSTER)

CLOUDSDK_CONFIG := $(XDG_CONFIG_HOME)/gcloud/configurations/config_default
export CLOUDSDK_CONFIG
$(CLOUDSDK_CONFIG): $(GCLOUD)
	$(GCLOUD) auth login \
	&& $(GCLOUD) config set project $(GCP_PROJECT) \
	&& $(GCLOUD) config set compute/region $(GCP_REGION)

$(KUBECONFIG_DIR):
	mkdir -p $(@)
$(KUBECONFIG): | $(KUBECTL) $(KUBECONFIG_DIR) $(CLOUDSDK_CONFIG)
	$(GCLOUD) container clusters get-credentials $(CLUSTER)

.PHONY: k9s
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K8S cluster via a terminal UI
	$(K9S) --all-namespaces

.PHONY: k9
k9: | $(K9S) $(KUBECONFIG)
	$(K9S) --namespace default --headless

define ENV
export GCP_PROJECT="$(GCP_PROJECT)"
export GCP_REGION="$(GCP_REGION)"
export KUBECONFIG="$(KUBECONFIG)"
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export CLOUDSDK_CONFIG="$(CLOUDSDK_CONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias m 2>/dev/null; alias m=make
endef
export ENV
.PHONY: env
env:: | $(CLOUDSDK_CONFIG) $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)" OR source .env
	@echo "$$ENV"

define LIST_INSTANCES
$(GCLOUD) compute instances list --filter='name ~ $(CLUSTER)'
endef
instances: | $(CLOUDSDK_CONFIG) ## List all instances
	$(LIST_INSTANCES)

watch-instances: | $(CLOUDSDK_CONFIG) ## Watch all instances
	watch -c "$(LIST_INSTANCES)"

watch-nodes: | $(KUBECONFIG) ## Watch all K8S nodes
	watch -c "$(KUBECTL) get nodes --output=wide"

disks: | $(CLOUDSDK_CONFIG) ## List all disks
	$(GCLOUD) compute disks list --filter='name ~ $(CLUSTER)'

.PHONY: k8s-versions
k8s-versions: | $(CLOUDSDK_CONFIG) ## List all available K8S versions on GCP (GKE)
	$(GCLOUD) container get-server-config

.PHONY: k8s
k8s: | $(CLOUDSDK_CONFIG) ## Create a managed K8S cluster on GCP (GKE) - up to 4 minutes
	$(GCLOUD) container clusters describe $(CLUSTER) \
	|| time $(GCLOUD) container clusters create $(CLUSTER) \
	   --release-channel $(CLUSTER_RELEASES) \
	   --cluster-version $(CLUSTER_VERSION) \
	   --node-version $(CLUSTER_NODE_VERSION) \
	   --machine-type $(CLUSTER_NODE_TYPE) \
	   --num-nodes $(CLUSTER_NODES_PER_ZONE) \
	   --enable-shielded-nodes \
	   --disk-type "pd-ssd" \
	   --disk-size "100" \
	   --enable-ip-alias \
	   --enable-autoupgrade \
	   --enable-autorepair \
	   --max-surge-upgrade $(CLUSTER_NODES_PER_ZONE) \
	   --max-unavailable-upgrade 0 \
	   --metadata disable-legacy-endpoints=true \
	   --no-enable-master-authorized-networks \
	   --addons "HorizontalPodAutoscaling,HttpLoadBalancing"

.PHONY: k8s-help
k8s-help: | $(CLOUDSDK_CONFIG) ## List all options available when creating a managed K8S cluster on GCP (GKE)
	$(GCLOUD) container clusters create --help

.PHONY: k8s-ls
k8s-ls: | $(CLOUDSDK_CONFIG) ## List all GKE clusters running on GCP
	$(GCLOUD) container clusters list

.PHONY: k8s-rm
k8s-rm: | $(CLOUDSDK_CONFIG) ## Delete our GKE cluster
	$(GCLOUD) container clusters delete $(CLUSTER)

.PHONY: chaos-operator
chaos-operator: | $(KUBECONFIG) ## Install Chaos Mesh Operator
	$(CURL) -sSL https://mirrors.chaos-mesh.org/latest/install.sh | bash

MONITORING_DIR := k8s/monitoring-stack
.PHONY: monitoring-stack
monitoring-stack: ## Deploy a monitoring stack
	$(DOCKER) run --user $$(id -u):$$(id -g) --rm -v $(PWD)/$(MONITORING_DIR):/$(MONITORING_DIR) --workdir /$(MONITORING_DIR) quay.io/coreos/jsonnet-ci ./build.sh monitoringstack.jsonnet
	$(KUBECTL) apply --filename $(MONITORING_DIR)/manifests/setup
	$(KUBECTL) apply --filename $(MONITORING_DIR)/manifests
	$(KUBECTL) apply --filename $(MONITORING_DIR)/rabbitmq

teardown-monitoring-stack: ## Teardown the deployed monitoring stack
	$(KUBECTL) delete --filename $(MONITORING_DIR)/rabbitmq --ignore-not-found
	$(KUBECTL) delete --filename $(MONITORING_DIR)/manifests --ignore-not-found
	$(KUBECTL) delete --filename $(MONITORING_DIR)/manifests/setup --ignore-not-found

.PHONY: rabbitmq-operator
rabbitmq-operator: | $(KUBECONFIG) ## Install RabbitMQ Cluster Operator into K8S
	$(KUBECTL) apply --filename https://github.com/rabbitmq/cluster-operator/releases/download/$(RABBITMQ_OPERATOR_VERSION)/cluster-operator.yml

# TODO: Make this not GKE-specific
.PHONY: rabbitmq-production-cluster
rabbitmq-production-cluster: | rabbitmq-operator ## Install the production-ready RabbitMQ cluster
	$(KUBECTL) apply --namespace rabbitmq-system --filename https://raw.githubusercontent.com/rabbitmq/cluster-operator/$(RABBITMQ_OPERATOR_VERSION)/docs/examples/production-ready/ssd-gke.yaml
	$(KUBECTL) apply --namespace rabbitmq-system --filename https://raw.githubusercontent.com/rabbitmq/cluster-operator/$(RABBITMQ_OPERATOR_VERSION)/docs/examples/production-ready/rabbitmq.yaml
