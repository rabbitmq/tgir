# Episode 002: How to upgrade RabbitMQ 3.7 to 3.8 in prod?

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
