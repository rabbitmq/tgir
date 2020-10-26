# TGIR S01E07: How to monitor RabbitMQ

* Proposed via [rabbitmq/tgir#17](https://github.com/rabbitmq/tgir/issues/17)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu) & [@MichalKuratczyk](https://twitter.com/michalkuratczyk)
* Published on: 2020-10-30

<a href="https://www.youtube.com/watch?v=TGIRS01E07" target="_blank"><img src="video.jpg" border="50" /></a>

You have a few RabbitMQ deployments running (on Kubernetes). How do you monitor them?
You have heard of the [great Grafana dashboards that team RabbitMQ maintains](https://grafana.com/orgs/rabbitmq), maybe from this [RabbitMQ Summit 2019 talk](https://www.youtube.com/watch?v=L-tYXpirbpA) or from the official [Monitoring with Prometheus & Grafana](https://www.rabbitmq.com/prometheus.html) guide. But how do you actually set them up?

For speed and convenience, we spin up a K3S instance on a Linux host and do the following:

* integrate K3S with Prometheus & Grafana, all running inside K3S
* deploy a few RabbitMQ clusters together with workloads
* cover the most important Grafana dashboards that we maintain by looking at the above workloads

You may follow along on any Linux host, including a VM running on your macOS or Windows host.
[We had some credits with Equinix Metal](https://info.equinixmetal.com/changelog) that we wanted to put to good use.

## MAKE TARGETS

```
env                         Configure shell env - eval "$(make env)" OR source .env
equinix-metal               Create a Equinix Metal instance - optional step
equinix-metal-rm            Delete the Equinix Metal instance that we have created - this deletes everything
k3s                         Create a K3S instance on a Linux host - works on any Ubuntu VM
k9s                         Interact with our K3S instance via a terminal UI
kube-prometheus             Integrate Prometheus & Grafana with K3S, including RabbitMQ dashboards
rabbitmq-classic            Deploy a RabbitMQ cluster & workload that uses Classic Queues
rabbitmq-quorum             Deploy a RabbitMQ cluster & workload that uses Quorum Queues
rabbitmq-quorum             Deploy a RabbitMQ cluster & workload that uses Stream Queues
rabbitmq-rm-%               Delete one of the deployed RabbitMQ clusters & associated workloads
```
