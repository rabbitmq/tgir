# TGIR S01E03: How to contribute to RabbitMQ? Part 1

* Proposed via [rabbitmq/tgir#4](https://github.com/rabbitmq/tgir/issues/4)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-03-27

<!-- <a href="https://www.youtube.com/watch?v=TGIR" target="_blank"><img src="video.png" border="50" /></a> -->

This is the first part of a multi-part series on how to contribute to RabbitMQ.
We will start by getting a local development copy of RabbitMQ up and running.
Next, we will learn about different ways of running RabbitMQ, and how to use the local CLIs.
To wrap-up, we will build a Docker image of a modified RabbitMQ version and stress test it.
Our contribution will be to verify that the fix is ready to ship in the next RabbitMQ release.

To get the best out of this episode, I encourage you to follow along.
All commands are available as make targets in this episode's directory.


## Timeline

- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Today's topic
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - rabbitmq-public-umbrella
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - What does the master branch represent?
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - And the v3.8.x branch?
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - How to run a local dev copy of RabbitMQ?
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Interactive shell is available by default
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Run a local dev copy of RabbitMQ with all plugins enabled and STDOUT debug logging
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Where to find rabbitmqctl & friends?
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Build a Docker image of rabbitmq-server#2279 & rabbitmq-common#368
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - Close rabbitmq-server#2254
- [00:00:00](https://www.youtube.com/watch?v=TGIR&t=0s) - In the next episode...


## Links

- [Work with ease on multiple RabbitMQ sub-projects, e.g. core broker, plugins and some client libraries](https://github.com/rabbitmq/rabbitmq-public-umbrella)
- [rabbitmq-server issues #2254: Node can use significant (e.g. 80GB) amounts of RAM during startup](https://github.com/rabbitmq/rabbitmq-server/issues/2254)
  - [rabbitmq-server PR #2279: Reduce memory usage during startup](https://github.com/rabbitmq/rabbitmq-server/pull/2279)
  - [rabbitmq-common PR #368: Add `worker_pool:dispatch_sync` function](https://github.com/rabbitmq/rabbitmq-common/pull/368)


## Make targets

```
checkout-pr2279             Checkout the correct source for rabbitmq-server & rabbitmq-common
deps                        Resolve all dependencies
dev-server                  Run dev rabbitmq-server
dev-server-all-plugins      Run dev rabbitmq-server with all plugins
docker-image                Build & publish a Docker image of a custom RabbitMQ build
rabbitmq-public-umbrella    Setup a local copy for developing RabbitMQ
show-ctls                   Show where to find CTLs
switch-to-3.8.x             Switch local copy to v3.8.x
switch-to-3.9.x             Switch local copy to v3.9.x
which-release-series        Show which release series we are currently on
```
