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

provision:
  cmd.run:
    - name: "certbot certonly --dns-route53 --domains test.danhatesnumbers.co.uk"
    - runas: root
    - creates: /usr/local/etc/letsencrypt/live/test.danhatesnumbers.co.uk/fullchain.pem

renew:
  cmd.run:
    - name: "certbot renew"
    - runas: root