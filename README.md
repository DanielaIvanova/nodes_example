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
Manager.Worker.add_node(10)
```

To check the current state:
``` elixir
Manager.Worker.get_state :father
```

You can also check, if processes are alive:
``` elixir
Manager.Worker.processes_alive? :father
```
