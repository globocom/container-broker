# Container Broker

## Routes

### Nodes

#### List
  - `GET /nodes`

#### Add
  - `POST /nodes`
  - Parameters: `{ "hostname": "", "slots_execution_types": {"cpu": 2, "network": 10} }`

#### Update
  - `PATCH /nodes/:uuid`
  - Parameters: `{ "slots_execution_types": {"cpu": 2, "network": 10} }`

#### Remove
  - `DELETE /nodes/:uuid`
  - Parameters: `{ "slots_execution_types": {"cpu": 2, "network": 10} }`

### Tasks

#### Create
  - `POST /tasks`
  - Parameters: `{ "name": "", "image": "", "cmd": "", "storage_mount": "", "tags": {"slug": "slug3166h", "type": "video"} }`
  - Response:
  ```json
  {
    "status": "ok|error",
    "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9"
  }
  ```

#### Task Details
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

## Development

### Expose Docker HTTP API on MacOSX:
```shell
socat TCP-LISTEN:2376,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock
```


***REMOVED***
***REMOVED***
***REMOVED***
