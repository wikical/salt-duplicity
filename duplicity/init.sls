{% set gpg_pub_key = pillar.duplicity.get('gpg_pub_key', False) %}

{% if gpg_pub_key %}
{% set key_email = salt['cmd.run']("echo '" ~ gpg_pub_key ~ "'|gpg --with-fingerprint|head -n 1|awk '{ print $NF }'|tr -d '<>'") %}
{% set key_fingerprint = salt['cmd.run']("echo '" ~ gpg_pub_key ~ "'|gpg --with-fingerprint|grep fingerprint|awk -F= '{ print $2 }'|sed 's/ //g'|tr -d '\n'") %}
{% set key_id = key_fingerprint[-8:] %}
import_private_gpg_key:
  cmd.run:
    - name: |
        echo '{{ pillar.duplicity.gpg_priv_key.replace("\n", "\n        ")  }}' | gpg --import -
    - unless: gpg --list-secret-keys {{ key_email }}
import_public_gpg_key:
  cmd.run:
    - name: |
        echo '{{ gpg_pub_key.replace("\n", "\n        ") }}' | gpg --import -
    - unless: gpg --list-keys {{ key_email }}
trust_public_gpg_key:
  cmd.run:
    - name: echo '{{ key_fingerprint }}:6:' | gpg --import-ownertrust
    - unless: "gpg --export-ownertrust|grep {{ key_fingerprint }}|grep -q :6:"
    - require:
      - cmd.run: import_public_gpg_key
{% elif pillar.duplicity.get('gpg_key_id', False) %}
{% set key_id = pillar.duplicity.gpg_key_id %}
{% endif %}

duplicity:
  pkg:
    - installed

# We install paramiko from pip, because the Debian version has some
# problems; notably later paramiko versions have improved on
# https://github.com/paramiko/paramiko/issues/17.
paramiko:
  pip.installed:
    - name: paramiko == 1.12.1
python-paramiko:
  pkg:
    - purged

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
    - defaults:
        gpg_pw: {{ pillar.duplicity.get('gpg_pw', '') }}
        target_pw: {{ pillar.duplicity.get('target_pw', '') }}
        target: {{ pillar.duplicity.target }}
        verbosity: {{ pillar.duplicity.get('verbosity', 4) }}
        key_id: {{ key_id }}
        includes_excludes: {{ pillar.duplicity.get('includes_excludes', '') }}
        extra_parms: {{ pillar.duplicity.get('extra_parms', '') }}
        pre: {{ pillar.duplicity.get('pre', '') }}
        post: {{ pillar.duplicity.get('post', '') }}
        remove_older_than: {{ pillar.duplicity.get('remove_older_than', '2Y') }}
        remove_all_inc_of_but_n_full: {{ pillar.duplicity.get('remove_all_inc_of_but_n_full', '') }}
        full_if_older_than: {{ pillar.duplicity.get('full_if_older_than', '1M') }}
        source: {{ pillar.duplicity.get('source', '/') }}
      
{% set when_to_run = pillar.duplicity.get('when_to_run', '0 4 * * *') %}
/etc/cron.d/duplicity:
  file.managed:
    - mode: 600
    - contents: "{{ when_to_run }} root /usr/local/sbin/custom_backup scheduled\n"

{% set pre = pillar.duplicity.get('pre', 'False') %}
{% set post = pillar.duplicity.get('post', 'False') %}

{% if pre %}
/etc/duplicity/pre:
  file.managed:
    - mode: 700
    - contents: |
        {{ pre.replace("\n", "\n        ") }}
    - makedirs: True
{% endif %}

{% if post %}
/etc/duplicity/post:
  file.managed:
    - mode: 700
    - contents: |
        {{ post.replace("\n", "\n        ") }}
    - makedirs: True
{% endif %}
