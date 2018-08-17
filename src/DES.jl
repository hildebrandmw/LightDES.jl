module DES

import DataStructures
import FunctionWrappers.FunctionWrapper
import Dates: now

export Simulation, Callback, schedule!, register!, now, StopSimulation

struct UndefinedCallback <: Exception; end
err(x) = throw(UndefinedCallback())

struct Event
    handle    :: Int64
    time        :: Int64
    priority    :: Int64
end

# Base.isless(a::Event, b::Event) = (a.time < b.time) ||
#     (a.time == b.time && a.priority < b.priority) ||
#     (a.time == b.time && a.priority == b.priority && a.id < b.id)
Base.isless(a::Event, b::Event) =
    ifelse(
        isequal(a.time, b.time),
        isless(a.priority, b.priority),
        isless(a.time, b.time)
    )

mutable struct Simulation
    time :: Int64
    # Priority queue of events to process.
    callbacks :: Vector{FunctionWrapper{Nothing,Tuple{Simulation}}}
    heap :: DataStructures.BinaryHeap{Event,DataStructures.LessThan}
    # When to stop simulation
    timeout :: Int64

    # Inner Constructor
    function Simulation(timeout; starttime = 0)
        return new(
            starttime,
            Vector{FunctionWrapper{Nothing,Tuple{Simulation}}}(),
            DataStructures.binary_minheap(Event),
            timeout,
        )
    end
end

struct Callback
    f :: FunctionWrapper{Nothing,Tuple{Simulation}}
end
Callback() = Callback(err)
(cb::Callback)(sim::Simulation) = cb.f(sim)

now(sim::Simulation) = sim.time

function register!(sim :: Simulation, cb :: Callback)
    # Add the callback to the list of callbacks.
    push!(sim.callbacks, cb.f)
    return length(sim.callbacks)
end

function schedule!(sim :: Simulation, handle, intime, priority = 1)
    key = Event(handle, now(sim) + intime, priority)
    push!(sim.heap, key)

    return nothing
end

function step(sim::Simulation)
    # Peek to get both the funciton and the key.
    key = pop!(sim.heap)
    # Pop the item off the queue and update sim time.
    sim.time = key.time
    # Call the function.
    #key.callback(sim)
    sim.callbacks[key.handle](sim)

    return nothing
end

timedout(sim::Simulation) = sim.time >= sim.timeout
Base.isempty(sim::Simulation) = isempty(sim.heap)

struct StopSimulation <: Exception end

function Base.run(sim::Simulation, until = sim.timeout)
    sim.timeout = until

    try
        while !isempty(sim) && !timedout(sim)
            step(sim)
        end
    catch ex
        if isa(ex,  StopSimulation)
            return nothing
        else
            rethrow(ex)
        end
    end

    return nothing
end

end # module
