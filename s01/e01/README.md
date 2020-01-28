# TGIR S01E01: How to upgrade from RabbitMQ 3.7 to 3.8?

* Proposed by [@dlresende](https://twitter.com/dlresende) via [rabbitmq/tgir#2](https://github.com/rabbitmq/tgir/issues/2)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-01-31

## Introduction

Welcome to the first episode of TGI RabbitMQ 2020, where we show you how to upgrade a production cluster from RabbitMQ 3.7 to 3.8.
Before we dive into today's main topic, let's answer the first question:

### What is TGI RabbitMQ?

TGI RabbitMQ is a series of videos produced by the RabbitMQ team.

It is inspired by [TGI Kubernetes](https://tgik.io) - thank you Joe Beda & the rest of the TGIK team - with a couple of important differences:

1. The last Friday of every month we ship a new episode.
The episode that you are watching now became available on our [RabbitMQ YouTube channel](https://tgi.rabbitmq.com) on the 31st of January 2020, the last Friday of the month.
The next episode ships on the... 28th of February 2020.
1. Episodes are pre-recorded. While we don't rule out live streams, we pre-record by default.
1. Most importantly, this show is about RabbitMQ, not Kubernetes. OK, there will be some Kubernetes, for sure, but the focus is RabbitMQ.

My favourite part is that we package and share everything that you need to follow along.
For example, you need a budget of maybe 10 USD and a Google Cloud Platform account to do everything that I will be doing in today's episode.
Even if you know nothing about RabbitMQ, the barrier of entry is a [Google Cloud SDK](https://cloud.google.com/sdk/install), specifically the `gcloud` CLI.
Let's take a few to set this up now:

```
brew cask install google-cloud-sdk
gcloud config list
```

OK, let's get started with today's topic: How to upgrade from RabbitMQ 3.7 to 3.8?

### [Diego Lemos](https://twitter.com/dlresende), Engineering Lead, Pivotal R&D London:

A new RabbitMQ version comes out. Exciting!
Shiny new features, bug fixes, security patches, etc. - it's time to upgrade!
But hang on a second... there are hundreds of applications using RabbitMQ in production.
How should we go about upgrading?

This question comes up frequently in the RabbitMQ community, as part of what we call _Day 2 Operations_.
Every company or team decide which upgrade strategy works better for them: blue-green deployment, rolling (one node at a time) upgrades, etc.
But every strategy comes with its advantages and trade-offs, which are not well understood.

* What happens to clients during a rolling upgrade?
* What happens to particular types of queues?
* What if an alarm gets triggered during an upgrade?
* When should I expect for downtime?
* When there's a risk of data loss?
* How clusters reform after an upgrade?
* How to configure RabbitMQ or its clients to be upgrade-resilient?

The above questions come up over and over again and I believe that many would benefit from clear & concise guidance on how to tackle them.

So why are we doing this now? https://www.rabbitmq.com/versions.html

## The Setup

One RabbitMQ 3.7 node with management enabled:

```sh
make rmq-server
gcloud compute instances create-with-container tgir-s01e01-rmq1-server \
  --public-dns --boot-disk-type=pd-ssd --labels=namespace=tgir-s01e01 --container-stdin --container-tty \
  --machine-type=n1-standard-8 \
  --create-disk=name=tgir-s01e01-rmq1-server-persistent,size=200GB,type=pd-ssd,auto-delete=yes \
  --container-mount-disk=name=tgir-s01e01-rmq1-server-persistent,mount-path=/var/lib/rabbitmq \
  --container-image=rabbitmq:3.7.23-management
```


A production workload using PerfTest:

```sh
make rmq-workload-start
gcloud compute instances create-with-container tgir-s01e01-rmq1-workload \
  --public-dns --boot-disk-type=pd-ssd --labels=namespace=tgir-s01e01 --container-stdin --container-tty \
  --machine-type=n1-highcpu-4 \
  --container-arg="--consumer-latency" \
  --container-arg="5000000" \
  --container-arg="--variable-rate" \
  --container-arg="1:60" \
  --container-arg="--variable-rate" \
  --container-arg="0:300" \
  --container-image=pivotalrabbitmq/perf-test:dev-2020.01.22 --container-arg="--auto-delete" --container-arg="false" --container-arg="--consumers" --container-arg="4000" --container-arg="--confirm" --container-arg="1" --container-arg="--confirm-timeout" --container-arg="120" --container-arg="--connection-recovery-interval" --container-arg="30-120" --container-arg="--flag" --container-arg="persistent" --container-arg="--heartbeat-sender-threads" --container-arg="10" --container-arg="--nio-threads" --container-arg="10" --container-arg="--nio-thread-pool" --container-arg="20" --container-arg="--producers" --container-arg="4000" --container-arg="--producer-random-start-delay" --container-arg="60" --container-arg="--producer-scheduler-threads" --container-arg="10" --container-arg="--qos" --container-arg="5" --container-arg="--queue-args" --container-arg="x-max-length=1000" --container-arg="--queue-pattern" --container-arg="q%d" --container-arg="--queue-pattern-from" --container-arg="1" --container-arg="--queue-pattern-to" --container-arg="4000" --container-arg="--servers-startup-timeout" --container-arg="60" --container-arg="--size" --container-arg="1000" --container-arg="--uris" --container-arg="amqp://guest:guest@tgir-s01e01-rmq1-server.c.cf-rabbitmq-core.internal:5672/%2f,amqp://guest:guest@tgir-s01e01-rmq2-server.c.cf-rabbitmq-core.internal:5672/%2f,amqp://guest:guest@tgir-s01e01-rmq3-server.c.cf-rabbitmq-core.internal:5672/%2f"
```

Let's check RabbitMQ Management:

```
make rmq-management
open http://"$(gcloud compute instances describe tgir-s01e01-rmq1-server --format='get(networkInterfaces[0].accessConfigs[0].natIP)')":15672
```

Notice the RabbitMQ & Erlang version, as well as the number of connections, channels & queues.

![rmq-management-37x](./tgir-s01e01-rmq-management-37x.png)

What I really want to see now is logs for both RabbitMQ as well as PerfTest:

```
make logs
open "https://console.cloud.google.com/logs/viewer?project=$(gcloud config get-value project 2>/dev/null)&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2F$(gcloud config get-value project 2>/dev/null)%2Flogs%2Fcos_containers%0ANOT%20jsonPayload.message:%22consumer%20latency%22%0ANOT%20jsonPayload.message:%22has%20a%20client-provided%20name%22%0ANOT%20jsonPayload.message:%22authenticated%20and%20granted%20access%22%0ANOT%20jsonPayload.message:%22starting%20producer%22%0ANOT%20jsonPayload.message:%22starting%20consumer%22%0ANOT%20jsonPayload.message:%22accepting%20AMQP%20connection%22"
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
make rmq-workload-ctop
gcloud compute ssh tgir-s01e01-rmq1-workload -- "docker run --rm --interactive --tty --cpus 0.5 --memory 128M --volume /var/run/docker.sock:/var/run/docker.sock --name ctop quay.io/vektorlab/ctop"
```

## The Upgrade Process

We are now ready to upgrade our RabbitMQ 3.7 node to 3.8.

The most important aspect of this is to stop the RabbitMQ node gracefully.
We do this by stopping the RabbitMQ app:

```
make rmq-server-stop-app
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

It does not however stop the Erlang VM, meaning that from a system supervisor perspective, the system process that represents RabbitMQ is still running.
We know that this system process is the Erlang VM, a.k.a. `beam.smp`, so even if RabbitMQ and all its dependencies that run inside the Erlang VM are stopped, everything is OK from a system supervisor perspective.

We are now ready to shutdown the Erlang VM, even the entire OS in our case, and have it restart with the new RabbitMQ version:

```
make rmq-server-38x
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

We need to-reopen RabbitMQ Management because the public IP is ephemeral and it changes during the upgrade:

```
make rmq-management
open http://"$(gcloud compute instances describe tgir-s01e01-rmq1-server --format='get(networkInterfaces[0].accessConfigs[0].natIP)')":15672
```

![rmq-management](./tgir-s01e01-rmq-management-38x.png)

To make it easier to understand what happened from a RabbitMQ perspective, let's only look at the lifecycle logs:

```
make logs-rmq-lifecycle
open "https://console.cloud.google.com/logs/viewer?project=$(gcloud config get-value project 2>/dev/null)&minLogLevel=0&expandAll=false&limitCustomFacetWidth=true&interval=PT1H&advancedFilter=resource.type%3Dgce_instance%0AlogName%3Dprojects%2F$(gcloud config get-value project 2>/dev/null)%2Flogs%2Fcos_containers%0AjsonPayload.message:%20(%22starting%20rabbitmq%22%20OR%20%22started%22%20OR%20%22stopping%22%20OR%20%22stopped%22%20AND%20NOT%20%22supervisor%22)"
```

We can confirm the following:

* We are now running RabbitMQ 3.8.2 - the upgrade took about 1 minute and 30 seconds
* All durable queues and persistent messages are exactly as we left them before the upgrade
* All clients have reconnected, none crashed

---

* What happens to clients during a rolling upgrade?
* What happens to particular types of queues?
* What if an alarm gets triggered during an upgrade?
* When should I expect for downtime?
* When there's a risk of data loss?
* How clusters reform after an upgrade?
* How to configure RabbitMQ or its clients to be upgrade-resilient?

### How do I ensure that messages are not lost?

* 8 queue type / message flag / TTL combinations
* 10k messages per queue

Publisher confirms & consumer acknowledgements are a pre-requisite before we can discuss message loss.

| Queue type  | Message flag     | Messages lost       |
| ---         | ---              | :--                 |
| Non-durable |                  | Yes                 |
| Non-durable | persistent       | Yes                 |
| Durable     |                  | Yes                 |
| Durable     | persistent       | No                  |
| Lazy        |                  | No?                 |
| Lazy        | persistent       | No                  |

## Learn more

* [Upgrading RabbitMQ](https://www.rabbitmq.com/upgrade.html)
