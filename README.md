# Container Broker

## Routes

### POST /nodes
  - Register a new node to container broker pool
  - Parameters: `{ "hostname": "", "slots_execution_types": {"cpu": 2, "network", 10} }`
  - Response:   `{ "status": "ok|error" }`

### POST /tasks
  - Creates a container from given image to run given command
  - Parameters: `{ "name": "", "image": "", "cmd": "", "storage_mount": "", "tags": {"slug": "slug3166h", "type": "video"} }`
  - Response:
  ```json
  {
    "status": "ok|error",
    "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9"
  }
  ```

### GET /task/:uuid
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










