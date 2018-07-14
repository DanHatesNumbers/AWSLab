security/openssl-devel:
  ports.installed:
    - options:
      - RC2: off
      - RC4: off
      - MD4: off
      - RMD160: off

www/nginx-lite:
  ports.installed:
    - options:
      - HTTPV2: on
    - require:
      - pkg: openssl-devel

dhparam:
  cmd.run:
    - name: "openssl dhparam -out /usr/local/etc/nginx/dhparam.pem 2048"
    - require:
      - pkg: openssl-devel
    - runas: root
    - creates: /usr/local/etc/nginx/dhparam.pem

nginx-service:
  service.running:
    - name: nginx
    - require:
      - pkg: nginx-lite
    - watch_any:
      - file: /usr/local/etc/nginx/nginx.conf
      - file: /usr/local/etc/nginx/conf.d/test.danhatesnumbers.co.uk.conf

/var/www/test.danhatesnumbers.co.uk/index.html:
  file.managed:
    - require:
      - pkg: nginx-lite
    - source: salt://index.html
    - user: www
    - group: www
    - makedirs: True

/usr/local/etc/nginx/nginx.conf:
  file.managed:
    - require: 
      - pkg: nginx-lite
    - source: salt://nginx.conf
    - user: root
    - group: wheel

/usr/local/etc/nginx/conf.d/test.danhatesnumbers.co.uk.conf:
  file.managed:
    - require:
      - pkg: nginx-lite
    - source: salt://test.danhatesnumbers.co.uk.conf
    - makedirs: True
    - user: root
    - group: wheel

/usr/local/etc/nginx/nginx.conf-dist:
  file.absent