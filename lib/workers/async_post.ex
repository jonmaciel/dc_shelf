defmodule Workers.AsyncPost do
  def perform(url, body, auth_header \\ nil) do
    res =
      HTTPotion.post(
        url,
        body: body,
        headers: get_headers(auth_header)
      )

    if res.status_code == 200 do
      {:ok}
    else
      raise "request fail"
    end
  end

  defp get_headers(nil) do
    ["content-type": "application/json"]
  end

  defp get_headers(auth_header) do
    [
      "content-type": "application/json",
      Authorization: auth_header
    ]
  end
end
