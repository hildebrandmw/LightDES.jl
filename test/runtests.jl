using LightDES
using BenchmarkTools
using Test

mutable struct CBTest
    callback :: Callback
    count :: Int
end
CBTest() = CBTest(Callback(), 0)

function increment!(sim::Simulation, cb::CBTest, i)
    cb.count += 1
    schedule!(sim, cb.callback, i)
    return nothing
end

stopsim(sim::Simulation, cb) = throw(StopSimulation())
genericerr(sim::Simulation, cb) = throw(Exception())

function makesim(timeout)
    sim = Simulation(timeout)

    # Create an instance of an object, then close over it to create the incrementibng
    # Function
    cb1 = CBTest()
    cb1.callback = Callback(x -> increment!(x, cb1, 1))

    cb2 = CBTest()
    cb2.callback = Callback(x -> increment!(x, cb2, 10))

    schedule!(sim, cb1.callback, 1)
    schedule!(sim, cb2.callback, 1)

    return sim, cb1, cb2
end

@testset "Testing Simulation" begin
    sim, cb1, cb2  = makesim(1000)

    run(sim)

    @test sim.time == 1000
    @test cb1.count == 1000
    @test cb2.count == 100

    bm = @benchmark run(sim) setup=((sim, i, j) = makesim(10000)) evals=1
    display(bm)
    println()
end

@testset "Testing Stop Simulation" begin
    sim = Simulation(10)
    cb = CBTest()
    cb.callback = Callback(x -> stopsim(x, cb))

    schedule!(sim, cb.callback, 5)
    @test run(sim) == nothing
    @test sim.time == 5
    @test isempty(sim)

    cb.callback = Callback(x -> genericerr(x, cb))
    schedule!(sim, cb.callback, 3)
    @test_throws Exception run(sim)
end
