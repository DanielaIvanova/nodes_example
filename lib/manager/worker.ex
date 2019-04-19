defmodule Manager.Worker do
  alias Manager.Node
  @parrent_name :father
  @t 500

  @spec start_supervisor() :: true
  def start_supervisor do
    pid = spawn(fn -> loop([]) end)
    Process.register(pid, @parrent_name)
  end

  @spec add_node(non_neg_integer()) :: :ok
  def add_node(n) do
    Enum.each(1..n, fn _n -> send(:father, {:add_node}) end)
  end

  @spec get_state(atom()) :: list(Node.t())
  def get_state(pid) do
    send(pid, {self(), :get_state})

    receive do
      msg -> msg
    end
  end

  @spec kill_node(pid()) :: any()
  def kill_node(pid) do
    send(:father, {pid, :kill_node})
  end

  @spec kill_every_nth_node(non_neg_integer()) :: :ok
  def kill_every_nth_node(n) do
    list =
      for node <- get_state() do
        node.pid
      end

    list = Enum.drop_every(list, n)

    Enum.each(list, fn node -> send(:father, {node, :kill_node}) end)
  end

  @spec kill_leader_pid() :: any()
  def kill_leader_pid() do
    leader = hd(get_state()).leader
    kill_node(leader)
  end

  @spec processes_alive?(pid) :: list(boolean())
  def processes_alive?(pid) do
    send(pid, {self(), :get_state})

    receive do
      msg ->
        for node <- msg do
          Process.alive?(node.pid)
        end
    end
  end

  defp loop(state) do
    receive do
      {:add_node} when state != [] ->
        pid = spawn(__MODULE__, :mail_box, [@t])
        start_election(pid, [Node.create(pid)] ++ state)

        loop([Node.create(pid)] ++ state)

      {:add_node} ->
        pid = spawn(__MODULE__, :mail_box, [@t])

        loop([Node.create(pid, pid)])

      {from, :get_state} ->
        send(from, state)
        loop(state)

      {from, :update_leader} ->
        new_state =
          for node <- state do
            %{node | leader: from}
          end

        loop(new_state)

      {pid, :kill_node} ->
        Process.exit(pid, :kill)
        IO.puts("The process: #{inspect(pid)} is dead!")

        new_state =
          Enum.reduce(state, [], fn node, acc ->
            if Process.alive?(node.pid) do
              [node | acc]
            else
              acc
            end
          end)

        loop(new_state)
    end
  end

  def mail_box(time) do
    receive do
      {from, :iamtheking} ->
        if List.first(get_state()).leader < from do
          send(from, {self(), :ping})
        end

        mail_box(time)

      {_from, :finethanks} ->
        Process.sleep(time)
        mail_box(time)

      {from, :alive} when from != self() ->
        send(from, {self(), :finethanks})
        state = get_state()
        start_election(self(), state)
        mail_box(time)

      {from, :ping} when from != self() ->
        send(from, {self(), :pong})
        mail_box(time)

      {from, :pong} ->
        send(from, {self(), :ping})
        mail_box(time)
    after
      4 * time ->
        start_election(self(), get_state())
        mail_box(time)
    end
  end

  defp start_election(pid, state) do
    list_of_pids =
      for node <- state do
        node.pid
      end

    if Enum.max(list_of_pids) == pid do
      Enum.each(state, fn node ->
        send(node.pid, {pid, :iamtheking})
      end)

      send(@parrent_name, {pid, :update_leader})
    else
      Enum.each(state, fn node ->
        if node.pid > pid do
          send(node.pid, {pid, :alive?})
        end
      end)
    end
  end

  defp get_state() do
    send(@parrent_name, {self(), :get_state})

    receive do
      state when is_list(state) -> state
    end
  end
end
