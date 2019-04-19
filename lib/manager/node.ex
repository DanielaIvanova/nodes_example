defmodule Manager.Node do
  @moduledoc """
  Module defining the Node structure.
  """
  alias __MODULE__

  defstruct [:pid, :leader]

  @typedoc "Node structure"
  @type t :: %Node{
          pid: pid,
          leader: pid | nil
        }

  @doc """
  Create Node structure.

  ## Examples

      iex> pid("0.111.0") |> Manager.Node.create
      %Manager.Node{leader: nil, pid: #PID<0.111.0>}

  """
  @spec create(pid) :: Node.t()
  def create(pid), do: %Node{pid: pid}

  @spec create(pid, pid) :: Manager.Node.t()
  def create(pid, leader), do: %Node{pid: pid, leader: leader}
end
