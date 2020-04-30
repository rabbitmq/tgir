# TGIR S01E04: How to contribute to RabbitMQ? Part 2

* Proposed via [rabbitmq/tgir#4](https://github.com/rabbitmq/tgir/issues/4)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-04-30

<a href="https://www.youtube.com/watch?v=9q-_DLfhfYg" target="_blank"><img src="video.jpg" border="50" /></a>

This is the second part on how to contribute to RabbitMQ.

See how you can contribute a new Erlang/OTP 22 feature to RabbitMQ 3.8 in these three simple steps:

1. Add a few lines of code to [rabbitmq-prometheus](https://github.com/rabbitmq/rabbitmq-prometheus) plugin
2. Update the [Erlang-Distribution](https://grafana.com/grafana/dashboards/11352) Grafana dashboard
3. Open a pull request 🙌🏻

The goal of this episode is for **you** to contribute this change 😉

Notes and links at https://github.com/rabbitmq/tgir/tree/S01E04/s01/e04



## TIMELINE

- This is what you will be contributing, and why (00:00)
- All contributions start with an issue (05:20)
- Start your contribution by writing a failing test (08:19)
- Make the test pass locally (12:19)
- Submit your contribution early as a draft pull-request (13:24)
- Run everything locally & capture observations (15:31)
- Mark the pull-request as ready for review (27:39)
- How can you help us accept contributions promptly (28:00)
- How do you know which version of RabbitMQ to expect a contribution in? (30:00)
- Clean state on your local host (31:38)



## LINKS

- [erlang/otp #2270](https://github.com/erlang/otp/pull/2270) - [Which releases?](https://github.com/erlang/otp/pull/2270/commits/302840129567426fd882484606bdc27ed3087eca)
- [prometheus.erl #94](https://github.com/deadtrickster/prometheus.erl/pull/94)
- [rabbitmq/rabbitmq-prometheus #39](https://github.com/rabbitmq/rabbitmq-prometheus/issues/39)
- [Erlang-Distribution Grafana Dashboard](https://grafana.com/grafana/dashboards/11352)
- [Erlang.mk - Common Test](https://erlang.mk/guide/ct.html)
- [RabbitMQ Runtime Tuning - Inter-node Communication Buffer Size](https://www.rabbitmq.com/runtime.html#distribution-buffer)
- [Erlang +zdbbl](https://erlang.org/doc/man/erl.html#+zdbbl)
- [RabbitMQ - All release notes](https://github.com/rabbitmq/rabbitmq-website/tree/live/site/release-notes)
