# TGIR S01E01: How to upgrade from RabbitMQ 3.7 to 3.8?

<a href="https://www.youtube.com/watch?v=DynCqFtnSoY" target="_blank"><img src="video.png" border="50" /></a>

* Proposed by [@dlresende](https://twitter.com/dlresende) via [rabbitmq/tgir#2](https://github.com/rabbitmq/tgir/issues/2)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-01-31
* Video: https://www.youtube.com/watch?v=DynCqFtnSoY



## Timeline

* [00:00:00](https://www.youtube.com/watch?v=DynCqFtnSoY&t=0s) - **Welcome to TGIR!**
* [00:00:50](https://www.youtube.com/watch?v=DynCqFtnSoY&t=50s) - Today's topic
* [00:02:19](https://www.youtube.com/watch?v=DynCqFtnSoY&t=139s) - How to follow along
* [00:04:15](https://www.youtube.com/watch?v=DynCqFtnSoY&t=255s) - **Single Node RabbitMQ**
* [00:06:58](https://www.youtube.com/watch?v=DynCqFtnSoY&t=418s) - Simulate production workload
* [00:08:12](https://www.youtube.com/watch?v=DynCqFtnSoY&t=492s) - In-place upgrade from RabbitMQ v3.7.23 to RabbitMQ v3.8.2
* [00:16:13](https://www.youtube.com/watch?v=DynCqFtnSoY&t=973s) - In-place downgrade from RabbitMQ v3.8.2 to RabbitMQ v3.7.23 😱
* [00:20:38](https://www.youtube.com/watch?v=DynCqFtnSoY&t=1238s) - Second upgrade attempt, after client connection recovery fix
* [00:22:49](https://www.youtube.com/watch?v=DynCqFtnSoY&t=1369s) - How long should an in-place single node upgrade take?
* [00:26:05](https://www.youtube.com/watch?v=DynCqFtnSoY&t=1565s) - **Three-Nodes RabbitMQ Cluster**
* [00:30:59](https://www.youtube.com/watch?v=DynCqFtnSoY&t=1859s) - Simulate production workload
* [00:35:16](https://www.youtube.com/watch?v=DynCqFtnSoY&t=2116s) - Start in-place upgrade of first node
* [00:37:28](https://www.youtube.com/watch?v=DynCqFtnSoY&t=2248s) - First node is restarting as v3.8.2
* [00:39:01](https://www.youtube.com/watch?v=DynCqFtnSoY&t=2341s) - Let's randomly spread the clients across all nodes
* [00:47:45](https://www.youtube.com/watch?v=DynCqFtnSoY&t=2865s) - Start in-place upgrade of second node
* [00:50:00](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3000s) - Second node is restarting as v3.8.2
* [00:52:00](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3120s) - The difference between rolling & all-at-once upgrade
* [00:53:11](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3191s) - Connections imbalance
* [00:53:48](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3228s) - Start in-place upgrade of last node
* [00:55:48](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3348s) - Last node is restarting as v3.8.2
* [00:56:33](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3393s) - How long should an in-place 3-nodes cluster upgrade take?
* [00:57:40](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3460s) - **RabbitMQ Feature Flags**
* [01:00:43](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3643s) - The entire cluster is now running RabbitMQ v3.8.2 fully
* [01:04:58](https://www.youtube.com/watch?v=DynCqFtnSoY&t=3898s) - Drain all messages _tout suite_
* [01:07:52](https://www.youtube.com/watch?v=DynCqFtnSoY&t=4072s) - Tear down all resources
* [01:08:48](https://www.youtube.com/watch?v=DynCqFtnSoY&t=4128s) - **How to Propose a TGIR Topic**

## Introduction

### What is TGI RabbitMQ?

TGI RabbitMQ is a series of videos produced by the RabbitMQ team.

It is inspired by [TGI Kubernetes](https://tgik.io) - thank you Joe Beda & the rest of the TGIK team - with a couple of important differences:

1. The last Friday of every month we ship a new episode.
The episode that you are watching now became available on our [YouTube channel](https://tgi.rabbitmq.com) on the 31st of January 2020, the last Friday of the month.
The next episode ships on the... 28th of February 2020.
1. Episodes are pre-recorded. While we don't rule out live streams, we pre-record by default.
1. Most importantly, this show is about RabbitMQ, not Kubernetes. OK, there will be some Kubernetes, for sure, but the focus is RabbitMQ.

My favourite part is that we share everything that you need to follow along in the simplest of ways: make targets with shell completion support.
No more typos, no long commands to copy-paste, just `m<TAB> r<TAB>` and before you know it you are spinning up and tearing down RabbitMQ clusters like a pro.
To do everything that I will be doing in today's episode you need a budget of maybe 10 USD and a Google Cloud Platform account.
Even if you know nothing about RabbitMQ, the barrier of entry is a [Google Cloud SDK](https://cloud.google.com/sdk/install) install and config.
Let's take a few to set this up now:

```
make deps
brew cask install google-cloud-sdk
/usr/local/bin/gcloud auth login \
&& /usr/local/bin/gcloud config set project cf-rabbitmq-core \
&& /usr/local/bin/gcloud config set compute/zone europe-west2-b
```

OK, let's get started with today's topic: **How to upgrade from RabbitMQ 3.7 to 3.8?**

We will start with the simplest RabbitMQ deployment and perform the simplest upgrade procedure: in-place.

## The Setup

One RabbitMQ 3.7 node with `rabbitmq-management`:

```sh
make server
time /usr/local/bin/gcloud compute instances create-with-container tgir-s01e01-gerhard-rmq1-server \
  --boot-disk-type=pd-ssd --labels=namespace=tgir-s01e01-gerhard --container-stdin --container-tty \
  --machine-type=n1-standard-8 \
  --create-disk=name=tgir-s01e01-gerhard-rmq1-server-persistent,size=200GB,type=pd-ssd,auto-delete=yes \
  --container-mount-disk=name=tgir-s01e01-gerhard-rmq1-server-persistent,mount-path=/var/lib/rabbitmq \
  --container-env RABBITMQ_ERLANG_COOKIE=tgir-s01e01-gerhard \
  --container-image=rabbitmq:3.7.23-management
```

A production workload using PerfTest:

```sh
make workload
/usr/local/bin/gcloud compute instances create-with-container tgir-s01e01-gerhard-rmq1-workload \
  --boot-disk-type=pd-ssd --labels=namespace=tgir-s01e01-gerhard --container-stdin --container-tty \
  --machine-type=n1-highcpu-4 \
  --container-arg="--consumer-latency" \
  --container-arg="5000000" \
  --container-arg="--variable-rate" \
  --container-arg="1:60" \
  --container-arg="--variable-rate" \
  --container-arg="0:240" \
  --container-image=pivotalrabbitmq/perf-test:dev-2020.01.22 --container-arg="--auto-delete" --container-arg="false" --container-arg="--consumers" --container-arg="4000" --container-arg="--confirm" --container-arg="1" --container-arg="--confirm-timeout" --container-arg="120" --container-arg="--connection-recovery-interval" --container-arg="240" --container-arg="--flag" --container-arg="persistent" --container-arg="--heartbeat-sender-threads" --container-arg="10" --container-arg="--nio-threads" --container-arg="10" --container-arg="--nio-thread-pool" --container-arg="20" --container-arg="--producers" --container-arg="4000" --container-arg="--producer-random-start-delay" --container-arg="60" --container-arg="--producer-scheduler-threads" --container-arg="10" --container-arg="--qos" --container-arg="5" --container-arg="--queue-args" --container-arg="x-max-length=1000" --container-arg="--queue-pattern" --container-arg="q%d" --container-arg="--queue-pattern-from" --container-arg="$(((1-1)*4000+1))" --container-arg="--queue-pattern-to" --container-arg="$((1*4000))" --container-arg="--servers-startup-timeout" --container-arg="30" --container-arg="--size" --container-arg="1000" --container-arg="--uri" --container-arg="amqp://guest:guest@tgir-s01e01-gerhard-rmq1-server.c.cf-rabbitmq-core.internal:5672/%2f"
```

Let's check RabbitMQ Management (username is `guest` & password is `guest`):

```
make management
/usr/local/bin/gcloud compute firewall-rules describe gerhard-allow-rmq-management \
|| /usr/local/bin/gcloud compute firewall-rules create gerhard-allow-rmq-management \
	--allow=TCP:15672 --source-ranges=82.39.214.211/32
open http://"$(/usr/local/bin/gcloud compute instances describe tgir-s01e01-gerhard-rmq1-server --format='get(networkInterfaces[0].accessConfigs[0].natIP)')":15672
```

In RabbitMQ Management, notice the RabbitMQ & Erlang version, as well as the number of connections & queues.
![rmq-management-37x](./tgir-s01e01-rmq-management-37x.png)

What I really want to see is logs from both RabbitMQ & PerfTest:

```
make logs
open "https://console.cloud.google.com/logs/viewer?project=cf-rabbitmq-core&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2Fcf-rabbitmq-core%2Flogs%2Fcos_containers%0ANOT%20jsonPayload.message:%22consumer%20latency%22%0ANOT%20jsonPayload.message:%22has%20a%20client-provided%20name%22%0ANOT%20jsonPayload.message:%22authenticated%20and%20granted%20access%22%0ANOT%20jsonPayload.message:%22starting%20producer%22%0ANOT%20jsonPayload.message:%22starting%20consumer%22%0ANOT%20jsonPayload.message:%22accepting%20AMQP%20connection%22"
```

![logs](./tgir-s01e01-logs.png)

Now that we have this setup, let's watch RabbitMQ Management for a couple of minutes.
We will notice that the consumers can't quiet keep up with the producers.
We did this on purpose, so that we can simulate a backlog of messages before triggering the upgrade to RabbitMQ 3.8.
In a typical production environment the expectation is that the consumers will empty all messages in the queues.
If they don't, then all available memory & disk will eventually get used up, alarms will be triggered and RabbitMQ will block all publishing connections.

Before we upgrade, let's set the correct expectations.
We have some persistent messages across some durable queues which we expect to become available as soon as our RabbitMQ node restarts as 3.8.
All our publishers are using publisher confirms, so they will know if any messages has not been safely stored by RabbitMQ.
Consumers use message acknowledgements, meaning that any unconfirmed messages - a.k.a. in-flight - will change state to ready when the node restarts.
We expect some consumers to receive the same message twice:
* once before the node went down while the message was still unconfirmed
* and one more time after the node restarts and delivers the same message again

Lastly, all clients - publishers and consumers - are using connection recovery with a variable interval.
This means that when the connection to the broker goes away, all clients will attempt to reconnect at random intervals.
No client will crash, it will simply wait for the RabbitMQ node to become available again.

Let's keep an eye on all clients before we start the upgrade process:

```
make workload-ctop
/usr/local/bin/gcloud compute ssh tgir-s01e01-gerhard-rmq1-workload -- "docker run --rm --interactive --tty --cpus 0.5 --memory 128M --volume /var/run/docker.sock:/var/run/docker.sock --name ctop quay.io/vektorlab/ctop"
```

## The Upgrade Process

> https://www.rabbitmq.com/upgrade.html

We are now ready to upgrade our RabbitMQ 3.7 node to 3.8.

The most important aspect of this is to stop the RabbitMQ node gracefully.
We do this by stopping the RabbitMQ app:

```
make app-stop
gcloud compute ssh tgir-s01e01-rmq1-server -- \
  "docker exec \$(docker container ls | awk '/rabbitmq/ { print \$1 }') rabbitmqctl stop_app"
Stopping rabbit application on node rabbit@tgir-s01e01-rmq1-server ...
Connection to 35.189.82.219 closed.
```

This command does the following:
* closes all connections
* stops all RabbitMQ plugins in dependency-aware order
* stops all TCP listeners
* flushes all data to disk
* stops all Message Stores as well as the Schema DB (Mnesia)

This command **does not** stop the Erlang VM, meaning that from a system supervisor perspective, the system process that represents RabbitMQ is still running.
We know that this system process is the Erlang VM (`beam.smp`), so even if RabbitMQ and all its dependencies that run inside the Erlang VM are stopped, everything is OK from a system supervisor perspective.

> `rabbitmqctl stop_app` is something that most RabbitMQ ops procedures simply ignore.
The typical approach is to send the `SIGTERM` UNIX signal to the Erlang VM process, wait for 30 seconds, and then `SIGKILL`.
This is an unclean RabbitMQ shutdown which may have undesired side-effects.

> A better approach would be to stop just RabbitMQ, using `rabbitmqctl stop_app`, wait until this command returns successfully - exit code 0 - and then continue with the Erlang VM shutdown.
After RabbitMQ is stopped in this manner, sending `SIGTERM` to the Erlang VM is definitely safe & appropriate.
If you want to know more about this, follow [rabbitmq/rabbitmq-server#2222](https://github.com/rabbitmq/rabbitmq-server/issues/2222).

We are now ready to shutdown the Erlang VM, even the entire OS in our case, and have it restart with the new RabbitMQ version:

```
make server-38x
gcloud compute ssh tgir-s01e01-rmq1-server -- \
  "docker exec \$(docker container ls | awk '/rabbitmq/ { print \$1 }') rabbitmqctl stop_app"
Stopping rabbit application on node rabbit@tgir-s01e01-rmq1-server ...
Connection to 35.189.82.219 closed.
gcloud compute instances update-container tgir-s01e01-rmq1-server \
  --container-image=rabbitmq:3.8.2-management
Updating specification of container [tgir-s01e01-rmq1-server]...done.
Stopping instance [tgir-s01e01-rmq1-server]...done.
Starting instance [tgir-s01e01-rmq1-server]...done.
```

Now that the upgrade is complete, let's understand what happened from a RabbitMQ perspective by looking at lifecycle logs:

```
make logs-lifecycle
open "https://console.cloud.google.com/logs/viewer?project=$(gcloud config get-value project 2>/dev/null)&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2F$(gcloud config get-value project 2>/dev/null)%2Flogs%2Fcos_containers%0AjsonPayload.message:%20(%22starting%20rabbitmq%22%20OR%20%22started%22%20OR%20%22stopping%22%20OR%20%22stopped%22%20AND%20NOT%20%22supervisor%22)"
```


We can confirm the following:

* The upgrade took 1 minute and 30 seconds - `14:58:44 - 15:00:14`
* We are now running RabbitMQ 3.8.2
* All clients have reconnected, none crashed
* All durable queues and persistent messages are exactly as we left them before the upgrade. All RabbitMQ data is kept on a persistent disk which was automatically re-attached to the new VM.

We need to re-open RabbitMQ Management because the public IP is ephemeral and it changed after the upgrade:

```
make management
open http://"$(gcloud compute instances describe tgir-s01e01-rmq1-server --format='get(networkInterfaces[0].accessConfigs[0].natIP)')":15672
```

![rmq-management-38x](./tgir-s01e01-rmq-management-38x.png)

## Three-Nodes RabbitMQ Cluster

  * `make workload-stop`
  * `make server-delete`
  * `make server`
  * `make management`
  * `make server RMQ_NODE=2`
  * `make server RMQ_NODE=3`
  * `make server-bash`
    * `rabbitmqctl stop_app`
    * `rabbitmqctl reset`
    * `rabbitmqctl join_cluster`
    * `rabbitmqctl start_app`

## RabbitMQ Feature Flags

## Propose a TGIR Topic
