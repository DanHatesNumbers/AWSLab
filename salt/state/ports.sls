fetch-ports:
  cmd.run:
    - name: portsnap fetch --interactive

extract-ports:
  cmd.run:
    - name: portsnap extract
    - creates: /usr/ports

update-ports:
  cmd.run:
    - name: portsnap update
    