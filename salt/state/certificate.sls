include:
  - letsencrypt

setup_letsencrypt:
    - letsencrypt.install
    - file.managed:
        - name: "/etc/letsencrypt/cli.ini"
        - source: salt://letsencrypt.conf