letsencrypt:
  pkg.installed

/etc/letsencrypt/cli.ini:
  file.managed:
    - require:
      - pkg: letsencrypt
    - source: salt://letsencrypt.conf
    - user: root
    - group: wheel
