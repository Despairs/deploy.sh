# deploy.sh

Bash function for copy and run applications.

Don't forget to `source` before usage!

Configuration location defined in `CONFIG` variable.

Configuration example:
``` yml
project:
  - name: 'logical project name'
    app:
      - name: 'logical application name'
        path: 'path to jar location'
    env:
      - name: 'logical enviroment name'
        host: 'ip'
        user: 'user'
        private-key: 'authorized ssh private key for this server'
        path: 
          app: 'path to app directory'
          start-app: 'path to start-app.sh directory'
```