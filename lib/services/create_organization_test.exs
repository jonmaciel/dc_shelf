defmodule Services.CreateOrganizationTest do
  test "Call" do
    assert {:ok, 1} = Services.CancelBringgOrder.call(%{order_id: order_id, driver_id: driver_id})
  end
end
