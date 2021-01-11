# TGIR S01E08: Secure public RabbitMQ clusters

* Proposed via [rabbitmq/tgir#16](https://github.com/rabbitmq/tgir/issues/16)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu) & [@GSantomaggio](https://twitter.com/GSantomaggio)
* Published on: 2020-12-31

<a href="https://www.youtube.com/watch?v=mPuMBB9_MRI" target="_blank"><img src="video.jpg" border="50" /></a>

How do you make your RabbitMQ clusters public & secure? Think HTTPS & AMQPS.
What about using a single IP for multiple RabbitMQ clusters?
And what about connection throttling?

Gerhard & Gabriele try out RabbitMQ Cluster Operator v1.3, cert-manager v1.1 & Traefik v2.3 on Digital Ocean Kubernetes v1.19.3.

Topics covered:
- cert-manager with CloudFlare DNS
- SNI in RabbitMQ, PerfTest & Erlang
- Istio as an alternative to Traefik



## LINKS

* [cert-manager](https://cert-manager.io/docs/)
* [Traefik](https://doc.traefik.io/traefik/)
* [cluster-operator - disableNonTLSListeners](https://github.com/rabbitmq/cluster-operator/pull/477)
* [cluster-operator - Prometheus TLS](https://github.com/rabbitmq/cluster-operator/pull/533)
* [cluster-operator - 1.2.0 to 1.3.0 rolling StatefulSet update?](https://github.com/rabbitmq/rabbitmq-server/discussions/2699)
* [RabbitMQ PerfTest - -sni option](https://github.com/rabbitmq/rabbitmq-perf-test/pull/253)
* [What is SNI?](https://www.cloudflare.com/learning/ssl/what-is-sni/)
* [RabbitMQ - Using TLS in the Java Client](https://www.rabbitmq.com/ssl.html#java-client)
* [Handle two RabbitMQ clusters with ISTIO](https://github.com/Gsantomaggio/k8s/tree/wip/rabbitmq_traffic)



## MAKE TARGETS

```
all                             Setup all resources
cert-manager                    3. Deploy cert-manager for Let's Encrypt TLS certs
cert-manager-cloudflare         4. Enable rabbitmq.com TLS certs verification
clean                           Remove all installed resources
cluster-operator                1. Install RabbitMQ Cluster Operator for easy & correct RabbitMQ clusters on K8S
dke                             Create Digital Ocean Kubernetes (DKE) cluster
dke-ls                          List DKE clusters
dke-regions                     Show all regions where DKE can be deployed
dke-rm                          Delete DKE cluster
dke-sizes                       Show all size options for DKE nodes
dke-versions                    Show all size options for DKE nodes
env                             Configure shell env - eval "$(make env)" OR source .env
k9s                             Interact with our K8S cluster via a terminal UI
rabbitmq-%-insecure             2. Deploy RabbitMQ cluster with a public IP
rabbitmq-%-insecure-rm          Delete RabbitMQ cluster & public IP
rabbitmq-%-secure               6. Deploy a RabbitMQ cluster with secure public IP
rabbitmq-%-secure-perftest      8. Run PerfTest against RabbitMQ cluster secure public IP
rabbitmq-%-secure-perftest-rm   Delete PerfTest that runs against RabbitMQ cluster secure public IP
rabbitmq-%-secure-rm            Delete RabbitMQ cluster
traefik                         5. Install Traefik
traefik-%-ingress               7. Deploy HTTPS and AMQPS Traefik ingress
traefik-%-ingress-rm            Deploy HTTPS and AMQPS Traefik ingress
traefik-rm                      Remove Traefik
```
