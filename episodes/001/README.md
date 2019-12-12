# Episode 001: Understand RabbitMQ - New observability features in 3.8

- Hosted by @gerhard, Amy Welch & Dormain Drewitz
- Recorded on 2019-12-12

<a href="#" target="_blank"><img src="https://user-images.githubusercontent.com/3342/70550192-4b7ba100-1b6d-11ea-99bc-7f7564504bcb.png" border="50" /></a>

## Introduction

[Gerhard Lazu](https://gerhard.io), [RabbitMQ Core Engineer](https://github.com/rabbitmq/rabbitmq-server/pulls?utf8=%E2%9C%93&q=author%3Agerhard)

In the next hour, I will show you what happens in RabbitMQ from the perspective of the new metrics system that we have shipped in RabbitMQ 3.8.
This was available for over 2 months now, since early October.

This new metrics system is an evolution of what many of you know & use in today's RabbitMQ Management

I want you to see RabbitMQ in a completely different light,
[even when it is struggling](rabbitmq-management-unresponsive-43.gif),
and understand why that is.

Because this webinar is a demo, please ask questions as they come up.
I will do my best to answer them as we make progress through the content.

...

OK, so we will start by setting up the new metrics system in RabbitMQ 3.8 from scratch.
This includes integrating with Prometheus & Grafana, which is something that you may not need to do if you are using RabbitMQ as a service,
but it's important to understand how the various pieces fit together.

...

We will continue by learning about the new Grafana dashboards that we maintain,
and how can they help you understand what happens within the various layers that make the RabbitMQ service.

There is something for everyone: developers, operators & even Erlang experts.

...

To finish off, we will show you how to best share the state of your RabbitMQ deployment when you ask for help.
This will help us, help you get the best experience out of RabbitMQ.

...

OK, so...

## How do we get started with the new metrics in RabbitMQ 3.8?

I will be using Docker for Desktop in my demo to keep us focused on the task at hand.

I don't think that I need to mention this, but just to be explicit about it, I would not recommend that you do this in production.

So let's start a single node RabbitMQ with Management enabled:

```sh
# make rabbitmq
/usr/local/bin/docker run -it --rm \
  --name getstarted \
  --hostname getstarted \
  --network 1212 \
  -p 15672:15672 \
  -p 15692:15692 \
  rabbitmq:3.8.2-management
```

Is RabbitMQ up and running as expected? http://localhost:15672

Before we continue, we want to put some load on this RabbitMQ node so that there are more metrics to look at when we get to that point.

As some of you may now, PerfTest has been the official RabbitMQ benchmarking tool for many years now.

To start a PerfTest instance:

```
# make perftest
```

### 1/3. Enable the `rabbitmq_prometheus` plugin

```sh
# make rabbitmq_enable_prometheus
docker exec -it getstarted rabbitmq-plugins enable rabbitmq_prometheus
```

What do the new Prometheus metrics look like? http://localhost:15692/metrics

Notice the new port, which is different from the Management one.

Learn more about this new plugin in RabbitMQ 3.8: https://github.com/rabbitmq/rabbitmq-prometheus

### 2/3. Configure Prometheus to pull RabbitMQ metrics periodically

We first need a Prometheus:

```sh
# make prometheus
docker run -it --rm \
  --name prometheus \
  --hostname prometheus \
  --network 1212 \
  -p 9090:9090 \
  prom/prometheus:v2.14.0
```

By default, what targets is Prometheus configured to scrape? http://localhost:9090/targets

Let's configure Prometheus to scrape RabbitMQ:

```sh
# make prometheus_exec
docker exec -it prometheus sh

vi /etc/prometheus/prometheus.yml

#  - job_name: 'rabbitmq'
#    static_configs:
#    - targets: ['getstarted:15692']

pkill -HUP prometheus
```

Was the Prometheus configuration applied correctly? http://localhost:9090/config

Is the new RabbitMQ target being scraped correctly? http://localhost:9090/targets

Can we see some RabbitMQ metrics in Prometheus? http://localhost:9090/new/graph

* `rabbitmq_identity_info`
* `rabbitmq_build_info`

### 3/3. Configure Grafana to visualise RabbitMQ metrics from Prometheus

We first need a Grafana:

```sh
# make grafana
/usr/local/bin/docker run -it --rm \
  --name grafana \
  --hostname grafana \
  --network 1212 \
  -p 3000:3000 \
  grafana/grafana:6.4.5
```

Secondly, we need to configure Prometheus datasource in Grafana: http://localhost:3000

Lastly, let's import a Grafana dashboard: http://localhost:3000/dashboards + https://grafana.com/orgs/rabbitmq


Now that we understand the mechanics of how the different pieces fit together, let us shift focus on what this dashboard is actually trying to show us, and that we are not seeing here.

## Developers: see RabbitMQ anti-patterns

## Developers: understand Quorum Queues

## Operators: see imbalanced deployments

## Experts: unlock Erlang insights

## All: share your context
