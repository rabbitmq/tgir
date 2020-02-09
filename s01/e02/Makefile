include ../../Makefile

NAMESPACE := tgir-s01e02-$(USER)

# https://hub.docker.com/_/rabbitmq?tab=tags
DOCKER_RABBITMQ_37x_IMAGE = rabbitmq:3.7.2-management
DOCKER_RABBITMQ_38x_IMAGE = rabbitmq:3.8.2-management
DOCKER_RABBITMQ_IMAGE ?= $(DOCKER_RABBITMQ_37x_IMAGE)
# https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
DOCKER_RABBITMQ_PERFTEST_IMAGE := pivotalrabbitmq/perf-test:2.10.0

RMQ_NODE ?= 1
RMQ_MANAGEMENT_PORT := 15672
QUEUES := 75
PUBLISHERS := $(QUEUES)
PUBLISH_EVERY := 30
CONSUMERS := $(QUEUES)
CONSUMER_PREFETCH := 50
QUEUE_EXPIRES := $$((30*24*3600))# 30 days
MESSAGE_TTL := $$((30*24*3600))# 30 days
MESSAGE_SIZE := $$((26*1024))# 26KB

BACKLOG_QUEUES := 50
MAX_MESSAGES_PER_BACKLOG_QUEUE := 1000000

#   IDLE MESSAGES:
#    2 * 12000000
#    5 *  3000000
#    3 *  1000000
#   14 *   500000
# ---------------
#        49000000
#          @ 26KB
# ---------------
#        1.215 TB

DISK_SIZE := 2000GB

# You may want to overwrite this with your GCP project, e.g. export GCP_PROJECT=my-project-name
GCP_PROJECT ?= cf-rabbitmq-core
# You may want to overwrite this with your preferred GCP zone, e.g. export GCP_ZONE=us-east1-b
GCP_ZONE ?= europe-west2-b

GCLOUD ?= /usr/local/bin/gcloud
$(GCLOUD):
	brew cask install google-cloud-sdk

.PHONY: deps
deps: $(GCLOUD) ## Resolve all dependencies
	$(GCLOUD) auth login \
	&& $(GCLOUD) config set project $(GCP_PROJECT) \
	&& $(GCLOUD) config set compute/zone $(GCP_ZONE)

instances: $(GCLOUD) ## List all instances
	$(GCLOUD) compute instances list --filter='name ~ $(NAMESPACE)'

# https://cloud.google.com/logging/docs/view/advanced-queries

logs: $(GCLOUD)
	open "https://console.cloud.google.com/logs/viewer?project=$(GCP_PROJECT)&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2F$(GCP_PROJECT)%2Flogs%2Fcos_containers%0ANOT%20jsonPayload.message:%22consumer%20latency%22%0ANOT%20jsonPayload.message:%22has%20a%20client-provided%20name%22%0ANOT%20jsonPayload.message:%22authenticated%20and%20granted%20access%22%0ANOT%20jsonPayload.message:%22starting%20producer%22%0ANOT%20jsonPayload.message:%22starting%20consumer%22%0ANOT%20jsonPayload.message:%22accepting%20AMQP%20connection%22"

logs-lifecyle: $(GCLOUD)
	open "https://console.cloud.google.com/logs/viewer?project=$(GCP_PROJECT)&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2F$(GCP_PROJECT)%2Flogs%2Fcos_containers%0AjsonPayload.message:%20(%22starting%20rabbitmq%22%20OR%20%22started%22%20OR%20%22stopping%22%20OR%20%22stopped%22%20AND%20NOT%20%22supervisor%22)"

define GCP_COS_CONTAINER_DEFAULTS
--public-dns \
--boot-disk-type=pd-ssd \
--labels=namespace=$(NAMESPACE) \
--container-stdin \
--container-tty
endef

# https://cloud.google.com/compute/docs/containers/deploying-containers
# https://cloud.google.com/compute/pricing
server: $(GCLOUD) ## Create RabbitMQ node
	time $(GCLOUD) compute instances create-with-container $(NAMESPACE)-rmq$(RMQ_NODE)-server \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=n1-highmem-8 \
	  --create-disk=name=$(NAMESPACE)-rmq$(RMQ_NODE)-server-persistent,size=$(DISK_SIZE),type=pd-ssd,auto-delete=yes \
	  --container-mount-disk=name=$(NAMESPACE)-rmq$(RMQ_NODE)-server-persistent,mount-path=/var/lib/rabbitmq \
	  --container-env RABBITMQ_ERLANG_COOKIE=$(NAMESPACE) \
	  --container-image=$(DOCKER_RABBITMQ_IMAGE)

define RMQ_SERVER_EXTERNAL_IP
$(GCLOUD) compute instances describe $(NAMESPACE)-rmq$(RMQ_NODE)-server \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
endef
management: $(GCLOUD) management-allow ## Open RabbitMQ Management
	open http://"$$($(RMQ_SERVER_EXTERNAL_IP))":$(RMQ_MANAGEMENT_PORT)

management-deny: $(GCLOUD)
	$(GCLOUD) compute firewall-rules describe $(USER)-allow-rmq-management \
	&& $(GCLOUD) compute firewall-rules delete $(USER)-allow-rmq-management

management-allow: $(GCLOUD)
	$(GCLOUD) compute firewall-rules describe $(USER)-allow-rmq-management \
	|| $(GCLOUD) compute firewall-rules create $(USER)-allow-rmq-management \
		--allow=TCP:$(RMQ_MANAGEMENT_PORT) --source-ranges=$(shell curl -s https://api.ipify.org)/32

server-delete: INSTANCE = rmq$(RMQ_NODE)-server
server-delete: _delete ## Delete RabbitMQ node

server-ssh: INSTANCE = rmq$(RMQ_NODE)-server
server-ssh: _ssh ## SSH to RabbitMQ node

server-bash: INSTANCE = rmq$(RMQ_NODE)-server
server-bash: _bash ## Open a shell session on RabbitMQ node

server-ctop: INSTANCE = rmq$(RMQ_NODE)-server
server-ctop: _ctop ## Run ctop on VM that runs RabbitMQ node

server-htop: INSTANCE = rmq$(RMQ_NODE)-server
server-htop: _htop ## Run htop on VM that runs RabbitMQ node

backlog: INSTANCE = rmq$(RMQ_NODE)-backlog
backlog: _backlog ## Simulate RabbitMQ message backlog

backlog-stop: INSTANCE = rmq$(RMQ_NODE)-backlog
backlog-stop: _delete ## Stop RabbitMQ message backlog

backlog-ctop: INSTANCE = rmq$(RMQ_NODE)-backlog
backlog-ctop: _ctop ## Run ctop on RabbitMQ message backlog

workload: INSTANCE = rmq$(RMQ_NODE)-workload
workload: _workload ## Simulate RabbitMQ production workload

workload-stop: INSTANCE = rmq$(RMQ_NODE)-workload
workload-stop: _delete ## Stop RabbitMQ production workload

workload-ctop: INSTANCE = rmq$(RMQ_NODE)-workload
workload-ctop: _ctop ## Run ctop on RabbitMQ production workload

_ssh: $(GCLOUD)
	$(GCLOUD) compute ssh $(NAMESPACE)-$(INSTANCE)

_bash: $(GCLOUD)
	$(GCLOUD) compute ssh $(NAMESPACE)-$(INSTANCE) -- \
	  "docker exec -it \$$(docker container ls | awk '/rabbitmq/ { print \$$1 }') bash"

_delete: $(GCLOUD)
	time $(GCLOUD) compute instances delete $(NAMESPACE)-$(INSTANCE)

# https://github.com/bcicen/ctop
define CTOP_CONTAINER
docker run --rm --interactive --tty \
  --cpus 0.5 --memory 128M \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --name ctop \
  quay.io/vektorlab/ctop
endef
_ctop: $(GCLOUD)
	$(GCLOUD) compute ssh $(NAMESPACE)-$(INSTANCE) -- "$(CTOP_CONTAINER)"

# https://github.com/hishamhm/htop
define HTOP_CONTAINER
docker run --rm --interactive --tty \
  --cpus 0.5 --memory 128M \
  --net="host" --pid="host" \
  --name htop \
  jess/htop
endef
_htop: $(GCLOUD)
	$(GCLOUD) compute ssh $(NAMESPACE)-$(INSTANCE) -- "$(HTOP_CONTAINER)"

define RABBITMQ_PERFTEST_DEFAULTS
--container-image=$(DOCKER_RABBITMQ_PERFTEST_IMAGE) \
--container-arg="--auto-delete" \
--container-arg="false" \
--container-arg="--exchange" \
--container-arg="topic" \
--container-arg="--flag" \
--container-arg="persistent" \
--container-arg="--size" \
--container-arg="$(MESSAGE_SIZE)" \
--container-arg="--type" \
--container-arg="topic" \
--container-arg="--uri" \
--container-arg="amqp://guest:guest@$(NAMESPACE)-rmq$(RMQ_NODE)-server.c.$(GCP_PROJECT).internal:5672/%2f"
endef

_backlog: $(GCLOUD)
	$(GCLOUD) compute instances create-with-container $(NAMESPACE)-$(INSTANCE) \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=n1-highcpu-2 \
	  --container-arg="--confirm" \
	  --container-arg="1" \
	  --container-arg="--confirm-timeout" \
	  --container-arg="120" \
	  --container-arg="--consumers" \
	  --container-arg="0" \
	  --container-arg="--heartbeat-sender-threads" \
	  --container-arg="10" \
	  --container-arg="--nio-threads" \
	  --container-arg="10" \
	  --container-arg="--nio-thread-pool" \
	  --container-arg="20" \
	  --container-arg="--producers" \
	  --container-arg="$(BACKLOG_QUEUES)" \
	  --container-arg="--queue-args" \
	  --container-arg="x-max-length=$(MAX_MESSAGES_PER_BACKLOG_QUEUE)" \
	  --container-arg="--queue-pattern" \
	  --container-arg="backlog%d" \
	  --container-arg="--queue-pattern-from" \
	  --container-arg="1" \
	  --container-arg="--queue-pattern-to" \
	  --container-arg="$(BACKLOG_QUEUES)" \
	  $(RABBITMQ_PERFTEST_DEFAULTS)

_workload: $(GCLOUD)
	$(GCLOUD) compute instances create-with-container $(NAMESPACE)-$(INSTANCE) \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=n1-highcpu-2 \
	  --container-arg="--consumers" \
	  --container-arg="$(CONSUMERS)" \
	  --container-arg="--producers" \
	  --container-arg="$(PUBLISHERS)" \
	  --container-arg="--publishing-interval" \
	  --container-arg="$(PUBLISH_EVERY)" \
	  --container-arg="--qos" \
	  --container-arg="$(CONSUMER_PREFETCH)" \
	  --container-arg="--queue-args" \
	  --container-arg="x-expires=$(QUEUE_EXPIRES),x-message-ttl=$(MESSAGE_TTL)" \
	  --container-arg="--queue-pattern" \
	  --container-arg="q%d" \
	  --container-arg="--queue-pattern-from" \
	  --container-arg="1" \
	  --container-arg="--queue-pattern-to" \
	  --container-arg="$(QUEUES)" \
	  $(RABBITMQ_PERFTEST_DEFAULTS)
