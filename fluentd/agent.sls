{% from "fluentd/map.jinja" import fluentd with context %}
{%- if fluentd.get('enabled', False) %}

fluentd_packages_agent:
  pkg.installed:
    - names: {{ fluentd.pkgs }}

fluentd_gems_agent:
  gem.installed:
    - names: {{ fluentd.gems }}
    - gem_bin: {{ fluentd.gem_path }}
    - require:
      - pkg: fluentd_packages_agent

fluentd_config_d_dir:
  file.directory:
    - name: {{ fluentd.dir.config }}/config.d
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
      fluentd: {{ fluentd }}

fluentd_config_agent:
  file.managed:
    - name: {{ fluentd.dir.config }}/td-agent.conf
    - source: salt://fluentd/files/td-agent.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      fluentd: {{ fluentd }}

fluentd_grok_pattern_agent:
  file.managed:
    - name: {{ fluentd.dir.config }}/config.d/global.grok
    - source: salt://fluentd/files/global.grok
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: fluentd_packages_agent
    - context:
      fluentd: {{ fluentd }}

{%- set fluentd_config = fluentd.get('config', {}) %}
{%- for name,values in fluentd_config.get('input', {}).iteritems() %}

input_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd.dir.config }}/config.d/input-{{ name }}.conf
    - source:
      - salt://fluentd/files/input/_generate.conf
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

{%- endfor %}

{%- for name,values in fluentd_config.get('filter', {}).iteritems() %}

filter_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd.dir.config }}/config.d/filter-{{ name }}.conf
    - source:
      - salt://fluentd/files/filter/_generate.conf
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

{%- endfor %}

{%- for name,values in fluentd_config.get('match', {}).iteritems() %}

omatch_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd.dir.config }}/config.d/match-{{ name }}.conf
    - source:
      - salt://fluentd/files/match/_generate.conf
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

{%- endfor %}

{%- for name,values in fluentd_config.get('label', {}).iteritems() %}

label_{{ name }}_agent:
  file.managed:
    - name: {{ fluentd.dir.config }}/config.d/label-{{ name }}.conf
    - source:
      - salt://fluentd/files/label.conf
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

{%- endfor %}

fluentd_service_agent:
  service.running:
    - name: {{ fluentd.service_name }}
    - enable: True
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - watch:
      - file: fluentd_config_agent

{%- endif %}
