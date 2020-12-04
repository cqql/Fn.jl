module Fn

using MacroTools: @capture, prewalk, postwalk

export @fn

const PLACEHOLDER_PATTERN = r"^_([1-9]?|[1-9][0-9]*)$"

"""
    @fn

Shorthand for defining anonymous functions. Use _ and _1, _2, ... as placeholders for
arguments.

    @fn(cat(_; dims=3))

    @fn(_2^_1)
"""
:@fn

macro fn(expr)
    # Resolve everything in the caller's scope. This is fine because all symbols we
    # introduce are gensyms and locally bound to function arguments anyway.
    esc(fn(expr))
end

struct RecursionBarrier
    expr
end

function fn(expr)
    # Collect placeholders
    placeholders = Set{Symbol}()
    analyzed_expr = prewalk(expr) do ex
        if @capture(ex, @fn _)
            # Do not recurse into nested @fn calls
            return RecursionBarrier(ex)
        end

        if ex isa Symbol && (ex == :_ || occursin(PLACEHOLDER_PATTERN, string(ex)))
            push!(placeholders, ex)
        end

        ex
    end

    if length(placeholders) == 0
        args = []
        replacements = Dict{Symbol, Symbol}()
    elseif :_ in placeholders
        if length(placeholders) > 1
            names = join(placeholders, ", ", " and ")
            error("You cannot mix _ and _n in @fn, found $names")
        end

        args = [gensym("arg")]
        replacements = Dict(:_ => args[1])
    else
        numbers = map(collect(placeholders)) do p; parse(Int, string(p)[2:end]) end
        a, b = extrema(numbers)
        args = map(a:b) do i gensym("arg$i") end
        replacements = Dict(map(enumerate(args)) do (i, arg); (Symbol("_$i"), arg) end)
    end

    with_args = postwalk(analyzed_expr) do ex
        if ex isa RecursionBarrier
            # Unpack nested @fn calls
            return ex.expr
        elseif ex isa Symbol && ex in keys(replacements)
            replacements[ex]
        else
            ex
        end
    end

    quote
        function ($(args...),)
            $(with_args)
        end
    end
end

end
