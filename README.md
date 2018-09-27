# LightDES

[![Build Status](https://travis-ci.org/hildebrandmw/LightDES.jl.svg?branch=master)](https://travis-ci.org/hildebrandmw/LightDES.jl)
[![codecov.io](https://codecov.io/gh/hildebrandmw/LightDES.jl/graphs/badge.svg?branch=master)](https://codecov.io/gh/hildebrandmw/LightDES.jl)
[![Project Status: Abandoned – Initial development has started, but there has not yet been a stable, usable release; the project has been abandoned and the author(s) do not intend on continuing development.](https://www.repostatus.org/badges/latest/abandoned.svg)](https://www.repostatus.org/#abandoned)


Light weight discrete event simulator for use in applications where event handling functions
are short and event dispatch consumes a healthy chunk of time.

## Installation

Since this package is (and probably never will be) registered, install using the command
```julia
]add https://github.com/hildebrandmw/LightDES
```

## Usage
```julia
julia> using LightDES

# Create a data type to store a callback. Callback will be a closure reference the
# struct itself.
julia> mutable struct CountObject
           callback :: Callback
           count :: Int
       end

# Define a function that takes a CountObject, prints and increments the count, then
# schedules the callback inside the object again.
julia> function increment!(sim::Simulation, co::CountObject, time)
           println("Count: $(co.count)")
           co.count += 1
           schedule!(sim, co.callback, time)
       end
increment! (generic function with 1 method)

# Construct a CountObject. Use a dummy Callback() for initialization.
julia> co = CountObject(Callback(), 1);

# Construct a Simulation. Set the timeout for 20 time units.
julia> sim = Simulation(20);

# Create a callback, close over the CountOjbect just created.
julia> co.callback = Callback(x -> increment!(x, co, 2))
(::Callback) (generic function with 1 method)

# Simulation time starts at 0
julia> now(sim)
0

# Schedule the callback.
julia> schedule!(sim, co.callback, 2)

# Run the simulation.
julia> run(sim)
Count: 1
Count: 2
Count: 3
Count: 4
Count: 5
Count: 6
Count: 7
Count: 8
Count: 9
Count: 10

# Verify that simulation stopped at sim time 20.
julia> now(sim)
20
```
