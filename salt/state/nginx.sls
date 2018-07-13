nginx:
  pkg.installed

nginx-service:
  service.running:
    - name: nginx
    - watch_any:
      - file: /usr/local/etc/nginx/nginx.conf
      - file: /usr/local/etc/nginx/conf.d/test.danhatesnumbers.co.uk.conf

/var/www/test.danhatesnumbers.co.uk/index.html:
  file.managed:
    - require:
      - pkg: nginx
    - source: salt://index.html
    - user: www
    - group: www
    - makedirs: True

/usr/local/etc/nginx/nginx.conf:
  file.managed:
    - require: 
      - pkg: nginx
    - source: salt://nginx.conf
    - user: root
    - group: wheel

/usr/local/etc/nginx/conf.d/test.danhatesnumbers.co.uk.conf:
  file.managed:
    - require:
      - pkg: nginx
    - source: salt://test.danhatesnumbers.co.uk.conf
    - makedirs: True
    - user: root
    - group: wheel