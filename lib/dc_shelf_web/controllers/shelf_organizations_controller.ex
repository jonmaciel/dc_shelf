defmodule DcShelfWeb.ShelfOrganizationsController do
  use DcShelfWeb, :controller

  def view(conn, %{"order_id" => order_id}) do
    case get_shelf_by_order(order_id) do
      {:ok, shelf_id} ->
        conn
        |> put_status(200)
        |> json(%{"shelf_id" => shelf_id})

      {:error, _} ->
        conn
        |> put_status(400)
        |> json(%{"error" => "There is no shelf"})
    end
  end

  def create(conn, %{"order_id" => order_id, "driver_id" => driver_id}) do
    case Services.CreateOrganization.call(%{order_id: order_id, driver_id: driver_id}) do
      {:ok, shelf_key} ->
        conn
        |> put_status(200)
        |> json(%{"shelf_key" => shelf_key})

      {_, _} ->
        conn
        |> put_status(400)
        |> json(%{"error" => "Error on shelf allocation"})
    end
  end

  defp get_shelf_by_order(query_order_id) do
    {:ok, conn} = Redix.start_link(host: "127.0.0.1", port: 6379)

    case Application.fetch_env!(:dc_shelf, :shelf_slots)
         |> Map.keys()
         |> Enum.reduce_while(0, fn shelf_key, _ ->
           case Redix.command(conn, ["GET", shelf_key]) do
             {:ok, nil} ->
               {:cont, "error"}

             {:ok, shelf} ->
               %{"order_id" => order_id} = Jason.decode!(shelf)

               if(order_id == query_order_id) do
                 {:halt, shelf_key}
               else
                 {:cont, "error"}
               end
           end
         end) do
      "error" ->
        {:error, "error"}

      shelf_key ->
        {:ok, shelf_key}
    end
  end
end
