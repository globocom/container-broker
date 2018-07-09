# Container Broker

## Routes

### POST /handshake
  - Registro de um node no pool Globernetes
  - Parâmetros: `{ "hostname": "", "cores": 10, "memory": 4096 }`
  - Resposta:   `{ "status": "ok|error" }`

### POST /job
  - Cria de um container que executa um determinado comando dentro de uma imagem
  - Parâmetros: `{ "name": "", "image": "", "cmd": "" }`
  - Retorno:
  ```
  {
    "status": "ok|error",
    "id": "abc123xyz"
  }
  ```

### GET /job/:id
  - Exibe informações de um determinado job
  - Parâmetro (via query-string): `id`
  - Retorno:
  ```
  {
    "id": "abcxyz",
    "status": "waiting|running|completed|error"
  }
  ```

### GET /status
  - Exibe informações do pool
  - Retorno:
  ```
  {
    "nodes": [
      {
        "hostname": ""
        "cores": 10,
        "memory": 4096,
        "jobs": [
          {
            "id": "abc123"
            "status": "waiting|running|completed|error"
          }
        ]
      }
    ]
  }
  ```

## Deploy










