# TGIR S01E07: How to monitor RabbitMQ

* Proposed via [rabbitmq/tgir#17](https://github.com/rabbitmq/tgir/issues/17)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu) & [@MichalKuratczyk](https://twitter.com/michalkuratczyk)
* Published on: 2020-11-10

<a href="https://www.youtube.com/watch?v=NWISW6AwpOE" target="_blank"><img src="video.jpg" border="50" /></a>

You have a few RabbitMQ deployments. How do you monitor them?
You have heard of the [great Grafana dashboards that team RabbitMQ maintains](https://grafana.com/orgs/rabbitmq), maybe from this [RabbitMQ Summit 2019 talk](https://www.youtube.com/watch?v=L-tYXpirbpA) or from the official [Monitoring with Prometheus & Grafana](https://www.rabbitmq.com/prometheus.html) guide. But how do you actually set them up?
And what about the default metrics configuration? Can this be improved if Prometheus is used?

For speed and convenience, we set up K3S on a Linux host ([we had some Equinix Metal credits](https://info.equinixmetal.com/changelog) that we put to good use) and then:

* We integrate Prometheus & Grafana with K3S, all running inside K3S.
* We set up RabbitMQ Grafana dashboards & deploy the RabbitMQ Cluster Operator, which makes deploying RabbitMQ on K8S as easy as it gets.
* We deploy a few RabbitMQ workloads and look at their behaviour via Grafana, paying special attention to memory pressure coming from the metrics system.

If your RabbitMQ nodes run many queues, channels & connections and you are using the default metrics configuration, this will help you understand how to optimise that.


## LINKS

* [Monitoring with Prometheus & Grafana guide](https://www.rabbitmq.com/prometheus.html)
* [RabbitMQ Cluster Kubernetes Operator](https://github.com/rabbitmq/cluster-operator)
* [RabbitMQ Grafana Dashboards](https://grafana.com/orgs/rabbitmq)
* Observe and understand RabbitMQ - RabbitMQ Summit 2019: [Post](https://www.cloudamqp.com/blog/2019-12-10-observe-and-understand-rabbitmq.html) [Video](https://www.youtube.com/watch?v=L-tYXpirbpA) [Slides](https://gerhard.io/slides/observe-understand-rabbitmq/#/)
* [Equinix Bare Metal - Servers](https://metal.equinix.com/product/servers/)


## MAKE TARGETS

```
env                           Configure shell env - eval "$(make env)" OR source .env
equinix-metal-server          Create a Equinix Metal host - optional step
equinix-metal-server-rm       Delete the Equinix Metal server - this deletes everything
equinix-metal-servers         List all Equinix Metal servers
equinix-metal-ssh-key         Add SSH key that will be added to all new servers
k3s                           Create a K3S instance on a Linux host - works on any Ubuntu VM
k3s-grafana                   Access Grafana running in K3S
k3s-monitoring                Integrate Prometheus & Grafana with K3S, including system metrics
k3s-rabbitmq                  Deploy all things RabbitMQ in K3S
k3s-rabbitmq-grafana          Add RabbitMQ Grafana dashboards to Kube Prometheus Stack
k3s-rabbitmq-operator         Install RabbitMQ Cluster Operator into K3S
k9s                           Interact with our K3S instance via a terminal UI
rabbitmq-default-metrics      Deploy a RabbitMQ with many Classic Queues, Publishers & Consumers and default Management metrics
rabbitmq-minimal-metrics      Deploy a RabbitMQ with many Classic Queues, Publishers & Consumers and minimal Management metrics
rabbitmq-prometheus-metrics   Deploy a RabbitMQ with many Classic Queues, Publishers & Consumers and no Management metrics
rabbitmq-quorum               Deploy a RabbitMQ with a Quorum Queue workload
rabbitmq-rm-%                 Delete one of the deployed RabbitMQ clusters & associated workloads
rabbitmq-stream               Deploy a RabbitMQ with a Stream Queue workload
ssh-k3s                       SSH into the K3S host``
```
