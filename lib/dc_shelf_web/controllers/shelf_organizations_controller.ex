defmodule DcShelfWeb.ShelfOrganizationsController do
  use DcShelfWeb, :controller

  def create(conn, %{"order_id" => order_id, "driver_id" => driver_id}) do
    case Services.CreateOrganization.call(order_id: order_id, driver_id: driver_id) do
      {:ok, shelf_id} ->
        conn
        |> put_status(200)
        |> json(%{"shelf_id" => shelf_id})

      {_, _} ->
        conn
        |> put_status(400)
        |> json(%{"error" => "Error on shelf allocation"})
    end
  end
end
