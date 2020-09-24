# TGIR S01E06: How to run a RabbitMQ cluster reliably on K8S?

* Proposed via [rabbitmq/tgir#13](https://github.com/rabbitmq/tgir/issues/13)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-09-25

<a href="https://www.youtube.com/watch?v=TGIRS01E06" target="_blank"><img src="video.jpg" border="50" /></a>

You have a single RabbitMQ node running on Kubernetes (K8S).
[TGIRS01E05](https://github.com/rabbitmq/tgir/tree/S01E05/s01/e05) covered the getting started part well.
[Deploying RabbitMQ to Kubernetes: What’s Involved?](https://www.rabbitmq.com/blog/2020/08/10/deploying-rabbitmq-to-kubernetes-whats-involved/) blog post added more detail.
With the RabbitMQ on K8S basics understood, it's time to deploy a RabbitMQ cluster on K8S and tackle more advanced topics:

1. What are good liveness & readiness probes?
2. How to configure RabbitMQ for availability during K8S upgrades?
3. How to configure clients to handle a minority of RabbitMQ nodes becoming unavailable?
4. What to expect when a majority of RabbitMQ nodes go away?
5. What happens when all RabbitMQ nodes go away? [You will be surprised about this one, just as I have been](https://stackoverflow.com/questions/62355470/how-to-configure-a-rabbitmq-cluster-in-kubernetes-with-a-mounted-persistent-volu?stw=2).



## MAKE TARGETS

```
all                         Create K8S cluster & deploy RabbitMQ
clean                       Delete RabbitMQ and all linked resources, then delete K8S cluster
env                         Configure shell env - eval "$(make env)"
k8s                         Create K8S cluster
k8s-ls                      List K8S clusters
k8s-node-sizes              Show all size options for K8S nodes
k8s-regions                 Show all regions where K8S can be deployed
k8s-rm                      Delete K8S cluster
k9s                         Interact with K8S via terminal UI
lbs                         Show all Load Balancers
rabbitmq                    Deploy a RabbitMQ cluster on K8S
rabbitmq-rm                 Delete RabbitMQ and all linked resources
rabbitmq-workload           Deploy a RabbitMQ publishing & consuming workload
resources                   Show all resources
vms                         Show all VMs (aka Compute Engine instances)
vols                        Show all Volumes
```
