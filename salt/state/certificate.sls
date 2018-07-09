include:
  - letsencrypt

setup_letsencrypt:
  file.managed:
    - require: letsencrypt.install
    - name: "/etc/letsencrypt/cli.ini"
    - source: salt://letsencrypt.conf