module DES

import DataStructures
import FunctionWrappers
import FunctionWrappers.FunctionWrapper


# Much of this code is taken from BenLauwens "SimJulia" package:
# https://github.com/BenLauwens/SimJulia.jl
#
# I'm reimplementing some of it to be more type stable and to move away from
# the dependence on ResumableFunctions (which is also awesome, but again, I
# would like more type stability)

# Used to order events in a priority queue.
struct EventKey
    time        :: UInt64
    priority    :: UInt64
    id          :: UInt64
end

function Base.isless(a::EventKey, b::EventKey)
    return  (a.time < b.time) ||
            (a.time == b.time && a.priority < b.priority) ||
            (a.time == b.time && a.priority == b.priority && a.id < b.id)
end

mutable struct Simulation
    # Simulation time. Use a UInt64 to avoid floating point grossness.
    time :: UInt64
    # Priority queue of events to process.
    heap :: DataStructures.PriorityQueue{
        FunctionWrapper{Void,Tuple{Simulation}},
        EventKey,
        Base.ForwardOrdering
    }

    # When to stop simulation
    timeout :: UInt64

    # Inner Constructor
    function Simulation(timeout; starttime = 0)
        return new(
            starttime,
            DataStructures.PriorityQueue{
                FunctionWrapper{Void,Tuple{Simulation}},
                EventKey
            }(),
            timeout,
        )
    end
end

const FVS = FunctionWrapper{Void,Tuple{Simulation}}

now(sim::Simulation) = sim.time

function register(sim::Simulation, fn, intime, priority = 1, id = 1)
    key = EventKey(now(sim) + intime, priority, id)
    DataStructures.enqueue!(sim.heap, fn, key)
    return nothing
end

function step(sim::Simulation)
    # Peek to get both the funciton and the key.
    (fn, key) = DataStructures.peek(sim.heap)
    # Pop the item off the queue and update sim time.
    DataStructures.dequeue!(sim.heap)
    sim.time = key.time
    # Call the function.
    fn(sim)
    return nothing
end

timedout(sim::Simulation) = sim.time >= sim.timeout
Base.isempty(sim::Simulation) = isempty(sim.heap)

struct StopSimulation <: Exception end

function Base.run(sim::Simulation, until = sim.timeout)
    sim.timeout = until

    # Pull events from the heap until there are no more scheduled events
    # or until the simulation has reached its timeout value.
    #
    # Wrap this in a try-catch block to allow any task in the simulation to
    # throw a StopSimulation() and end simulation early.
    try
        while !isempty(sim) && !timedout(sim)
            step(sim)
        end
    catch err <: StopSimulation
        return nothing
    end

    return nothing
end

include("test.jl")

end # module
