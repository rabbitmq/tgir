# TGIR S01E04: How to contribute to RabbitMQ? Part 2

* Proposed via [rabbitmq/tgir#4](https://github.com/rabbitmq/tgir/issues/4)
* Hosted by [@gerhardlazu](https://twitter.com/gerhardlazu)
* Published on: 2020-04-30

<a href="https://www.youtube.com/watch?v=TGIRS01E04" target="_blank"><img src="video.jpg" border="50" /></a>

This is the second part on how to contribute to RabbitMQ.
We show you how to make your first RabbitMQ contribution in 3 simple steps:

1. Add a new Erlang/OTP 22 feature to [rabbitmq-prometheus](https://github.com/rabbitmq/rabbitmq-prometheus) in a few lines of Erlang
2. Update [Erlang-Distribution Grafana dashboard](https://grafana.com/grafana/dashboards/11352)
3. Contribute your first pull request to RabbitMQ!

We show how to link multiple contributions together, across multiple repositories:
- start with Erlang/OTP
- continue with prometheus.erl & rabbitmq-prometheus
- finish off with the Erlang-Distribution Grafana dashboard

The goal of this episode is to have you contribute this change 😉



## TIMELINE

- In today's episode... ([00:00](https://www.youtube.com/watch?v=TGIRS01E04&t=0s))

### START WITH AN ISSUE
- Is this a new or an existing issue?
- Capture why it is worth doing
- Wait for a reply if unsure, continue otherwise

### CONTINUE WITH A PULL REQUEST (PR)
- Explore & write a failing test
- Submit little & early as WIP
- Link to relevant issues/PRs
- Make it pass locally
- Make it pass remotely
- Keep history clean
- Run it locally & capture observations
- Change the PR state to done

### HELP A RABBITMQ TEAM MEMBER MERGE THE PR
- Who to ask for a review? or Who is the code owner?
- Assign a milestone **to the issue**
- Merge when checks are green
- Know which version of RabbitMQ to expect it in



## LINKS

- [erlang/otp #2270](https://github.com/erlang/otp/pull/2270) - [Which releases?](https://github.com/erlang/otp/pull/2270/commits/302840129567426fd882484606bdc27ed3087eca)
- [prometheus.erl #94](https://github.com/deadtrickster/prometheus.erl/pull/94)
- [rabbitmq/rabbitmq-prometheus #39](https://github.com/rabbitmq/rabbitmq-prometheus/issues/39)
- [Erlang-Distribution Grafana Dashboard](https://grafana.com/grafana/dashboards/11352)
- [Erlang.mk - Common Test](https://erlang.mk/guide/ct.html)
- [RabbitMQ Runtime Tuning - Inter-node Communication Buffer Size](https://www.rabbitmq.com/runtime.html#distribution-buffer)
- [Erlang +zdbbl](https://erlang.org/doc/man/erl.html#+zdbbl)
- [RabbitMQ - All release notes](https://github.com/rabbitmq/rabbitmq-website/tree/live/site/release-notes)
