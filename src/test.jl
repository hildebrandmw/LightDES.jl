import FunctionWrappers
import FunctionWrappers.FunctionWrapper

mutable struct CBStruct
    f :: FVS
end

empty_function(x) = nothing

CBStruct() = CBStruct(empty_function)

function cbin(sim::Simulation, cb::CBStruct, i)
    register(sim, cb.f, i)
    return nothing
end


function test()
    sim = Simulation(10)

    cb1 = CBStruct()
    cb1.f = (x) -> cbin(x, cb1, 1)
    cb2 = CBStruct()
    cb2.f = (x) -> cbin(x, cb2, 2)

    register(sim, cb1.f, 0)
    register(sim, cb2.f, 0)

    return sim
end
