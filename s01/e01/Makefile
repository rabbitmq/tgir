include ../../Makefile

NAMESPACE := tgir-s01e01

# https://hub.docker.com/_/rabbitmq?tab=tags
DOCKER_RABBITMQ_37x_IMAGE = rabbitmq:3.7.23-management
DOCKER_RABBITMQ_38x_IMAGE = rabbitmq:3.8.2-management
# https://hub.docker.com/r/pivotalrabbitmq/perf-test/tags
DOCKER_RABBITMQ_PERFTEST_IMAGE := pivotalrabbitmq/perf-test:dev-2020.01.22


NUMBER_OF_QUEUES_PER_NODE := 4000
NUMBER_OF_MESSAGES_PER_QUEUE := 1000
MESSAGE_SIZE := 1000

instances: ## List all instances
	gcloud compute instances list --filter='name ~ $(NAMESPACE)'

rmq1-server: INSTANCE = rmq1-server
rmq1-server: _rmq-server ## Create RabbitMQ node

rmq1-server-delete: INSTANCE = rmq1-server
rmq1-server-delete: _delete ## Delete RabbitMQ node

rmq1-server-37x: INSTANCE = rmq1-server
rmq1-server-37x: _rmq-server-37x ## Ensure RabbitMQ node is running RabbitMQ v3.7.x

rmq1-server-38x: INSTANCE = rmq1-server
rmq1-server-38x: _rmq-server-38x ## Ensure RabbitMQ node is running RabbitMQ v3.8.x

rmq1-server-ssh: INSTANCE = rmq1-server
rmq1-server-ssh: _ssh ## SSH to RabbitMQ node

rmq1-server-bash: INSTANCE = rmq1-server
rmq1-server-bash: _bash ## Open a shell session on RabbitMQ node

rmq1-server-ctop: INSTANCE = rmq1-server
rmq1-server-ctop: _ctop ## Run ctop on VM that runs RabbitMQ node

rmq1-server-htop: INSTANCE = rmq1-server
rmq1-server-htop: _htop ## Run htop on VM that runs RabbitMQ node

rmq1-messages-start: INSTANCE = rmq1-messages
rmq1-messages-start: _rmq-messages ## Simulate RabbitMQ message backlog

rmq1-messages-stop: INSTANCE = rmq1-messages
rmq1-messages-stop: _delete ## Stop RabbitMQ message backlog

rmq1-clients-start: INSTANCE = rmq1-clients
rmq1-clients-start: _rmq-clients ## Simulate RabbitMQ production workload

rmq1-clients-stop: INSTANCE = rmq1-clients
rmq1-clients-stop: _delete ## Stop RabbitMQ production workload

logs-viewer:
	open "https://console.cloud.google.com/logs/viewer?project=cf-rabbitmq-core&minLogLevel=0&expandAll=false&customFacets&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2Fcf-rabbitmq-core%2Flogs%2Fcos_containers"

define GCP_COS_CONTAINER_DEFAULTS
--public-dns \
--boot-disk-type=pd-ssd \
--labels=namespace=$(NAMESPACE) \
--container-stdin \
--container-tty
endef

# https://cloud.google.com/compute/docs/containers/deploying-containers
_rmq-server:
	gcloud compute instances create-with-container $(NAMESPACE)-$(INSTANCE) \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=n1-standard-8 \
	  --create-disk=name=$(INSTANCE)-persistent,size=200GB,type=pd-ssd,auto-delete=yes \
	  --container-mount-disk=name=$(INSTANCE)-persistent,mount-path=/var/lib/rabbitmq \
	  --container-image=$(DOCKER_RABBITMQ_37x_IMAGE)

# https://api.cloudflare.com/#dns-records-for-a-zone-create-dns-record

_rmq-server-37x: _rmq_stop_app
	gcloud compute instances update-container $(NAMESPACE)-$(INSTANCE) \
	  --container-image=$(DOCKER_RABBITMQ_37x_IMAGE)


_rmq-server-38x: _rmq_stop_app
	gcloud compute instances update-container $(NAMESPACE)-$(INSTANCE) \
	  --container-image=$(DOCKER_RABBITMQ_38x_IMAGE)

_ssh:
	gcloud compute ssh $(NAMESPACE)-$(INSTANCE)

_bash:
	gcloud compute ssh $(NAMESPACE)-$(INSTANCE) -- \
	  "docker exec -it \$$(docker container ls | awk '/rabbitmq/ { print \$$1 }') bash"

_rmq_stop_app:
	gcloud compute ssh $(NAMESPACE)-$(INSTANCE) -- \
	  "docker exec \$$(docker container ls | awk '/rabbitmq/ { print \$$1 }') rabbitmqctl stop_app"

_delete:
	gcloud compute instances delete $(NAMESPACE)-$(INSTANCE)

# https://github.com/bcicen/ctop
define CTOP_CONTAINER
docker run --rm --interactive --tty \
  --cpus 0.5 --memory 128M \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --name ctop \
  quay.io/vektorlab/ctop
endef
_ctop:
	gcloud compute ssh $(NAMESPACE)-$(INSTANCE) -- "$(CTOP_CONTAINER)"

# https://github.com/hishamhm/htop
define HTOP_CONTAINER
docker run --rm --interactive --tty \
  --cpus 0.5 --memory 128M \
  --net="host" --pid="host" \
  --name htop \
  jess/htop
endef
_htop:
	gcloud compute ssh $(NAMESPACE)-$(INSTANCE) -- "$(HTOP_CONTAINER)"

define RABBITMQ_PERFTEST_DEFAULTS
--container-image=pivotalrabbitmq/perf-test:dev-2020.01.22 \
--container-arg="--auto-delete" \
--container-arg="false" \
--container-arg="--consumers" \
--container-arg="$(NUMBER_OF_QUEUES_PER_NODE)" \
--container-arg="--confirm" \
--container-arg="1" \
--container-arg="--confirm-timeout" \
--container-arg="120" \
--container-arg="--connection-recovery-interval" \
--container-arg="30-120" \
--container-arg="--flag" \
--container-arg="persistent" \
--container-arg="--heartbeat-sender-threads" \
--container-arg="10" \
--container-arg="--nio-threads" \
--container-arg="10" \
--container-arg="--nio-thread-pool" \
--container-arg="20" \
--container-arg="--producers" \
--container-arg="$(NUMBER_OF_QUEUES_PER_NODE)" \
--container-arg="--producer-random-start-delay" \
--container-arg="60" \
--container-arg="--producer-scheduler-threads" \
--container-arg="10" \
--container-arg="--qos" \
--container-arg="5" \
--container-arg="--queue-args" \
--container-arg="x-max-length=$(NUMBER_OF_MESSAGES_PER_QUEUE)" \
--container-arg="--queue-pattern" \
--container-arg="q%d" \
--container-arg="--queue-pattern-from" \
--container-arg="1" \
--container-arg="--queue-pattern-to" \
--container-arg="$(NUMBER_OF_QUEUES_PER_NODE)" \
--container-arg="--servers-startup-timeout" \
--container-arg="60" \
--container-arg="--size" \
--container-arg="$(MESSAGE_SIZE)" \
--container-arg="--uri" \
--container-arg="amqp://guest:guest@tgir-s01e01-rmq1-server.c.cf-rabbitmq-core.internal:5672/%2f"
endef

_rmq-messages:
	gcloud compute instances create-with-container $(NAMESPACE)-$(INSTANCE) \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=n1-highcpu-4 \
	  --container-arg="--consumers" \
	  --container-arg="0" \
	  --container-arg="--rate" \
	  --container-arg="1" \
	  $(RABBITMQ_PERFTEST_DEFAULTS)

_rmq-clients:
	gcloud compute instances create-with-container $(NAMESPACE)-$(INSTANCE) \
	  $(GCP_COS_CONTAINER_DEFAULTS) \
	  --machine-type=n1-highcpu-4 \
	  --container-arg="--consumer-latency" \
	  --container-arg="5000000" \
	  --container-arg="--variable-rate" \
	  --container-arg="1:60" \
	  --container-arg="--variable-rate" \
	  --container-arg="0:300" \
	  $(RABBITMQ_PERFTEST_DEFAULTS)

