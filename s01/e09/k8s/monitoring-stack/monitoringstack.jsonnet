local kp = (import 'kube-prometheus/kube-prometheus.libsonnet') + {
	_config+:: {
		namespace: 'monitoring',
	},
	grafanaDashboards+:: {
		'erlang-distribution.json': (import 'dashboards/erlang-distribution_rev3.json'),
		'erlang-distributions-compare.json': (import 'dashboards/erlang-distributions-compare_rev8.json'),
		'erlang-memory-allocators.json': (import 'dashboards/erlang-memory-allocators_rev3.json'),
		'rabbitmq-overview.json': (import 'dashboards/rabbitmq-overview_rev7.json'),
		'rabbitmq-perftest.json': (import 'dashboards/rabbitmq-perftest_rev7.json'),
		'rabbitmq-quorum-queues-raft.json': (import 'dashboards/rabbitmq-quorum-queues-raft_rev2.json'),
	},
	grafana+:: {
		dashboards+:: {
			'erlang-distribution.json': (import 'dashboards/erlang-distribution_rev3.json'),
			'erlang-distributions-compare.json': (import 'dashboards/erlang-distributions-compare_rev8.json'),
			'erlang-memory-allocators.json': (import 'dashboards/erlang-memory-allocators_rev3.json'),
			'rabbitmq-overview.json': (import 'dashboards/rabbitmq-overview_rev7.json'),
			'rabbitmq-perftest.json': (import 'dashboards/rabbitmq-perftest_rev7.json'),
			'rabbitmq-quorum-queues-raft.json': (import 'dashboards/rabbitmq-quorum-queues-raft_rev2.json'),
		},
	},
};

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
	['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
		for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana) }
