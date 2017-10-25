{% from "fluentd/map.jinja" import agent with context %}
{%- if agent.enabled %}

fluentd_packages_agent:
  pkg.installed:
    - names: {{ agent.pkgs }}

fluentd_gems_agent:
  gem.installed:
    - names: {{ agent.gems }}
    - gem_bin: {{ agent.gem_path }}
    - require:
      - pkg: fluentd_packages_agent

fluentd_config_d_dir:
  file.directory:
    - name: {{ agent.dir.config }}/config.d
    - makedirs: True
    - mode: 755
    - require:
      - pkg: fluentd_packages_agent

fluentd_config_service:
  file.managed:
    - name: /etc/default/td-agent
    - source: salt://fluentd/files/default-td-agent
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      agent: {{ agent }}

fluentd_config_agent:
  file.managed:
    - name: {{ agent.dir.config }}/td-agent.conf
    - source: salt://fluentd/files/td-agent.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      agent: {{ agent }}

fluentd_grok_pattern_agent:
  file.managed:
    - name: {{ agent.dir.config }}/config.d/global.grok
    - source: salt://fluentd/files/global.grok
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      agent: {{ agent }}

{%- for name,values in agent.get('input', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}

input_{{ name }}_agent:
  file.managed:
    - name: {{ agent.dir.config }}/config.d/input-{{ name }}.conf
    - source:
      - salt://fluentd/files/input/{{ values.type }}.conf
      - salt://fluentd/files/input/generic.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
{%- if values is mapping %}
        values: {{ values }}
{%- else %}
        values: {}
{%- endif %}

{%- endif %}
{%- endfor %}

{%- for name,values in agent.get('filter', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}

filter_{{ name }}_agent:
  file.managed:
    - name: {{ agent.dir.config }}/config.d/filter-{{ name }}.conf
    - source:
      - salt://fluentd/files/filter/{{ values.type }}.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
{%- if values is mapping %}
        values: {{ values }}
{%- else %}
        values: {}
{%- endif %}

{%- endif %}
{%- endfor %}

{%- for name,values in agent.get('output', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}

output_{{ name }}_agent:
  file.managed:
    - name: {{ agent.dir.config }}/config.d/match-{{ name }}.conf
    - source:
      - salt://fluentd/files/output/{{ values.type }}.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
{%- if values is mapping %}
        values: {{ values }}
{%- else %}
        values: {}
{%- endif %}

{%- endif %}
{%- endfor %}

{%- for name,values in agent.get('flow', {}).iteritems() %}
{%- if values is not mapping or values.get('enabled', True) %}

flow_{{ name }}_agent:
  file.managed:
    - name: {{ agent.dir.config }}/config.d/flow-{{ name }}.conf
    - source:
      - salt://fluentd/files/flow.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
      - file: fluentd_config_d_dir
    - watch_in:
      - service: fluentd_service_agent
    - defaults:
        name: {{ name }}
{%- if values is mapping %}
        values: {{ values }}
{%- else %}
        values: {}
{%- endif %}

{%- endif %}
{%- endfor %}

fluentd_service_agent:
  service.running:
    - name: {{ agent.service_name }}
    - enable: True
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: fluentd_config_agent

{%- endif %}
