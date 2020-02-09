# TGIR S01E02: Help! RabbitMQ ate my RAM!

* Proposed by [@Farkie](https://github.com/Farkie) via [rabbitmq/tgir#5](https://github.com/rabbitmq/tgir/issues/5)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-02-28

## Timeline

* 00:00:00 - **Welcome to TGIR!**

## Agenda

- Help! RabbitMQ ate my RAM!
  - @Farkie via rabbitmq.slack.com
- Replicate the setup
- What is going on?
  - RabbitMQ Management - Node
  - RabbitMQ Management - Top
  - rabbitmq-diagnostics observer
  - Enable rabbitmq_prometheus
    - Integrate with Erlang Memory Allocators dashboard
    - Explain memory use via Erlang Memory Allocators
      - Repeat after a couple of days
- How do I fix it?
  - Restart it?
  - Bump high memory watermark
    - rabbitmqctl
    - set_config
- Is there a better approach?
    - Quorum Queues
      - On-disk by default
      - Better use of memory
      - Recover very well
      - Why not Lazy Queues?
- TGIR S01E01 follow-up
    - 3.6 -> 3.8 in-place upgrade
    - The implications of many vhosts
- Marques' tweet
    - Crossplane TBS
