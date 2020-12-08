include $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))/../../Makefile

TGIR := tgir-s01e09
CLUSTER := $(TGIR)-$(USER)
# Find out what versions are available: make k8s-versions
# K8S versions valid at 04 December 2020
CLUSTER_VERSION ?= 1.18.10-gke.2701
CLUSTER_NODE_VERSION ?= 1.18.10-gke.2701
CLUSTER_RELEASES ?= rapid
CLUSTER_NODE_TYPE ?= n2-standard-4
CLUSTER_NODES_PER_ZONE ?= 2

# You may want to overwrite this with your GCP project, e.g. export GCP_PROJECT=my-project-name
GCP_PROJECT ?= cf-rabbitmq-core
# You may want to overwrite this with your preferred GCP region, e.g. export GCP_REGION=us-east1
GCP_REGION ?= europe-west2

# https://github.com/rabbitmq/cluster-operator/releases
RABBITMQ_OPERATOR_VERSION := v1.2.0

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
export PATH=$(LOCAL_BIN):$$PATH
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
env:: | $(CLOUDSDK_CONFIG) $(KUBECONFIG_DIR) $(KUBECTL) ## Configure shell env - eval "$(make env)" OR source .env
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

define POSTINSTALL_OUTPUT
Install complete.

To access Grafana, access https://localhost:3000 after running:
kubectl --namespace monitoring port-forward svc/grafana 3000

To access Chaos Mesh Dashboard, access https://localhost:2333 after running:
kubectl --namespace chaos-testing port-forward svc/chaos-dashboard 2333
endef

.PHONY: all
all: | k8s monitoring-stack chaos-operator rabbitmq-operator ## Create the cluster & stacks needed for the episode in GKE - Chaos Mesh, Grafana, Prometheus & RabbitMQ Operator
	@echo "$$POSTINSTALL_OUTPUT"

.PHONY: k8s-help
k8s-help: | $(CLOUDSDK_CONFIG) ## List all options available when creating a managed K8S cluster on GCP (GKE)
	$(GCLOUD) container clusters create --help

.PHONY: k8s-ls
k8s-ls: | $(CLOUDSDK_CONFIG) ## List all GKE clusters running on GCP
	$(GCLOUD) container clusters list

.PHONY: k8s-rm
k8s-rm: | $(CLOUDSDK_CONFIG) ## Delete our GKE cluster
	$(GCLOUD) container clusters delete $(CLUSTER)

# https://github.com/chaos-mesh/chaos-mesh/releases
CHAOS_MESH_VERSION := v1.0.2
.PHONY: chaos-operator
chaos-operator: | $(KUBECONFIG) ## Install Chaos Mesh Operator
	$(CURL) -sSL https://mirrors.chaos-mesh.org/$(CHAOS_MESH_VERSION)/install.sh | bash

.PHONY: teardown-chaos-operator
teardown-chaos-operator: | $(KUBECONFIG) ## Remove Chaos Mesh Operator
	$(CURL) -sSL https://mirrors.chaos-mesh.org/$(CHAOS_MESH_VERSION)/install.sh | bash -s -- --template | $(KUBECTL) delete -f -

# helm search repo --versions prometheus-community/kube-prometheus-stack
KUBE_PROMETHEUS_STACK_VERSION ?= 12.2.3
.PHONY: monitoring-stack
monitoring-stack: | $(KUBECONFIG) $(HELM) ## Integrate Prometheus & Grafana with K8S, including system metrics
	$(KUBECTL) create namespace monitoring
	$(HELM) repo add prometheus-community https://prometheus-community.github.io/helm-charts
	$(HELM) upgrade prometheus prometheus-community/kube-prometheus-stack \
	  --install \
		--namespace monitoring \
	  --version $(KUBE_PROMETHEUS_STACK_VERSION) \
	  --values k8s/monitoring-stack/values.yml
	$(KUBECTL) apply \
	  --filename k8s/monitoring-stack/traefik-servicemonitor.yml \
	  --filename k8s/monitoring-stack/dashboards

.PHONY: teardown-monitoring-stack
teardown-monitoring-stack: | $(KUBECONFIG) $(HELM) ## Teardown the whole monitoring stack
	$(KUBECTL) delete --filename k8s/monitoring-stack/dashboards --ignore-not-found
	$(KUBECTL) delete --filename k8s/monitoring-stack/traefik-servicemonitor.yml --ignore-not-found
	$(HELM) uninstall --namespace monitoring prometheus
	$(HELM) repo remove prometheus-community
	$(KUBECTL) delete namespace monitoring --ignore-not-found

.PHONY: rabbitmq-operator
rabbitmq-operator: | $(KUBECONFIG) ## Install RabbitMQ Cluster Operator into K8S
	$(KUBECTL) apply --filename https://github.com/rabbitmq/cluster-operator/releases/download/$(RABBITMQ_OPERATOR_VERSION)/cluster-operator.yml

.PHONY: teardown-rabbitmq-operator
teardown-rabbitmq-operator: | $(KUBECONFIG) ## Teardown the RabbitMQ Cluster Operator
	$(KUBECTL) delete --ignore-not-found --filename https://github.com/rabbitmq/cluster-operator/releases/download/$(RABBITMQ_OPERATOR_VERSION)/cluster-operator.yml

.PHONY: rabbitmq-production-cluster
rabbitmq-production-cluster: | rabbitmq-operator ## Install the production-ready RabbitMQ cluster
	$(KUBECTL) apply --namespace rabbitmq-system --filename k8s/rabbitmq/ssd-gke.yaml
	$(KUBECTL) apply --namespace rabbitmq-system --filename k8s/rabbitmq/pod-disruption-budget.yaml
	$(KUBECTL) apply --namespace rabbitmq-system --filename k8s/rabbitmq/clusters/partition-ignore.yaml

.PHONY: teardown-production-cluster
teardown-production-cluster: | $(KUBECTL) ## Teardown the production-ready RabbitMQ cluster
	$(KUBECTL) delete --namespace rabbitmq-system --ignore-not-found --filename k8s/rabbitmq/clusters/partition-ignore.yaml
	$(KUBECTL) delete --ignore-not-found --filename k8s/rabbitmq/ssd-gke.yaml
	$(KUBECTL) delete --namespace rabbitmq-system --ignore-not-found --filename k8s/rabbitmq/pod-disruption-budget.yaml

.PHONY: quorum-clients
quorum-clients: | $(KUBECONFIG) ## Create RabbitMQ clients to start 1000 quorum queues
	$(KUBECTL) apply --namespace rabbitmq-system --filename k8s/rabbitmq/clients/perf-test-quorum.yaml

.PHONY: teardown-quorum-clients
teardown-quorum-clients: | $(KUBECONFIG) ## Delete quorum queue RabbitMQ clients
	$(KUBECTL) delete --namespace rabbitmq-system --ignore-not-found --filename k8s/rabbitmq/clients/perf-test-quorum.yaml

.PHONY: rebalance-queues
rebalance-queues: | $(KUBECONFIG) ## Exec into RabbitMQ Pod to rebalance queue leaders across cluster
	$(KUBECTL) exec --namespace rabbitmq-system svc/production-ready -- rabbitmq-queues rebalance all

.PHONY: clear-chaos
clear-chaos: | $(KUBECONFIG) ## Clear any Chaos Mesh events from the cluster
	$(KUBECTL) delete --ignore-not-found --filename k8s/chaos-experiments

.PHONY: chaos-az-latency
chaos-az-latency: | $(KUBECONFIG) ## Introduce 1s of latency to&from a random pod in the cluster for 1m every 5m
	$(KUBECTL) apply --filename k8s/chaos-experiments/cluster-latency.yaml

.PHONY: chaos-az-partition
chaos-az-partition: | $(KUBECONFIG) ## Create a network partition seperating one RabbitMQ node completely from the other two
	$(KUBECTL) apply --filename k8s/chaos-experiments/cluster-partition.yaml

.PHONY: chaos-intra-node-partition
chaos-intra-node-partition: | $(KUBECONFIG) ## Create a network partition only between two of the nodes, leaving other connections intact
	$(KUBECTL) apply --filename k8s/chaos-experiments/intra-node-partition.yaml

.PHONY: chaos-cpu-stealing
chaos-cpu-stealing: | $(KUBECONFIG) ## Cause CPU pressure in a random RabbitMQ pod, simulating CPU stealing
	$(KUBECTL) apply --filename k8s/chaos-experiments/cpu-stealing.yaml

.PHONY: chaos-memory-filling
chaos-memory-filling: | $(KUBECONFIG) ## Cause memory pressure in a random RabbitMQ pod, reducing available memory for RabbitMQ
	$(KUBECTL) apply --filename k8s/chaos-experiments/memory-filling.yaml

.PHONY: chaos-slow-disk
chaos-slow-disk: | $(KUBECONFIG) ## Add latency to file I/O operations to simulate a slow disk on a random RabbitMQ pod
	$(KUBECTL) apply --filename k8s/chaos-experiments/disk-latency.yaml

