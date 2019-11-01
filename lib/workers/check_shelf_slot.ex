defmodule Workers.CheckShelfSlot do
  @doc """
  When a order has been taken to the shelf, the botton is pressed,
  so this job is schedulled to watch this bottonm (shelf slot).
  Once the botton is released, the order has been taken and this 
  orkers is not scheduled anymore.
  """
  def perform(shelf_key, is_on_shelf) do
    case get_pin(shelf_key)[:shelf_pin]
         |> Circuits.GPIO.open(:input) do
      {:ok, gpio} ->
        # check: if still pressed, so schedule again 
        (Circuits.GPIO.read(gpio) == 1)
        |> reschedule!(is_on_shelf, shelf_key)

        Circuits.GPIO.close(gpio)

      {:error, _} ->
        raise "Error on GPIO connection - Starting worker"
    end
  end

  defp get_pin(shelf_key) do
    Application.fetch_env!(:dc_shelf, :shelf_slots)[shelf_key]
  end

  # pressed?, is on sheld? 
  # wainting for  shopper
  defp reschedule!(false, false, shelf_key) do
    # reschedule to check if it stills waiting
    Exq.enqueue_in(Exq, "default", 2, Workers.CheckShelfSlot, [shelf_key, false])
  end

  # shopper bringg the order! thx shopper! It's heavy!
  defp reschedule!(true, false, shelf_key) do
    get_pin(shelf_key)[:shopper_pin]
    |> turn_off_pin!()

    get_pin(shelf_key)[:driver_pin]
    |> turn_on_pin!()

    # reschedule to check if delivery stil on shelf
    # it means: NEXT STEP!!!!
    Exq.enqueue_in(Exq, "default", 2, Workers.CheckShelfSlot, [shelf_key, true])
  end

  # buttom is pressed, and is on shelf
  defp reschedule!(true, true, shelf_key) do
    # delivery is on shelf
    # reschedule to check if it still on shelf
    Exq.enqueue_in(Exq, "default", 2, Workers.CheckShelfSlot, [shelf_key, true])
    # TODO: Send to hub  Ready to delivery
  end

  # buttom is not pressed, and is on shelf
  defp reschedule!(false, true, shelf_key) do
    # order has been taken
    # it means: Finished!!!!
    Services.SendInformationRequest.call(shelf_key, "delivered")

    get_pin(shelf_key)[:driver_pin]
    |> turn_off_pin!()

    case Redix.start_link(host: "127.0.0.1", port: 6379) do
      {:ok, conn} ->
        Redix.command(conn, ["DEL", shelf_key])

      {:error, _} ->
        raise "Error on start redis link - Worker"
    end

    # TODO: Send to hub  Ready to delivering
  end

  defp turn_off_pin!(pin) do
    case Circuits.GPIO.open(pin, :output) do
      {:ok, gpio} ->
        Circuits.GPIO.write(gpio, 1)
        Circuits.GPIO.close(gpio)

      {:error, _} ->
        raise "Error on gpio connection to pin ##{pin} - trying to turn off"
    end
  end

  defp turn_on_pin!(pin) do
    case Circuits.GPIO.open(pin, :output) do
      {:ok, gpio} ->
        Circuits.GPIO.write(gpio, 0)
        Circuits.GPIO.close(gpio)

      {:error, _} ->
        raise "Error on gpio connection to pin ##{pin} - trying to turn on"
    end
  end
end
