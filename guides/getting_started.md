# Getting Started

## Install

The package can be installed by adding `ivcu_s3_storage` to your list
of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ivcu_s3_storage, "~> 0.1.0"}
  ]
end
```

## Define a storage

```elixir
defmodule MyApp.S3Storage do
  use IVCU.Storage.S3, otp_app: :my_app
end
```

## Configuration

```elixir
config :my_app, MyApp.S3Storage,
  access_key_id: "<access_key_id>",
  secret_access_key: "<secret_access_key>",
  bucket: "my-bucket",
  region: "eu-central-1",
  # Optional:
  host: "amazon.com",
  scheme: "https://"
```

## Add the storage to your definition

```elixir
defmodule MyApp.Image do
  @behaviour IVCU.Definition

  # ...

  def storage, do: MyApp.S3Storage

  # ...
end
```
