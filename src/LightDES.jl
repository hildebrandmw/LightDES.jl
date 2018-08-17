module LightDES

import DataStructures
import FunctionWrappers.FunctionWrapper
import Dates: now

export Simulation, schedule!, register!, now, StopSimulation

struct Event
    handle :: Int64
    time :: Int64
    priority :: Int64
end

function Base.isless(a::Event, b::Event) 
    ifelse(a.time == b.time, a.priority < b.priority, b.time < b.time)
end

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

now(sim::Simulation) = sim.time

"""
    register!(sim::Simulation, fn)::Int

Register `fn` in the list of callbacks in `sim` and return a handle which can
be used to schedule this function.

Argument `fn` must be convertable to type 
`FunctionWrapper{Nothing,Tuple{Simulation}}`.
"""
function register!(sim :: Simulation, fn)
    # Add the callback to the list of callbacks.
    push!(sim.callbacks, fn)
    return length(sim.callbacks)
end

"""
    schedule!(sim::Simulation, handle, intime, [priority])

Schedule the callback referenced by `handle` for the current simulation time
plus `intime`.
"""
function schedule!(sim :: Simulation, handle, intime, priority = 1)
    key = Event(handle, now(sim) + intime, priority)
    push!(sim.heap, key)

    return nothing
end

function step(sim::Simulation)
    key = pop!(sim.heap)
    sim.time = key.time
    sim.callbacks[key.handle](sim)

    return nothing
end

timedout(sim::Simulation) = sim.time >= sim.timeout
Base.isempty(sim::Simulation) = isempty(sim.heap)

struct StopSimulation <: Exception end

"""
    run(sim::Simulation, [until])

Run `sim` until the specified simulation time. If no time is given, `sim` will
run until its default timeout.
"""
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
