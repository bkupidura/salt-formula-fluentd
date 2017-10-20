{%- if pillar.fluentd.agent %}
include:
  {%- if pillar.fluentd.agent is defined %}
  - fluentd.agent
  {%- endif %}
{%- endif %}
