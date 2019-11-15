defmodule Services.CreateOrganization do
  def call(order_id: order_id, driver_id: driver_id) do
    case Redix.start_link(host: "127.0.0.1", port: 6379) do
      {:ok, conn} ->
        get_shelf_with_same_driver(driver_id, conn)
        |> get_free_shelf(conn)
        |> alocate_order(%{order_id: order_id, driver_id: driver_id}, conn)

      {:error, _} ->
        raise "Redis connection error"
    end
  end

  defp get_shelf_with_same_driver(driver_id, conn) do
    case Application.fetch_env!(:dc_shelf, :shelf_slots)
         |> Map.keys()
         |> Enum.reduce_while(0, &slot_same_driver?(&1, &2, driver_id, conn)) do
      "error" ->
        {:error, "there is no shelf slot with this driver"}

      shelf_key ->
        {:ok, shelf_key}
    end
  end

  defp slot_same_driver?(shelf_key, _, driver_id, conn) do
    case Redix.command(conn, ["GET", shelf_key]) do
      {:ok, nil} ->
        {:cont, "error"}

      {:ok, shelf} ->
        if shelf
           |> Jason.decode!()
           |> slot_same_driver?(driver_id) do
          {:halt, shelf_key}
        else
          {:cont, "error"}
        end
    end
  end

  defp slot_same_driver?(shelf, driver_id) do
    Enum.reduce_while(shelf, 0, fn slot, _ ->
      if slot["driver_id"] == driver_id, do: {:halt, true}, else: {:cont, false}
    end)
  end

  # when the slot has already binged by "get_shelf_with_same_driver"
  defp get_free_shelf({:ok, shelf_key}, _), do: {:ok, shelf_key}

  defp get_free_shelf({:error, _}, conn) do
    case Application.fetch_env!(:dc_shelf, :shelf_slots)
         |> Map.keys()
         |> Enum.reduce_while(0, &shelf_slot_free?(&1, &2, conn)) do
      "error" ->
        {:error, "error"}

      shelf_key ->
        {:ok, shelf_key}
    end
  end

  defp shelf_slot_free?(shelf_key, _, conn) do
    case Redix.command(conn, ["GET", shelf_key]) do
      {:ok, nil} -> {:halt, shelf_key}
      {:ok, _} -> {:cont, "error"}
    end
  end

  defp alocate_order({:ok, shelf_key}, params, conn) do
    # order waiting to be collected

    case get_pin(shelf_key)[:shopper_pin]
         |> Circuits.GPIO.open(:output) do
      {:ok, gpio} ->
        Circuits.GPIO.write(gpio, 0)
        Circuits.GPIO.close(gpio)
    end

    update_shelf(shelf_key, params, conn)

    {:ok, shelf_key}
  end

  defp alocate_order({:error, _}, _, _), do: {:error, "there is no free shelf"}

  defp update_shelf(shelf_key, params, conn) do
    case Redix.command(conn, ["GET", shelf_key]) do
      {:ok, nil} ->
        Redix.command(conn, ["SET", shelf_key, Jason.encode!([params])])

        Exq.enqueue_in(Exq, "default", 1, Workers.CheckShelfSlot, [shelf_key, false])

      {:ok, shelf} ->
        decoded_shelf = Jason.decode!(shelf)

        unless order_on_shelf?(decoded_shelf, params[:order_id]) do
          Redix.command(conn, ["SET", shelf_key, Jason.encode!(decoded_shelf ++ [params])])
        end
    end
  end

  defp order_on_shelf?(shelf, order_id) do
    Enum.reduce_while(shelf, 0, fn slot, _ ->
      if slot["order_id"] == order_id, do: {:halt, true}, else: {:cont, false}
    end)
  end

  defp get_pin(shelf_key), do: Application.fetch_env!(:dc_shelf, :shelf_slots)[shelf_key]
end
