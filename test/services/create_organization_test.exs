defmodule Services.CreateOrganizationTest do
  use ExUnit.Case
  use ExVCR.Mock

  setup do
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
  end

  @tag :skip
  test "Call" do
    assert {:ok, "shelf_slot_blue"} ==
             Services.CreateOrganization.call(order_id: 1, driver_id: 1)
  end
end
