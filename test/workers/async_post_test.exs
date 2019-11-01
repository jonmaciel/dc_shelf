defmodule Workers.AsyncPostTest do
  use ExUnit.Case
  use ExVCR.Mock

  setup do
    ExVCR.Config.cassette_library_dir("test/fixture/vcr_cassettes")
  end

  test "Send async" do
    use_cassette "worker_post" do
      body =
        %{
          "internalId" => "1",
          "externalId" => "1",
          "serviceType" => "dc_shelf",
          "status" => "delivered"
        }
        |> Jason.encode!()

      assert {:ok} ==
               Workers.AsyncPost.perform(
                 "https://webhook.site/a8024363-a668-400c-a6ff-8836195edf56",
                 body,
                 "aaa"
               )
    end
  end
end
