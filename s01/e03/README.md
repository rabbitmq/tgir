# TGIR S01E03: How to contribute to RabbitMQ? Part 1

* Proposed via [rabbitmq/tgir#4](https://github.com/rabbitmq/tgir/issues/4)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-03-27

<!-- <a href="https://www.youtube.com/watch?v=TGIR" target="_blank"><img src="video.png" border="50" /></a> -->

Today we will start by getting a local development copy of RabbitMQ up and running.
Next, we will learn about different ways of running RabbitMQ, and how to use local CLI utilities.
To wrap-up, we will build and running a Docker image of our development version of RabbitMQ.

To get the best out of this episode, I encourage you to follow along.
All commands are available as make targets in this episode's directory.


## Timeline

- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Today's topic

## Links

- [Work with ease on multiple RabbitMQ sub-projects, e.g. core broker, plugins and some client libraries](https://github.com/rabbitmq/rabbitmq-public-umbrella)


## Make targets

```
deps                        Resolve all dependencies
dev-cluster-start           Start dev cluster
dev-cluster-stop            Stop dev cluster
dev-server                  Run dev rabbitmq-server
dev-server-with-plugins     Run dev rabbitmq-server with plugins
rabbitmq-public-umbrella    Setup a local copy for developing RabbitMQ
switch-to-3.8.x             Switch local copy to v3.8.x
switch-to-3.9.x             Switch local copy to v3.9.x
```
