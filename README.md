# Container Broker

## Routes

### POST /handshake
  - Register a new node to container broker pool
  - Paramters: `{ "hostname": "", "cores": 10, "memory": 4096 }`
  - Response:   `{ "status": "ok|error" }`

### POST /job
  - Cria de um container que executa um determinado comando dentro de uma imagem
  - Creates a container from given image to run given command
  - Paramters: `{ "name": "", "image": "", "cmd": "", "storage_mount": "", "tags": {"slug": "slug3166h", "type": "video"} }`
  - Retorno:
  ```json
  {
    "status": "ok|error",
    "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9"
  }
  ```

### GET /job/:uuid
  - Show information about some job
  - Parameters (query string): `id`
  - Response:
  ```json
  {
    "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9",
    "status": "waiting|running|completed|error"
  }
  ```

### GET /status
  - Show pool informations
  - Response:
  ```json
  {
    "nodes": [
      {
        "hostname": "",
        "cores": 10,
        "memory": 4096,
        "jobs": [
          {
            "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9",
            "status": "waiting|running|completed|error"
          }
        ]
      }
    ]
  }
  ```

## Deploy

### Tsuru
Command: `tsuru app-deploy -a container-broker-dev`










