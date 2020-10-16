# Container Broker

## Key Features
- Run any Docker based task
- A Node only needs Docker HTTP API
- Separate Tasks by execution type
- Easily get Task logs
- Automatically retry jobs
- Enqueue tasks if no slots available
- Distribute load between Nodes
- If a node dies, tasks are automatically moved to another healthy Node (Failover)
- Support external volume mounts

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'container-broker'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install container-broker

## Usage

### Routes

#### Nodes

##### List
  - `GET /nodes`

##### Add
  - `POST /nodes`
  - Parameters: `{ "hostname": "", "slots_execution_types": {"cpu": 2, "network": 10} }`

##### Update
  - `PATCH /nodes/:uuid`
  - Parameters: `{ "slots_execution_types": {"cpu": 2, "network": 10} }`

##### Remove
  - `DELETE /nodes/:uuid`
  - Parameters: `{ "slots_execution_types": {"cpu": 2, "network": 10} }`

#### Tasks

##### Create
  - `POST /tasks`
  - Parameters: `{ "name": "", "image": "", "cmd": "", "storage_mounts": "{}", "tags": {"type": "video"} }`
  - Response:
  ```json
  {
    "status": "ok|error",
    "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9"
  }
  ```

##### Task Details
  - Show information about some job
  - Parameters (query string): `id`
  - Response:
  ```json
  {
    "uuid": "2d272b5c-953c-44e9-ad15-6c31187903c9",
    "status": "waiting|running|completed|error"
  }
  ```

#### GET /status
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Expose Docker HTTP API on MacOSX:
```shell
socat TCP-LISTEN:2376,reuseaddr,fork UNIX-CONNECT:/var/run/docker.sock
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/globocom/container-broker.
