{% set gpg_pub_key = pillar.get('gpg_pub_key', False) %}

{% if gpg_pub_key %}
{% set key_email = salt["cmdmod.run"]("echo '" ~ gpg_pub_key + "'|gpg --with-fingerprint|head -n 1|awk '{ print \$NF }'|tr -d '<>'") %}
{% set key_fingerprint = salt["cmdmod.run"]("echo '" ~ gpg_pub_key ~ "'|gpg --with-fingerprint|grep fingerprint|awk -F= '{ print \$2 }'|sed 's/ //g'|tr -d '\n'") %}
{% set key_id = key_fingerprint[-8:] %}
import_private_gpg_key:
  cmd.run:
    - name: echo '{{ pillar['gpg_priv_key'] }}' | gpg --import -
    - unless: gpg --list-secret-keys {{ key_email }}
import_public_gpg_key:
  cmd.run:
    - name: echo '{{ gpg_pub_key }}' | gpg --import -
    - unless: gpg --list-keys {{ key_email }}
trust_public_gpg_key:
  cmd.run:
    - name: echo '{{ key_fingerprint }}:6:' | gpg --import-ownertrust
    - unless: gpg --export-ownertrust|grep {{ key_fingerprint }}|grep -q :6:
    - require:
      - cmd.run: import_public_gpg_key
{% elif pillar['gpg_key_id'] %}
{% set key_id = gpg_key_id %}
{% endif %}

duplicity:
  pkg:
    - installed

python-paramiko:
  pkg:
    - installed

# This is to avoid the "no module gio" warning
python-gobject:
  pkg:
    - installed

/usr/local/sbin/custom_backup:
  file.managed:
    - template: jinja
    - source: salt://duplicity/custom_backup
    - makedirs: True
    - mode: 700
      
{% set when_to_run = pillar.get('when_to_run', '0 4 * * *') %}
/etc/cron.d/duplicity':
  file.managed:
    - mode: 600
    - contents: {{ when_to_run }} root /usr/local/sbin/custom_backup scheduled

{% set pre = pillar.get('pre', 'False') %}
{% set post = pillar.get('post', 'False') %}

{% if pre %}
/etc/duplicity/pre:
  file.managed:
    - mode: 700
    - contents: {{ pre }}
    - makedirs: True
{% endif %}

{% if post %}
/etc/duplicity/post:
  file.managed:
    - mode: 700
    - contents: {{ post }}
    - makedirs: True
{% endif %}
