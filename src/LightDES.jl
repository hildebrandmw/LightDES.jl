module LightDES

import DataStructures
import FunctionWrappers.FunctionWrapper
import Dates: now

export Simulation, schedule!, Callback, now, StopSimulation

struct Event{T}
    fn :: FunctionWrapper{Nothing, Tuple{T}}
    time :: Int64
    priority :: Int64
end

Base.isless(a::Event, b::Event) = (a.time == b.time) ? (a.priority < b.priority) : (a.time < b.time)

mutable struct Simulation
    time :: Int64
    # Priority queue of events to process.
    heap :: DataStructures.BinaryHeap{Event{Simulation},DataStructures.LessThan}
    # When to stop simulation
    timeout :: Int64

    # Inner Constructor
    function Simulation(timeout; starttime = 0)
        return new(
            starttime,
            DataStructures.binary_minheap(Event{Simulation}),
            timeout,
        )
    end
end

now(sim::Simulation) = sim.time

struct Callback <: Function
    fn :: FunctionWrapper{Nothing,Tuple{Simulation}}
end

const throw_err(args...) = throw(StopSimulation())
Callback() = Callback(throw_err)
(cb::Callback)(args...) = cb.fn(args...)
unwrap(cb::Callback) = cb.fn

# Overload Event creation
Event(cb::Callback, args...) = Event(unwrap(cb), args...)

"""
    schedule!(sim::Simulation, callback::Function, intime, [priority])

Schedule the `callback` for the current simulation time plus `intime`.
"""
function schedule!(sim :: Simulation, callback :: Function, intime, priority = 1)
    key = Event(callback, now(sim) + intime, priority)
    push!(sim.heap, key)
    return nothing
end

function step(sim::Simulation)
    key = pop!(sim.heap)
    sim.time = key.time
    key.fn(sim)
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
