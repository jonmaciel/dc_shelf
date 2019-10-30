defmodule Services.CreateOrganizationTest do
  use ExUnit.Case

  test "Call" do
    assert {:ok, 1} ==
             Services.CreateOrganization.call(order_id: 1, driver_id: 1)
  end
end
