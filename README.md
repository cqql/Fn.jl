# Anonymous Parameter Functions for Julia

My entry to the [long list](https://github.com/JuliaLang/julia/issues/5571) of attempts to
make the underscore useful in Julia. And all of them are more advanced than this one but
anyway, here you go.

---

Fn.jl exports `@fn` to bring Clojure's [shortform anonymous
functions](https://clojure.org/guides/learn/functions#_anonymous_function_syntax) to
Julia. Now you don't need to name the arguments of throwaway functions anymore and
function piping with extra arguments will look a bit nicer.

```julia
using Fn

# Finding pairs of consecutive number indices without @fn
pairs = sortperm(x) |> p -> zip(p[1:end-1], p[2:end]) |> collect

# With @fn
pairs = sortperm(x) |> @fn(zip(_[1:end-1], _[2:end])) |> collect
```

Within `@fn` you can use `_` as a placeholder variable and the macro will create an
anonymous function with a single parameter in its place without you having to name it
explicitly and writing the name twice, once to declare it, once to define it.

```julia
load_vectors() |> @fn(cat(_; dims=3)) |> use_them
```

If you need more than one argument, you can number the placeholders.

```julia
@fn(_2 .* (1:_1))(3, 2) # => 2:2:6
```
