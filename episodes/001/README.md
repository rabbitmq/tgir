# Episode 001: Understand RabbitMQ - New observability features in 3.8

- Hosted by @gerhard, Amy Welch & Dormain Drewitz
- Recorded on 2019-12-12

<a href="#" target="_blank"><img src="https://user-images.githubusercontent.com/3342/70550192-4b7ba100-1b6d-11ea-99bc-7f7564504bcb.png" border="50" /></a>

## Introduction

* [Gerhard Lazu](https://twitter.com/gerhardlazu), [RabbitMQ Core Engineer](https://github.com/rabbitmq/rabbitmq-server/pulls?utf8=%E2%9C%93&q=author%3Agerhard)
* New metrics system in 3.8 based on Prometheus
  * An evolution of RabbitMQ Management
  * See RabbitMQ in a completely different light - [even when it is struggling](rabbitmq-management-unresponsive-43.gif)
  * The primary goal is to **understand** RabbitMQ
  * The secondary goal is to **improve** RabbitMQ & Erlang
  * Lastly, we want you to have a better experience as you report issues
* All content for this webinar is available at https://tgi.rabbitmq.com/001
* If you want to follow along on your machine, `git clone https://github.com/rabbitmq/tgir && cd episodes/001`
* I will stop after every section to answer a few questions
  * Please feel free to ask questions as we make progress through the content
  * Any unanswared questions I intend to address afterwards & share answers via https://tgi.rabbitmq.com/001

## How to get started with the new metrics in RabbitMQ 3.8?

Provided that we have Docker installed, let's start a single node RabbitMQ with Management enabled:

```sh
# make rabbitmq
docker run -it --rm -p 15672:15672 -p 15692:15692 --name rabbit rabbitmq:3.8-management
```

Let's check that RabbitMQ is up and running as expected: http://localhost:15672

### 1/n. Enable the `rabbitmq_prometheus` plugin

```sh
# make rabbitmq_exec
docker exec -it rabbit bash

rabbitmq-plugins enable rabbitmq_prometheus
^D
```

Verify that the new Prometheus metrics are available: http://localhost:15692/metrics

### 2/n. Configure Prometheus to pull RabbitMQ metrics periodically

```sh
# make prometheus
docker run -it --rm -p 9090:9090 prom/prometheus:v2.14.0
```

Let's check what targets Prometheus is configured to scrape by default: http://localhost:9090/targets

Let's configure Prometheus to scrape RabbitMQ:

```sh
# make prometheus_exec

vi /etc/prometheus/prometheus.yml

#  - job_name: 'rabbitmq'
#    static_configs:
#    - targets: ['tgir-001-rabbitmq:15692']

pkill -HUP prometheus
```

Let's verify that Prometheus configuration has been applied correctly: http://localhost:9090/config

## Developers: see RabbitMQ anti-patterns

## Developers: understand Quorum Queues

## Operators: see imbalanced deployments

## Experts: unlock Erlang insights

## All: share your context
