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

  alias ExAws.S3

  @doc false
  defmacro __using__(opts) do
    otp_app = Keyword.get(opts, :otp_app) || raise ":otp_app key was expected"
    module = __CALLER__.module

    quote do
      @behaviour IVCU.Storage

      @impl IVCU.Storage
      def put(file) do
        unquote(__MODULE__).put(unquote(otp_app), unquote(module), file)
      end

      @impl IVCU.Storage
      def delete(file) do
        unquote(__MODULE__).delete(unquote(otp_app), unquote(module), file)
      end

      @impl IVCU.Storage
      def url(file) do
        unquote(__MODULE__).url(unquote(otp_app), unquote(module), file)
      end
    end
  end

  @doc false
  def put(otp_app, module, file) do
    config = fetch_config!(otp_app, module)

    with {:ok, _} <- do_put(config, file) do
      :ok
    end
  end

  defp do_put(config, %{filename: filename, content: nil, path: src_path})
       when is_binary(filename) and is_binary(src_path) do
    %{bucket: bucket} = config

    src_path
    |> S3.Upload.stream_file()
    |> S3.upload(bucket, filename)
    |> aws_request(config)
  end

  defp do_put(config, %{filename: filename, content: content, path: nil})
       when is_binary(filename) and is_binary(content) do
    %{bucket: bucket} = config

    bucket
    |> S3.put_object(filename, content)
    |> aws_request(config)
  end

  @doc false
  def delete(otp_app, module, file) do
    config = fetch_config!(otp_app, module)

    with {:ok, _} <- do_delete(config, file) do
      :ok
    end
  end

  defp do_delete(config, %{filename: filename}) when is_binary(filename) do
    %{bucket: bucket} = config

    bucket
    |> S3.delete_object(filename)
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
  def url(otp_app, module, %{filename: filename}) when is_binary(filename) do
    config = fetch_config!(otp_app, module)
    %{bucket: bucket} = config
    aws_config = Map.take(config, @aws_opts)

    {:ok, url} =
      S3.presigned_url(aws_config, :get, bucket, filename,
        virtual_host: config[:virtual_host]
      )

    url
  end

  @aws_config ~w[bucket region access_key_id secret_access_key virtual_host host scheme]a

  defp fetch_config!(otp_app, module) do
    config =
      Application.get_env(otp_app, module) ||
        raise "no configuration provided for #{otp_app}, #{module}"

    case Enum.into(config, %{}) do
      %{
        bucket: _,
        region: _,
        access_key_id: _,
        secret_access_key: _
      } = config ->
        config
        |> Map.take(@aws_config)
        |> Map.update(:host, "s3.amazonaws.com", & &1)
        |> Map.update(:scheme, "https://", & &1)
        |> Map.update(:virtual_host, true, & &1)

      _ ->
        raise "required keys are :bucket, :region, :access_key_id," <>
                " :secret_access_key"
    end
  end
end
