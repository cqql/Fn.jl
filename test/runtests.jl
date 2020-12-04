using Fn
using MacroTools

using Test

@testset "Fn.jl" begin
    @testset "no _ creates 0-argument function" begin
        @test @capture(Fn.fn(:(exp(5 * √π))), function () exp(5 * √π) end)
    end

    @testset "_ creates single argument function" begin
        @test @capture(Fn.fn(:(5 + _)), function (x_) 5 + x_ end)
    end

    @testset "numbered underscores introduce multiple arguments" begin
        @test @capture(Fn.fn(:(sin(_1) * cos(_2))), function (x_, y_) sin(x_) * cos(y_) end)
    end

    @testset "numbered arguments are ordered by number, not by occurence" begin
        @test @capture(Fn.fn(:(sin(_2) * cos(_1))), function (x_, y_) sin(y_) * cos(x_) end)
    end

    @testset "missing numbers introduce unused extra arguments" begin
        expr = Fn.fn(:(sin(_4) * cos(_1)))
        @test @capture(expr, function (w_, x_, y_, z_) sin(z_) * cos(w_) end)
    end

    @testset "leading zeros are not accepted" begin
        # They would make everything more complicated
        expr = Fn.fn(:(sin(_01) * cos(_02)))
        @test @capture(expr, function () sin(x_) * cos(y_) end)
        # Putting _01 and _02 into the @capture expression confuses MacroTools
        @test x == :_01 && y == :_02
    end

    @testset "mixing _ and _n raises an error" begin
        @test_throws ErrorException Fn.fn(:(_ + _1))
    end

    @testset "@fn does not replace _ in nested @fn" begin
        fn = Fn.fn(:(map(@fn(_ + 3), _)))

        matched = @capture(fn, function (x_) map(@fn(y_ + 3), x_) end)
        @test matched
        @test y === :_
    end

    @testset "@fn escapes function body" begin
        h(x) = x^2
        f = @fn(h(_))
        @test f(5) == 25
    end
end
