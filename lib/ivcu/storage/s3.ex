defmodule IVCU.Storage.S3 do
  @moduledoc """
  Provides a helper to genenrate a [storage](`IVCU.Storage`) that
  saves all the files to S3.

  ## Usage

  First you need to define a configurable module for your storage.

      defmodule MyApp.S3Storage do
        use IVCU.Storage.S3, otp_app: :my_app
      end

  Then you need to proceed to configuration part.

      config :my_app, MyApp.S3Storage,
        access_key_id: "<access_key_id>",
        secret_access_key: "<secret_access_key>",
        bucket: "my-bucket",
        region: "eu-central-1",
        # Optional:
        host: "amazon.com",
        scheme: "https://"

  Now you can use your storage module in your
  [definition](`IVCU.Definition`).
  """

  @doc false
  defmacro __using__(opts) do
    otp_app = Keyword.get(opts, :otp_app) || raise ":otp_app key was expected"

    config =
      Application.get_env(otp_app, __CALLER__.module) ||
        raise "no configuration provided for #{otp_app}, #{__CALLER__.module}"

    bucket =
      Keyword.get(config, :bucket) ||
        raise "expected key :bucket in #{otp_app}, #{__CALLER__.module} " <>
                "configuration"

    region =
      Keyword.get(config, :region) ||
        raise "expected key :region in #{otp_app}, #{__CALLER__.module} " <>
                "configuration"

    access_key_id =
      Keyword.get(config, :access_key_id) ||
        raise "expected key :access_key_id in #{otp_app}, " <>
                "#{__CALLER__.module} configuration"

    secret_access_key =
      Keyword.get(config, :secret_access_key) ||
        raise "expected key :secret_access_key in #{otp_app}, " <>
                "#{__CALLER__.module} configuration"

    host = Keyword.get(config, :host, "s3.amazonaws.com")
    scheme = Keyword.get(config, :scheme, "https://")

    config =
      Macro.escape(%{
        bucket: bucket,
        region: region,
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        host: host,
        scheme: scheme
      })

    quote do
      @behaviour IVCU.Storage

      @impl IVCU.Storage
      def put(file) do
        unquote(__MODULE__).put(unquote(config), file)
      end

      @impl IVCU.Storage
      def delete(file) do
        unquote(__MODULE__).delete(unquote(config), file)
      end

      @impl IVCU.Storage
      def url(file) do
        unquote(__MODULE__).url(unquote(config), file)
      end
    end
  end

  @doc false
  def put(config, file) do
    with {:ok, _} <- do_put(config, file) do
      :ok
    end
  end

  defp do_put(config, %{filename: filename, content: nil, path: src_path})
       when is_binary(filename) and is_binary(src_path) do
    %{bucket: bucket} = config

    src_path
    |> ExAws.S3.Upload.stream_file()
    |> ExAws.S3.upload(bucket, filename)
    |> aws_request(config)
  end

  defp do_put(config, %{filename: filename, content: content, path: nil})
       when is_binary(filename) and is_binary(content) do
    %{bucket: bucket} = config

    bucket
    |> ExAws.S3.put_object(filename, content)
    |> aws_request(config)
  end

  @doc false
  def delete(config, file) do
    with {:ok, _} <- do_delete(config, file) do
      :ok
    end
  end

  defp do_delete(config, %{filename: filename}) when is_binary(filename) do
    %{bucket: bucket} = config

    bucket
    |> ExAws.S3.delete_object(filename)
    |> aws_request(config)
  end

  defp aws_request(operation, config) do
    %{
      region: region,
      access_key_id: access_key_id,
      secret_access_key: secret_access_key
    } = config

    ExAws.request(operation,
      region: region,
      access_key_id: access_key_id,
      secret_access_key: secret_access_key
    )
  end

  @aws_opts ~w[region access_key_id secret_access_key host scheme]a

  @doc false
  def url(config, %{filename: filename}) when is_binary(filename) do
    %{bucket: bucket} = config
    aws_config = Map.take(config, @aws_opts)

    {:ok, url} =
      ExAws.S3.presigned_url(aws_config, :get, bucket, filename,
        virtual_host: true
      )

    url
  end
end
