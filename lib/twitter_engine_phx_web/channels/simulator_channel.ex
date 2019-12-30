  defmodule TwitterEnginePhxWeb.SimulatorChannel do
  use TwitterEnginePhxWeb, :channel

  def join("simulator:lobby", payload, socket) do
    #if authorized?(payload) do
      {:ok, socket}
    #else
    #  {:error, %{reason: "unauthorized"}}
    #end
  end

  def handle_in("getHashtagData", payload, socket) do
    hashtag = Map.fetch!(payload, "hashtag")
    hashtag = "#" <> hashtag
    simulation_server_pid = Application.get_env(TwitterEnginePhx, :simulationerverpid)
    Simulator.getHashtagTweets(simulation_server_pid, hashtag)
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("getUserData", payload, socket) do
    username = Map.fetch!(payload, "username")
    simulation_server_pid = Application.get_env(TwitterEnginePhx, :simulationerverpid)
    Simulator.getUserRetweets(simulation_server_pid, username)
    Simulator.getUserMentions(simulation_server_pid, username)
    {:reply, {:ok, payload}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (simulator:lobby).
  def handle_in("shout", payload, socket) do
#    IO.puts "REACHED SHOUT CHANNEL"
#    Simulator.start(payload)
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(payload) do
    true
  end
end
