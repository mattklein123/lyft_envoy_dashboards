{% from "macros/envoy_stats.sls" import ingress_stats, egress_stats, circuit_breaking %}

{% for cluster_suffix, canary  in
  [('', False),
   ('_canary', True),
  ]
%}
Ensure service_to_service{{cluster_suffix}} dashboard is managed:
  lyft_dashboard.present:
    - name: service_to_service{{cluster_suffix}}
    - base_rows_from_pillar:
      - 'grafana_rows:title'
    - base_panels_from_pillar:
      - 'grafana_panels:no_fill'
      - 'grafana_panels:hide_legend'
      - 'grafana_panels:thin'
    - dashboard:
        refresh: 1m
        time:
          from: "now-6h"
          to: "now-2m"
        rows:
          - title: Dashboard README
            height: 50
            showTitle: True
            panels:
              - title:
                content: This dashboard is used to display stats for requests sent from lyft microservice A to lyft microservice B. Both microservices must be using envoy for this dashboard to fully populate. Explanation of these stats can be found [at this link](https://github.com/lyft/envoy-private/blob/master/docs/stats.md#service_to_service-dashboard-stats)
                type: text
          {{egress_stats('$originating_service', '$destination_service', canary)}}
          {{circuit_breaking('$originating_service', '$destination_service')}}
          {{ingress_stats('$destination_service', canary)}}
        templating:
          list:
            - name: environment
              type: custom
              refresh_on_load: False
              query: 'production,staging'
              refresh: True
              current:
                text: production
                value: production
              options:
                - selected: True
                  text: production
                  value: production
                - selected: False
                  text: staging
                  value: staging
            - name: originating_service
              type: query
              query: "tagValue(production.infra.aws.autoscaling.grouptotalinstances.average, autoscalinggroupname, *)"
              regex: /([^-]+)/
              refresh: True
              sort: 1
              datasource: wavefront
              current:
                text: api
                value: api
            - name: destination_service
              type: query
              query: "hostValue(production.infra.aws.ec2.asg.envoy.cluster, $originating_service)"
              regex: /cluster\.([^.]+)/
              refresh: True
              sort: 1
              datasource: wavefront
              current:
                text: locations
                value: locations
{% endfor %}
