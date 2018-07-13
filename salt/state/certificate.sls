py27-certbot:
  pkg.installed

py27-certbot-dns-route53:
  pkg.installed

/usr/local/etc/letsencrypt/cli.ini:
  file.managed:
    - require: 
        - pkg: py27-certbot
        - pkg: py27-certbot-dns-route53
    - makedirs: True
    - source: salt://letsencrypt.conf
    - user: root
    - group: wheel

register:
  cmd.run:
    - name: "certbot register --no-eff-email"
    - runas: root
    - creates: /usr/local/etc/letsencrypt/accounts
