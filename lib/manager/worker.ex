defmodule Manager.Worker do
  @moduledoc """
  Module containing processes interaction functionality
  """
  alias Manager.Node
  require Logger

  @parrent_name :father
  @t 500

  @doc """
  Create supervisor process.

  ## Examples

      iex> Manager.Worker.start_supervisor
      true

  """
  @spec start_supervisor :: true
  def start_supervisor do
    pid = spawn(fn -> loop([]) end)
    Process.register(pid, @parrent_name)
  end

  @doc """
  Create n different processes.

  ## Examples

      iex> Manager.Worker.add_nodes(10)
      :ok

  """
  @spec add_nodes(non_neg_integer) :: :ok
  def add_nodes(n) do
    Enum.each(1..n, fn _n -> send(:father, {:add_node}) end)
  end

  @doc """
  Check the state of the supervisor process.

  ## Examples

      iex> Manager.Worker.get_state(:father)
      [
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.154.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.153.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.152.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.151.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.150.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.149.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.148.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.147.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.146.0>},
       %Manager.Node{leader: #PID<0.154.0>, pid: #PID<0.144.0>}
      ]

  """
  @spec get_state(atom) :: list(Node.t())
  def get_state(pid) do
    send(pid, {self(), :get_state})

    receive do
      msg when is_list(msg) -> msg
    end
  end

  @doc """
  Kill process by passing the PID of the process.

  ## Examples

      iex> Manager.Worker.kill_node(pid("0.154.0"))
      {#PID<0.154.0>, :kill_node}

  """
  @spec kill_node(pid) :: tuple
  def kill_node(pid) do
    send(:father, {pid, :kill_node})
  end

  @doc """
  Kill every nth process.

  ## Examples

      iex> Manager.Worker.kill_every_nth_node(2)
      :ok

  """
  @spec kill_every_nth_node(non_neg_integer) :: :ok
  def kill_every_nth_node(n) do
    all_pids =
      for node <- get_state() do
        node.pid
      end

    list_to_kill = Enum.drop_every(all_pids, n)

    Enum.each(list_to_kill, fn node -> send(:father, {node, :kill_node}) end)
  end

  @doc """
  Kill the Leader process.

  ## Examples

      iex> Manager.Worker.kill_leader_pid
      {#PID<0.151.0>, :kill_node}

  """
  @spec kill_leader_pid :: tuple
  def kill_leader_pid do
    leader = hd(get_state()).leader
    kill_node(leader)
  end

  @doc """
  Check in supervisor state if the processes are alive.

  ## Examples

      iex> Manager.Worker.processes_alive?(:father)
      [true, true, true. true]

  """
  @spec processes_alive?(pid) :: list(boolean)
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

      {from, :get_leader} ->
        send(from, hd(state).leader)
        loop(state)

      {from, :update_leader} ->
        new_state =
          for node <- state do
            %{node | leader: from}
          end

        loop(new_state)

      {pid, :kill_node} ->
        Process.exit(pid, :kill)
        Logger.info("#{inspect(pid)} was killed!")

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
        if List.first(get_state()).leader == from do
          Logger.info("Node: #{inspect(self())} says, that #{inspect(from)} is the leader now.")
          send(from, {self(), :ping})
        end

        mail_box(time)

      {_from, :finethanks} ->
        Process.sleep(time)
        mail_box(time)

      {from, :alive?} when from != self() ->
        list_of_pids =
          for node <- get_state() do
            node.pid
          end

        if Enum.max(list_of_pids) == self() do
          Enum.each(list_of_pids, fn pid -> send(pid, {:iamtheking, self()}) end)
          send(@parrent_name, {self(), :update_leader})
        else
          send(from, {self(), :finethanks})
        end

        mail_box(time)

      {from, :ping} when from != self() ->
        send(from, {self(), :pong})
        mail_box(time)

      {from, :pong} ->
        Process.send_after(from, {self(), :ping}, time)
        mail_box(time)
    after
      4 * time ->
        start_election(self(), get_state())
        mail_box(time)
    end
  end

  defp start_election(pid, state) do
    Logger.info("#{inspect(pid)} started election.")

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
