defmodule Services.CreateOrganization do
  def call(order_id: order_id, driver_id: driver_id) do
    get_free_shelf()
    |> alocate_order(%{order_id: order_id, driver_id: driver_id})
  end

  defp get_free_shelf() do
    {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 6379)

    case Application.fetch_env!(:dc_shelf, :shelf_slots)
         |> Map.keys()
         |> Enum.reduce_while(0, fn shelf_key, _ ->
           case Redix.command(conn, ["GET", shelf_key]) do
             {:ok, nil} -> {:halt, shelf_key}
             {:ok, _} -> {:cont, "error"}
           end
         end) do
      "error" ->
        {:error, "error"}

      shelf_key ->
        {:ok, shelf_key}
    end
  end

  defp alocate_order({:ok, shelf_key}, params) do
    # order waiting to be collected

    case get_pin(shelf_key)[:shopper_pin]
         |> Circuits.GPIO.open(:output) do
      {:ok, gpio} ->
        Circuits.GPIO.write(gpio, 0)
        Circuits.GPIO.close(gpio)
    end

    case Redix.start_link(host: "127.0.0.1", port: 6379) do
      {:ok, conn} ->
        Redix.command(conn, ["SET", shelf_key, Jason.encode!(params)])
    end

    Exq.enqueue_in(Exq, "default", 1, Workers.CheckShelfSlot, [shelf_key, false])

    {:ok, shelf_key}
  end

  defp alocate_order({:error, _}, _) do
    {:error, "there is no free shelf"}
  end

  defp get_pin(shelf_key) do
    Application.fetch_env!(:dc_shelf, :shelf_slots)[shelf_key]
  end
end
