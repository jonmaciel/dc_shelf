defmodule Services.CreateOrganization do
  def call(%{order_id: order_id, driver_id: driver_id}) do
    get_free_shelf()
    |> alocate_order(%{order_id: order_id, driver_id: driver_id})
  end

  defp get_free_shelf do
    {:ok, 1}
  end

  defp alocate_order({:ok, shelf_id}, %{order_id: _order_id, driver_id: _driver_id}) do
    {:ok, shelf_id}
  end

  defp alocate_order({:error, _}, _) do
    {:error, "there is no free shelf"}
  end
end
