
.. code-block:: yaml

  fluentd:
    agent:
      enabled: true
      flow:
        monitoring:
          filter:
            - pattern: 'docker.monitoring.{alertmanager,remote_storage_adapter,prometheus}.*'
              type: parser
              reserve_data: true
              key_name: log
              format: >-
                /^time="(?<time>[^ ]*)" level=(?<severity>[a-zA-Z]*) msg="(?<message>.+?)"/
              time_format: '%FT%TZ'
            - pattern: 'docker.monitoring.{alertmanager,remote_storage_adapter,prometheus}.*'
              type: record_transformer
              remove_keys: log
          match:
            - pattern: 'docker.**'
              type: file
              path: /tmp/flow-docker.log
        syslog:
          source:
            - type: tail
              path: /var/log/syslog
              tag: syslog.syslog
              format: >-
                '/^\<(?<pri>[0-9]+)\>(?<time>[^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$/'
              time_format: '%FT%T.%L%:z'
            - type: tail
              path: /var/log/auth.log
              tag: syslog.auth
              format: >-
                '/^\<(?<pri>[0-9]+)\>(?<time>[^ ]*) (?<host>[^ ]*) (?<ident>[a-zA-Z0-9_\/\.\-]*)(?:\[(?<pid>[0-9]+)\])?(?:[^\:]*\:)? *(?<message>.*)$/'
              time_format: '%FT%T.%L%:z'
          filter:
            - pattern: 'syslog.*'
              type: record_transformer
              enable_ruby: true
              record:
                - name: severity
                  value: 'record["pri"].to_i - (record["pri"].to_i / 8).floor * 8'
            - pattern: 'syslog.*'
              type: record_transformer
              enable_ruby: true
              record:
                - name: severity
                  value: '{"debug"=>7,"info"=>6,"notice"=>5,"warning"=>4,"error"=>3,"critical"=>2,"alert"=>1,"emerg"=>0}.key(record["severity"])'
            - pattern: 'syslog.*.telegraf'
              type: parser
              reserve_data: true
              key_name: message
              format: >-
                /^(?<time>[^ ]*) (?<severity>[A-Z])! (?<message>.*)/
              time_format: '%FT%TZ'
            - pattern: 'syslog.*.telegraf'
              type: record_transformer
              enable_ruby: true
              record:
                - name: severity
                  value: '{"debug"=>"D","info"=>"I","notice"=>"N","warning"=>"W","error"=>"E","critical"=>"C","alert"=>"A","emerg"=>"E"}.key(record["severity"])'
            - pattern: 'syslog.*'
              type: prometheus
              label:
                - name: ident
                  type: variable
                  value: ident
                - name: severity
                  type: variable
                  value: severity
              metric:
                - name: log_messages
                  type: counter
                  desc: The total number of log messages.
          match:
            - pattern: 'syslog.*'
              type: rewrite_tag_filter
              rule:
                - name: ident
                  regexp: '^(.*)'
                  result: '__TAG__.$1'
            - pattern: 'syslog.*.*'
              type: file
              path: /tmp/syslog
      source:
        prometheus:
          type: prometheus
        prometheus_monitor:
          type: prometheus_monitor
        prometheus_output_monitor:
          type: prometheus_output_monitor
        forward_listen:
          type: forward
          port: 24224
          bind: 0.0.0.0
