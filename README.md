# TaskNodes

## Overview
This project is about implementing an algorithm that allows selecting a
**Leader** from nodes.

## Clone this repository
```
git clone https://github.com/DanielaIvanova/nodes_example
cd nodes_example
```

## Usage example

 First, you have to start supervisor process that is responsible for storing the state for all nodes, that will be created.
 ``` elixir
 Manager.Worker.start_supervisor 
 ``` 

 Then, you can create as much `Nodes` as you wish. In this example will be created 10 processes.
``` elixir
Manager.Worker.add_nodes(10)
```

To check the current state:
``` elixir
Manager.Worker.get_state(:father)
```

To check, if the processes are alive:
``` elixir
Manager.Worker.processes_alive?(:father)
```

To kill process by passing the `pid` of the process:
``` elixir
Manager.Worker.kill_node(pid)
```

To kill every `n`th process:
``` elixir
Manager.Worker.kill_every_nth_node(n)
```

To kill the **Leader** process:
``` elixir
Manager.Worker.kill_leader_pid
```