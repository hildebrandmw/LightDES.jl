using DiscreteES
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

import DiscreteES: Simulation, callback, now

@testset "Testing Simple Simulation" begin
    function test_func(sim::Simulation)
        println("Hello")
        callback(sim, test_func, 1) 
    end

    # Çonstruct a simulation with a timeout of 10 time units.
    timeout = UInt(10)
    sim = Simulation(timeout) 
    # Add the test_func as a callback.
    callback(sim, test_func, 1)

    # Run the simulation
    run(sim)

    @test now(sim) == timeout
end
