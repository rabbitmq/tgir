include ../../Makefile

TGIR := tgir-s01e06
CLUSTER := $(TGIR)-$(USER)
# Find out what versions are available: make k8s-versions
# K8S versions valid at 28 September 2020
# Pick the latest available version for the control plane, but previous version for the nodes so that we can upgrade
CLUSTER_VERSION ?= 1.18.6-gke.4801
CLUSTER_NODE_VERSION ?= 1.17.9-gke.1504
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
k9s: | $(K9S) $(KUBECONFIG) ## Interact with our K8S cluster via a terminal UI
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
	   --release-channel $(CLUSTE_RELEASES) \
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
	   --max-unavailable-upgrade 1 \
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
rabbitmq: | $(KUBECONFIG) generate-secrets ## Deploy a reliable RabbitMQ cluster on GKE
	$(KUBECTL) apply --filename $(CURDIR)/k8s

.PHONY: rabbitmq-clients
rabbitmq-clients: | $(KUBECONFIG) generate-secrets ## Deploy reliable RabbitMQ clients on our K8S cluster running in GCP
	$(KUBECTL) apply --filename $(CURDIR)/k8s/deployment.consumer \
	&& $(KUBECTL) apply --filename $(CURDIR)/k8s/deployment.publisher

define SERVICE_IP
$(KUBECTL) get service reliable-rabbit-public -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
endef
.PHONY: rabbitmq-management
rabbitmq-management: | $(KUBECONFIG) ## Open RabbitMQ Management in a browser
	@while sleep 1; do \
	  if [ "$$($(SERVICE_IP) 2>/dev/null)" != "" ]; then \
	    break; \
	  else \
	    echo "Waiting for public IP to be assigned to our RabbitMQ deployment..."; \
	  fi \
	done
	open http://$$($(SERVICE_IP)):15672

.PHONY: k8s-operations
k8s-operations: | $(CLOUDSDK_CONFIG) $(BAT)
	$(GCLOUD) container operations list --format json \
	| $(BAT) --language json

.PHONY: k8s-upgrade
k8s-upgrade: | $(CLOUDSDK_CONFIG) ## Upgrade node pool to control plane version - up to 10 minutes
	$(GCLOUD) container clusters upgrade $(CLUSTER)

.PHONY: rabbitmq-upgrade
rabbitmq-upgrade: | $(YQ) $(KUBECONFIG) ## Upgrade RabbitMQ
	$(YQ) merge $(CURDIR)/k8s/statefulset.$(@) \
	  $(CURDIR)/k8s/statefulset.yml \
	| $(KUBECTL) apply --filename -

.PHONY: k8s-force-repair
k8s-force-repair: | $(CLOUDSDK_CONFIG)
	$(GCLOUD) container clusters resize $(CLUSTER) \
	  --node-pool default-pool \
	  --num-nodes $(CLUSTER_NODES_PER_ZONE)

define INSTANCES_TO_DELETE
$(GCLOUD) compute instances list \
	      --filter "zone:($(ZONES)) AND name ~ $(CLUSTER)" --format "value(name,zone)"
endef
.PHONY: _delete_zone
_delete_zone: | $(CLOUDSDK_CONFIG)
	$(INSTANCES_TO_DELETE) \
	| awk '{ system("$(GCLOUD) compute instances delete "$$1" --zone="$$2" --quiet 1>/dev/null &") }'

.PHONY: simulate-loss-of-minority
simulate-loss-of-minority: ZONES = $(GCP_REGION)-a
simulate-loss-of-minority: | _delete_zone  ## Simulate losing all instances in 1 zone (minority)

.PHONY: simulate-loss-of-majority
simulate-loss-of-majority: ZONES = $(GCP_REGION)-a $(GCP_REGION)-b
simulate-loss-of-majority: | _delete_zone ## Simulate losing all instances in 2 zones (majority)

.PHONY: 
simulate-loss-of-all: ZONES = $(GCP_REGION)-a $(GCP_REGION)-b $(GCP_REGION)-c
simulate-loss-of-all: | _delete_zone ## Simulate losing all instances across all 3 zones

.PHONY: rabbitmq-clients-rm
rabbitmq-clients-rm: | $(KUBECONFIG) ## Delete all RabbitMQ clients
	$(KUBECTL) delete --filename $(CURDIR)/k8s/deployment.publisher --wait \
	; $(KUBECTL) delete --filename $(CURDIR)/k8s/deployment.consumer --wait

.PHONY: rabbitmq-rm
rabbitmq-rm: | $(KUBECONFIG) ## Delete the RabbitMQ cluster and all associated resources that we have deployed
	$(KUBECTL) delete --filename $(CURDIR)/k8s --wait \
	; $(KUBECTL) delete pvc --all --wait

.PHONY: all
all: k8s rabbitmq ## Create K8S cluster & deploy RabbitMQ

.PHONY: clean
clean: rabbitmq-clients-rm rabbitmq-rm k8s-rm ## Delete the RabbitMQ cluster and all associated resources, then delete the K8S cluster on GKE that we have deployed
