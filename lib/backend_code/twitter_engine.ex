defmodule TwitterEngine do
  use GenServer

  # CLIENT SIDE
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def chooseProcessor(server) do
    GenServer.call(server, {:chooseProcessor})
  end

  # SERVER SIDE
  def init(init_arg) do
    processorCount = 100
    {:ok, db_pid} = DatabaseServer.start_link([])

    processerList =
      for i <- 1..processorCount do
        {:ok, pid} = TwitterProcessor.start_link(db_pid)
        pid
      end

    state = %{ :processors => processerList, :processorCount => processorCount, :lastProcessorUsed => 0 }
    {:ok, state}
  end

  def handle_call({:chooseProcessor}, _from, state) do
    nextProcessorIndex = rem(Map.fetch!(state, :lastProcessorUsed) + 1, Map.fetch!(state, :processorCount))
    Map.replace!(state, :lastProcessorUsed, nextProcessorIndex)
    processerList = Map.fetch!(state, :processors)
    next_pid = Enum.at(processerList, nextProcessorIndex)
    {:reply, {:proceed, next_pid}, state}
  end
end