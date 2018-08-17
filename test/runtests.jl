using DES
using BenchmarkTools
using Test

mutable struct CBTest
    callback :: Int
    count :: Int
end
CBTest() = CBTest(0, 0)

function increment!(sim::Simulation, cb::CBTest, i)
    cb.count += 1
    schedule!(sim, cb.callback, i)
    return nothing
end

stopsim(sim::Simulation, cb) = throw(StopSimulation())
genericerr(sim::Simulation, cb) = throw(Exception())

function makesim(timeout)
    sim = Simulation(timeout)

    cb1 = CBTest()
    cb1.callback = register!(sim, Callback((sim) -> increment!(sim, cb1, 1)))

    cb2 = CBTest()
    cb2.callback = register!(sim, Callback((sim) -> increment!(sim, cb2, 10)))

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
    cb.callback = register!(sim, Callback(sim -> stopsim(sim, cb)))

    schedule!(sim, cb.callback, 5)
    @test run(sim) == nothing
    @test sim.time == 5
    @test isempty(sim)

    cb.callback = register!(sim, Callback(sim -> genericerr(sim, cb)))
    schedule!(sim, cb.callback, 3)
    @test_throws Exception run(sim)
end
