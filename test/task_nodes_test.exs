defmodule TaskNodesTest do
  use ExUnit.Case
  alias Manager.Worker

  @t 2500

  setup do
    Worker.start_supervisor()

    on_exit(fn ->
      Process.exit(Process.whereis(:father), :kill)
    end)
  end

  test "add and kill processes" do
    assert Worker.add_nodes(10) == :ok

    assert :father |> Worker.get_state() |> Enum.count() == 10
    assert Worker.kill_every_nth_node(2) == :ok
    assert :father |> Worker.get_state() |> Enum.count() == 10 / 2
  end

  test "election" do
    assert Worker.add_nodes(10) == :ok
    leader_pid = hd(Worker.get_state(:father)).leader
    Process.sleep(@t)
    Worker.kill_leader_pid()
    Process.sleep(@t)
    assert hd(Worker.get_state(:father)).leader != leader_pid
    Process.sleep(@t)

    all_pids =
      for node <- Worker.get_state(:father) do
        node.pid
      end

    new_leader = hd(Worker.get_state(:father)).leader
    assert Enum.max(all_pids) == new_leader
  end
end
