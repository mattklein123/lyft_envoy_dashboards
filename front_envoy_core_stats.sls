{% macro top_level_all_hosts(asg, regions, canary, pd, sr_condition, condition_4xx) %}
          - title: TOP LEVEL ALL HOSTS
            panels:
              - title: CPS
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_ssl_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}} SSL'
                {% endfor %}
              - title: RPS
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                {% endfor %}
              - title: Total Connections
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_active.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_ssl_active.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}} SSL'
                {% endfor %}
              - title: Total Requests
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_active.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                {% endfor %}
              - title: Success Rate (non-5xx responses)
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: '(1 - (rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_5xx.instance.count.rate, region={{region}} and asg={{asg}})) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_*xx.instance.count.rate, region={{region}} and asg={{asg}})))) * 100'
                    name: '{{region}}'
                {% if canary %}
                  - target: '(1 - (rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_5xx.instance.count.rate, region={{region}} and asg={{asg}} and canary=true)) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_*xx.instance.count.rate, region={{region}} and asg={{asg}} and canary=true)))) * 100'
                    name: '{{region}} Canary'
                {% endif %}
                {% endfor %}
                y_formats:
                  - percent
                  - short
                alarms:
                  - name: Envoy Success Rate
                    query: (100 - ((ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_5xx.count.sum, asg={{asg}}) / sum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_*xx.count.sum, asg={{asg}}))) * 100))
                    condition: $query < {{ sr_condition }}
                    minutes: 3
                    service: {{ pd }}
                    hide: True
              - title: 4xx
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: '(rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_4xx.instance.count.rate, region={{region}} and asg={{asg}})) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_*xx.instance.count.rate, region={{region}} and asg={{asg}}))) * 100'
                    name: '{{region}}'
                {% if canary %}
                  - target: '(rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_4xx.instance.count.rate, region={{region}} and asg={{asg}} and canary=true)) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_*xx.instance.count.rate, region={{region}} and asg={{asg}} and canary=true))) * 100'
                    name: '{{region}} Canary'
                {% endif %}
                {% endfor %}
                y_formats:
                  - percent
                  - short
                alarms:
                  - name: Envoy 4xx % is high
                    query: ((rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_4xx.instance.count.rate, asg={{asg}})) / rawsum(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_*xx.instance.count.rate, asg={{asg}}))) * 100)
                    condition: $query > {{ condition_4xx }}
                    minutes: 3
                    service: {{ pd }}
                    hide: True
{% endmacro %}

{% macro per_host(asg, regions, canary, pd, cps_condition, rps_condition, total_cx_condition, total_req_condition) %}
          - title: PER HOST
            panels:
              - title: Downstream CPS
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_total.instance.count.rate, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Canary'
                {% endif %}
                {% endfor %}
                alarms:
                  - name: Envoy per host CPS is high
                    query: ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_total.instance.count.rate, asg={{asg}})
                    condition: $query > {{ cps_condition }}
                    minutes: 3
                    service: {{ pd }}
                    hide: True
              - title: Downstream RPS
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_total.instance.count.rate, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Canary'
                {% endif %}
                {% endfor %}
                alarms:
                  - name: Envoy per host RPS is high
                    query: ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_total.instance.count.rate, asg={{asg}})
                    condition: $query > {{ rps_condition }}
                    minutes: 3
                    service: {{ pd }}
                    hide: True
              - title: Downstream Total Connections
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_active.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.server.parent_connections.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}} Parent'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_active.instance.gauge.mean, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.server.parent_connections.instance.gauge.mean, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Parent Canary'
                {% endif %}
                {% endfor %}
                alarms:
                  - name: Envoy per host total connections is high
                    query: ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_active.instance.gauge.mean, asg={{asg}})
                    condition: $query > {{ total_cx_condition }}
                    minutes: 3
                    service: {{ pd }}
                    hide: True
              - title: Downstream Total Requests
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_active.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}}'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_active.instance.gauge.mean, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Canary'
                {% endif %}
                {% endfor %}
                alarms:
                  - name: Envoy per host total request is high
                    query: ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_rq_active.instance.gauge.mean, asg={{asg}})
                    condition: $query > {{ total_req_condition }}
                    minutes: 3
                    service: {{ pd }}
                    hide: True
              - title: Downstream Connection Length
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_length_ms.instance.timer.p50, region={{region}} and asg={{asg}}))'
                    name: '{{region}} P50'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_length_ms.instance.timer.p95, region={{region}} and asg={{asg}}))'
                    name: '{{region}} P95'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_length_ms.instance.timer.p50, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} P50 Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_length_ms.instance.timer.p95, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} P95 Canary'
                {% endif %}
                {% endfor %}
                y_formats:
                  - ms
                  - short
              - title: Upstream RPS All Clusters
                datasource: wavefront
                targets:
                  - target: 'rawavg(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_total.instance.count.rate, region=iad and asg={{asg}}), metric, cluster, 7), cluster)'
                    regexes:
                      - regex: "cluster='([^']+)'"
                        replacement: $1
                {% if canary %}
                  - target: 'rawavg(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_total.instance.count.rate, region=iad and asg={{asg}} and canary=true), metric, cluster, 7), cluster)'
                    regexes:
                      - regex: "cluster='([^']+)'"
                        replacement: $1 Canary
                {% endif %}
              - title: Upstream 5xx All Clusters
                datasource: wavefront
                targets:
                  - target: 'rawavg(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_5xx.instance.count.rate, region=iad and asg={{asg}}), metric, cluster, 7), cluster)'
                    regexes:
                      - regex: "cluster='([^']+)'"
                        replacement: $1
                {% if canary %}
                  - target: 'rawavg(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_5xx.instance.count.rate, region=iad and asg={{asg}} and canary=true), metric, cluster, 7), cluster)'
                    regexes:
                      - regex: "cluster='([^']+)'"
                        replacement: $1 Canary
                {% endif %}
              - title: Upstream P99 All Clusters
                datasource: wavefront
                targets:
                  - target: 'rawavg(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_time.instance.timer.p99, region=iad and asg={{asg}}), metric, cluster, 7), cluster)'
                    regexes:
                      - regex: "cluster='([^']+)'"
                        replacement: $1
                {% if canary %}
                  - target: 'rawavg(taggify(ts(production.infra.aws.ec2.asg.envoy.cluster.*.upstream_rq_time.instance.timer.p99, region=iad and asg={{asg}} and canary=true), metric, cluster, 7), cluster)'
                    regexes:
                      - regex: "cluster='([^']+)'"
                        replacement: $1 Canary
                {% endif %}
                y_formats:
                  - ms
                  - short
{% endmacro %}

{% macro system_health(asg, regions, canary) %}
          - title: SYSTEM HEALTH
            panels:
              - title: Memory
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.instance.memory.memory.free.gauge.value, region={{region}} and asg={{asg}}))'
                    name: '{{region}} System Free Memory'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.server.memory_allocated.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}} Envoy Allocated'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.server.memory_heap_size.instance.gauge.mean, region={{region}} and asg={{asg}}))'
                    name: '{{region}} Envoy Reserved'
                {% if canary %}
                  - target: 'rawavg(ts(production.infra.aws.ec2.instance.memory.memory.free.gauge.value, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} System Free Memory Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.server.memory_allocated.instance.gauge.mean, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Envoy Allocated Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.server.memory_heap_size.instance.gauge.mean, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Envoy Reserved Canary'
                {% endif %}
                {% endfor %}
                y_formats:
                  - bytes
                  - short
              - title: CPU Idle
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(rawavg(rate(ts(production.infra.aws.ec2.instance.cpu-average.cpu.idle.gauge.value, asg={{asg}} and region={{ region }})), "_host"))'
                    name: '{{region}}'
                {% if canary %}
                  - target: 'rate(ts(production.infra.aws.ec2.instance.cpu-average.cpu.idle.gauge.value, asg={{asg}} and region={{ region }} and canary=true))'
                    name: '{{region}} Canary'
                {% endif %}
                {% endfor %}
                y_formats:
                  - percent
                  - short
              - title: Network
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawavg(rate(ts(production.infra.aws.ec2.instance.interface.eth0.if_octets.octets.rx.gauge.value, region={{region}} and asg={{asg}})))'
                    name: '{{region}} System RX'
                  - target: 'rawavg(rate(ts(production.infra.aws.ec2.instance.interface.eth0.if_octets.octets.tx.gauge.value, region={{region}} and asg={{asg}})))'
                    name: '{{region}} System TX'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_rx_bytes_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}} Envoy Downstream RX'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_tx_bytes_total.instance.count.rate, region={{region}} and asg={{asg}}))'
                    name: '{{region}} Envoy Downstream TX'
                {% if canary %}
                  - target: 'rawavg(rate(ts(production.infra.aws.ec2.instance.interface.eth0.if_octets.octets.rx.gauge.value, region={{region}} and asg={{asg}} and canary=true)))'
                    name: '{{region}} System RX Canary'
                  - target: 'rawavg(rate(ts(production.infra.aws.ec2.instance.interface.eth0.if_octets.octets.tx.gauge.value, region={{region}} and asg={{asg}} and canary=true)))'
                    name: '{{region}} System TX Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_rx_bytes_total.instance.count.rate, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Envoy Downstream RX Canary'
                  - target: 'rawavg(ts(production.infra.aws.ec2.asg.envoy.http.router.downstream_cx_tx_bytes_total.instance.count.rate, region={{region}} and asg={{asg}} and canary=true))'
                    name: '{{region}} Envoy Downstream TX Canary'
                {% endif %}
                {% endfor %}
                y_formats:
                  - Bps
                  - short
              - title: Num Servers
                datasource: wavefront
                targets:
                {% for region in regions %}
                  - target: 'rawsum(ts(production.infra.aws.ec2.asg.envoy.server.live.instance.gauge.mean, region={{region}} and asg={{asg}} and "_host"="*production*"))'
                    name: '{{region}} Not Draining'
                {% endfor %}
{% endmacro %}
