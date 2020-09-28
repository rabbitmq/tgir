include ../../Makefile

TGIR := tgir-s01e06
CLUSTER := $(TGIR)-$(USER)
# Pick the one but last, so that we can upgrade
# Find out what versions are available: make k8s-versions
CLUSTER_VERSION ?= 1.17.9-gke.1504
CLUSTE_RELEASES ?= rapid
CLUSTER_NODE_TYPE ?= n2-standard-4
CLUSTER_NODES_PER_ZONE ?= 2

# You may want to overwrite this with your GCP project, e.g. export GCP_PROJECT=my-project-name
GCP_PROJECT ?= cf-rabbitmq-core
# You may want to overwrite this with your preferred GCP region, e.g. export GCP_REGION=us-east1
GCP_REGION ?= europe-west2

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
k9s: | $(K9S) $(KUBECONFIG) ## Interact with K8S via terminal UI
	$(K9S) --all-namespaces

define ENV
export XDG_CONFIG_HOME="$(XDG_CONFIG_HOME)"
export KUBECONFIG="$(KUBECONFIG)"
export CLOUDSDK_CONFIG="$(CLOUDSDK_CONFIG)"
unalias k 2>/dev/null; alias k=kubectl
unalias m 2>/dev/null; alias m=make
endef
export ENV
.PHONY: env
env:: | $(CLOUDSDK_CONFIG) $(KUBECONFIG_DIR) ## Configure shell env - eval "$(make env)"
	@echo "$$ENV"

.PHONY: k8s-versions
k8s-versions: | $(CLOUDSDK_CONFIG) ## List all available K8S versions
	$(GCLOUD) container get-server-config

.PHONY: k8s
k8s: | $(CLOUDSDK_CONFIG) ## Create K8S cluster
	$(GCLOUD) container clusters describe $(CLUSTER) \
	|| $(GCLOUD) container clusters create $(CLUSTER) \
	   --release-channel $(CLUSTE_RELEASES) \
	   --cluster-version $(CLUSTER_VERSION) \
	   --machine-type $(CLUSTER_NODE_TYPE) \
	   --num-nodes $(CLUSTER_NODES_PER_ZONE) \
	   --enable-shielded-nodes \
	   --disk-type "pd-ssd" \
	   --disk-size "100" \
	   --enable-ip-alias \
	   --enable-autoupgrade \
	   --enable-autorepair \
	   --max-surge-upgrade "1" \
	   --max-unavailable-upgrade "1" \
	   --metadata disable-legacy-endpoints=true \
	   --no-enable-master-authorized-networks \
	   --addons "HorizontalPodAutoscaling,HttpLoadBalancing"

.PHONY: k8s-help
k8s-help: | $(CLOUDSDK_CONFIG) ## List all options available when creating a cluster
	$(GCLOUD) container clusters create --help

.PHONY: k8s-ls
k8s-ls: | $(CLOUDSDK_CONFIG) ## List K8S clusters
	$(GCLOUD) container clusters list

.PHONY: k8s-rm
k8s-rm: | $(CLOUDSDK_CONFIG) ## Delete K8S cluster
	$(GCLOUD) container clusters delete $(CLUSTER)

.PHONY: generate-secrets
generate-secrets::

k8s/secret.default-user.yml: $(KUBECTL)
	$(KUBECTL) create secret generic default-user \
	  --dry-run=client --output=yaml --from-literal=value="default_user = $(RABBITMQ_DEFAULT_USER)" > $(@)
generate-secrets:: k8s/secret.default-user.yml

k8s/secret.default-pass.yml: $(KUBECTL)
	$(KUBECTL) create secret generic default-pass \
	  --dry-run=client --output=yaml --from-literal=value="default_pass = $(RABBITMQ_DEFAULT_PASS)" > $(@)
generate-secrets:: k8s/secret.default-pass.yml

k8s/secret.erlang-cookie.yml: $(KUBECTL)
	$(KUBECTL) create secret generic erlang-cookie \
	  --dry-run=client --output=yaml --from-literal=value="$(RABBITMQ_ERLANG_COOKIE)" > $(@)
generate-secrets:: k8s/secret.erlang-cookie.yml

.PHONY: rabbitmq
rabbitmq: | $(KUBECONFIG) generate-secrets ## Deploy a RabbitMQ cluster on K8S
	$(KUBECTL) apply --filename $(CURDIR)/k8s

.PHONY: rabbitmq-rm
rabbitmq-rm: | $(KUBECONFIG) ## Delete RabbitMQ cluster and all associated resources
	$(KUBECTL) delete --filename $(CURDIR)/k8s --wait \
	; $(KUBECTL) delete pvc --all --wait

.PHONY: all
all: k8s rabbitmq ## Create K8S cluster & deploy RabbitMQ

.PHONY: clean
clean: rabbitmq-rm k8s-rm ## Delete RabbitMQ cluster and all associated resources, then delete K8S cluster
