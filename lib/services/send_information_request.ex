defmodule Services.SendInformationRequest do
  def call(shelf_key, status) do
    shelf_key
    |> get_shelf()
    |> prepare_body!(status)
    |> request_all_async()
  end

  defp request_all_async(body) do
    get_webhook_urls()
    |> Enum.map(fn webhook_url ->
      Exq.enqueue(Exq, "default", Workers.AsyncPost, [
        webhook_url[:url],
        body,
        webhook_url[:header]
      ])
    end)
  end

  defp prepare_body!({:ok, nil}, _) do
    raise "there is no shelf"
  end

  defp prepare_body!({:ok, shelf}, status) do
    shelf_map = Jason.decode!(shelf)

    %{
      "internalId" => shelf_map["order_id"],
      "externalId" => shelf_map["order_id"],
      "serviceType" => "dc_shelf",
      "status" => status
    }
    |> Jason.encode!()
  end

  defp prepare_body!({:error, error}, _) do
    raise error
  end

  def get_shelf(shelf_key) do
    case Redix.start_link(host: "127.0.0.1", port: 6379) do
      {:ok, conn} ->
        Redix.command(conn, ["GET", shelf_key])

      {:error, _} ->
        {:error, "Error on start redis link - Worker"}
    end
  end

  defp get_webhook_urls() do
    Application.fetch_env!(:dc_shelf, :webhook_urls)
  end
end
