include ../../Makefile

NAMESPACE := tgir-s01e02-$(USER)

# https://hub.docker.com/_/rabbitmq?tab=tags
# https://hub.docker.com/r/pivotalrabbitmq/rabbitmq-prometheus/tags?page=1&name=3.8.3
DOCKER_RABBITMQ_IMAGE ?= pivotalrabbitmq/rabbitmq-prometheus:3.8.3-alpha.99-2020.02.23
# https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
DOCKER_RABBITMQ_PERFTEST_IMAGE := pivotalrabbitmq/perf-test:2.10.0

amqp_PORT := 5672
management_PORT := 15672
prometheus_PORT := 15692
netdata_PORT := 19999

30_DAYS := $$((30*24*3600*1000))
26_KB := $$((26*1024))
1_MILLION := 1000000

#   https://github.com/rabbitmq/tgir/issues/5#issuecomment-581384417
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
durable_backlog_MACHINE_TYPE := n1-standard-1
durable_drain_MACHINE_TYPE := n1-standard-1
durable_workload_MACHINE_TYPE := f1-micro
durable_rabbitmq_MACHINE_TYPE := n1-highmem-8
durable_rabbitmq_DISK_SIZE := 2000GB
durable_QUEUES := 75
durable_PUBLISHERS := $(durable_QUEUES)
durable_PUBLISH_EVERY := 30
durable_CONSUMERS := $(durable_QUEUES)
durable_CONSUMER_PREFETCH := 50
durable_QUEUE_EXPIRES := $(30_DAYS)
durable_MESSAGE_TTL := $(30_DAYS)
durable_MESSAGE_SIZE := $(26_KB)
durable_BACKLOG_QUEUES := 50
durable_MAX_MESSAGES_PER_BACKLOG_QUEUE := $(1_MILLION)

# You may want to overwrite this with your GCP project, e.g. export GCP_PROJECT=my-project-name
GCP_PROJECT ?= cf-rabbitmq-core
# You may want to overwrite this with your preferred GCP zone, e.g. export GCP_ZONE=us-east1-b
GCP_ZONE ?= europe-west2-b

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

define GCP_COS_CONTAINER_DEFAULTS
--public-dns \
--boot-disk-type=pd-ssd \
--labels=namespace=$(NAMESPACE) \
--container-stdin \
--container-tty
endef

# https://cloud.google.com/compute/docs/containers/deploying-containers
# https://cloud.google.com/compute/pricing
rabbitmq-%: $(GCLOUD) ## Create RabbitMQ server
	time $(GCLOUD) compute instances create-with-container $(NAMESPACE)-$@ \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=$($*_rabbitmq_MACHINE_TYPE) \
	  --create-disk=name=$(NAMESPACE)-$@-persistent,size=$($*_rabbitmq_DISK_SIZE),type=pd-ssd,auto-delete=yes \
	  --container-mount-disk=name=$(NAMESPACE)-$@-persistent,mount-path=/var/lib/rabbitmq \
	  --container-env RABBITMQ_ERLANG_COOKIE=$(NAMESPACE) \
	  --container-image=$(DOCKER_RABBITMQ_IMAGE)

define EXTERNAL_IP
$(GCLOUD) compute instances describe $(NAMESPACE)-$* \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
endef

management-%: $(GCLOUD) firewall-allow-management ## Open RabbitMQ Management
	open http://$(shell $(EXTERNAL_IP)):$(management_PORT)

prometheus-%: $(GCLOUD) firewall-allow-prometheus ## Open RabbitMQ Prometheus
	open http://$(shell $(EXTERNAL_IP)):$(prometheus_PORT)/metrics

firewall-allow-%: $(GCLOUD)
	$(GCLOUD) compute firewall-rules describe $(USER)-$(HOSTNAME)-allow-$* \
	|| $(GCLOUD) compute firewall-rules create $(USER)-$(HOSTNAME)-allow-$* \
		--allow=TCP:$($*_PORT) --source-ranges=$(shell curl -s https://api.ipify.org)/32

firewall-deny-%: $(GCLOUD)
	$(GCLOUD) compute firewall-rules describe $(USER)-$(HOSTNAME)-allow-$* \
	&& $(GCLOUD) compute firewall-rules delete $(USER)-$(HOSTNAME)-allow-$*

delete-%: $(GCLOUD) ## Delete instance
	time $(GCLOUD) compute instances delete $(NAMESPACE)-$*

ssh-%: $(GCLOUD) ## Open SSH session
	$(GCLOUD) compute ssh $(NAMESPACE)-$*

bash-%: $(GCLOUD) ## Open a shell session on instance
	$(GCLOUD) compute ssh $(NAMESPACE)-$* -- \
	  "docker exec -it \$$(docker container ls | awk '/$*/ { print \$$1 }') bash"

# https://github.com/bcicen/ctop
define CTOP_CONTAINER
docker run --rm --interactive --tty \
  --cpus 0.5 --memory 128M \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --name ctop \
  quay.io/vektorlab/ctop
endef
ctop-%: $(GCLOUD) ## Open ctop session
	$(GCLOUD) compute ssh $(NAMESPACE)-$* -- "$(CTOP_CONTAINER)"

# https://github.com/hishamhm/htop
define HTOP_CONTAINER
docker run --rm --interactive --tty \
  --cpus 0.5 --memory 128M \
  --net="host" --pid="host" \
  --name htop \
  jess/htop
endef
htop-%: $(GCLOUD) ## Open htop session
	$(GCLOUD) compute ssh $(NAMESPACE)-$* -- "$(HTOP_CONTAINER)"

# https://docs.netdata.cloud/packaging/docker/#run-netdata-with-the-docker-command
define NETDATA_CONTAINER
docker container inspect --format '{{.State.Status}}' netdata \
|| docker run --detach --name=netdata \
   --cpus 1 --memory 8G \
   --publish $(netdata_PORT):$(netdata_PORT) \
   --volume /etc/passwd:/host/etc/passwd:ro \
   --volume /etc/group:/host/etc/group:ro \
   --volume /proc:/host/proc:ro \
   --volume /sys:/host/sys:ro \
   --volume /etc/os-release:/host/etc/os-release:ro \
   --cap-add SYS_PTRACE \
   --security-opt apparmor=unconfined \
   netdata/netdata
endef
netdata-%: $(GCLOUD) firewall-allow-netdata ## Start netdata & open dashboard
	$(GCLOUD) compute ssh $(NAMESPACE)-$* -- "$(NETDATA_CONTAINER)" \
	&& open http://"$$($(EXTERNAL_IP))":$(netdata_PORT)

define durable_PERFTEST_DEFAULTS
--container-image=$(DOCKER_RABBITMQ_PERFTEST_IMAGE) \
--container-arg="--auto-delete" \
--container-arg="false" \
--container-arg="--exchange" \
--container-arg="topic" \
--container-arg="--flag" \
--container-arg="persistent" \
--container-arg="--size" \
--container-arg="$($*_MESSAGE_SIZE)" \
--container-arg="--type" \
--container-arg="topic" \
--container-arg="--uri" \
--container-arg="amqp://guest:guest@$(NAMESPACE)-rabbitmq-$*.c.$(GCP_PROJECT).internal:$(amqp_PORT)/%2f"
endef

define durable_backlog_PERFTEST_CONFIG
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
--container-arg="$(durable_BACKLOG_QUEUES)" \
--container-arg="--queue-args" \
--container-arg="x-max-length=$(durable_MAX_MESSAGES_PER_BACKLOG_QUEUE)" \
--container-arg="--queue-pattern" \
--container-arg="backlog%d" \
--container-arg="--queue-pattern-from" \
--container-arg="1" \
--container-arg="--queue-pattern-to" \
--container-arg="$(durable_BACKLOG_QUEUES)"
endef
backlog-%: $(GCLOUD) ## Simulate message backlog
	time $(GCLOUD) compute instances create-with-container $(NAMESPACE)-$@ \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=$($*_backlog_MACHINE_TYPE) \
	  $($*_backlog_PERFTEST_CONFIG) \
	  $($*_PERFTEST_DEFAULTS) \
	|| time $(GCLOUD) compute instances update-container $(NAMESPACE)-$@ \
	  $($*_backlog_PERFTEST_CONFIG) \
	  $($*_PERFTEST_DEFAULTS)

define durable_drain_PERFTEST_CONFIG
--container-arg="--autoack" \
--container-arg="--consumers" \
--container-arg="$(durable_BACKLOG_QUEUES)" \
--container-arg="--producers" \
--container-arg="0" \
--container-arg="--queue-args" \
--container-arg="x-max-length=$(durable_MAX_MESSAGES_PER_BACKLOG_QUEUE)" \
--container-arg="--queue-pattern" \
--container-arg="backlog%d" \
--container-arg="--queue-pattern-from" \
--container-arg="1" \
--container-arg="--queue-pattern-to" \
--container-arg="$(durable_BACKLOG_QUEUES)"
endef
drain-%: $(GCLOUD) ## Simulate message drain
	time $(GCLOUD) compute instances create-with-container $(NAMESPACE)-$@ \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=$($*_drain_MACHINE_TYPE) \
	  $($*_drain_PERFTEST_CONFIG) \
	  $(RABBITMQ_PERFTEST_DEFAULTS) \
	|| time $(GCLOUD) compute instances update-container $(NAMESPACE)-$@ \
	  $($*_drain_PERFTEST_CONFIG) \
	  $($*_PERFTEST_DEFAULTS)

define durable_workload_PERFTEST_CONFIG
--container-arg="--consumers" \
--container-arg="$(durable_CONSUMERS)" \
--container-arg="--producers" \
--container-arg="$(durable_PUBLISHERS)" \
--container-arg="--publishing-interval" \
--container-arg="$(durable_PUBLISH_EVERY)" \
--container-arg="--qos" \
--container-arg="$(durable_CONSUMER_PREFETCH)" \
--container-arg="--queue-args" \
--container-arg="x-expires=$(durable_QUEUE_EXPIRES),x-message-ttl=$(durable_MESSAGE_TTL)" \
--container-arg="--queue-pattern" \
--container-arg="q%d" \
--container-arg="--queue-pattern-from" \
--container-arg="1" \
--container-arg="--queue-pattern-to" \
--container-arg="$(durable_QUEUES)"
endef
workload-%: $(GCLOUD) ## Simulate workload
	time $(GCLOUD) compute instances create-with-container $(NAMESPACE)-$@ \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=$($*_workload_MACHINE_TYPE) \
	  $($*_workload_PERFTEST_CONFIG) \
	  $(RABBITMQ_PERFTEST_DEFAULTS)
	|| time $(GCLOUD) compute instances update-container $(NAMESPACE)-$@ \
	  $($*_workload_PERFTEST_CONFIG) \
	  $(RABBITMQ_PERFTEST_DEFAULTS)
