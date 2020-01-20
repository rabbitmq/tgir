# TGIR S01E01: How to upgrade from RabbitMQ 3.7 to 3.8?

* Proposed by [@dlresende](https://twitter.com/dlresende) via [rabbitmq/tgir#2](https://github.com/rabbitmq/tgir/issues/2)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-01-31

## Introduction

### [Diego Lemos](https://twitter.com/dlresende), Engineering Lead, Pivotal R&D:

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
Bonus points if I can see how to do it right, which would go really well alongside the already excellent [Upgrading RabbitMQ](https://www.rabbitmq.com/upgrade.html) guide.

## Three nodes, production cluster, best practice

* 24k connections & channels - 8k connections per node
* 12k queues with 10k messages each - 4k queues per node, 400k messages per node
* each message is 1KB in size
* minimal service degradation

This is how you do it: ...

No downtime -> longer upgrade

Service downtime -> faster upgrade

### Why not grow the cluster?

## Two nodes

Network partition strategy behaviour:

- ignore
- pause minority
- autoheal

Mirror all - 1-by-1 vs all at once

Grow cluster, force queues to re-locate?

## Single node

### How do I stop RabbitMQ gracefully?

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

### What impact does the size of messages have on node boot time?

* 4 message sizes: 1/8/16/32KB

### What happens if messages use TTL?

| Queue type | Message flag | Messages lost      |
| ---        | ---          | :--                |
| Durable    | persistent   | Yes if TTL expires |
| Lazy       | persistent   | Yes if TTL expires |


### Will confirmed & unacked messages be lost during a node upgrade?

### How do I know when a RabbitMQ node is ready for traffic?

### What happens when there are many messages to restore?

1mil messages in queue

The speed of booting the updated node will depend on how many messages need to be loaded from disk - every queue will load up to 16k messages in memory. This puts pressure on disk & memory.

### What happens when there are many messages and queues to restore?

### What can I do if the memory alarm gets triggered?

A bad situation is when a node boots and triggers the disk or memory alarm.

### What can I do if the disk alarm gets triggered?
