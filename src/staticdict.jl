# Normal strings can't be type parameters hence this
struct StaticString{N}
    chars::NTuple{N, Char}
end
StaticString(s::AbstractString) = StaticString((s...,))
Base.string(s::StaticString) = *(s.chars...,)

_static(s::Vector) = _static(Tuple(s))
_static(s::Tuple) = _static.(s)
_static(s::AbstractString) = StaticString(s)
_static(s::Any) = s

Base.show(io::IO, s::StaticString) = show(io, string(s))
Base.println(s::StaticString) = println(string(s))
Base.print(s::StaticString) = print(string(s))

struct StaticSymbol{N, C<:NTuple{N, Any}}
    elements::C
end
StaticSymbol(s::Symbol) = StaticSymbol((String(s)...,))
Base.Symbol(s::StaticSymbol) = Symbol(s.elements...,)

_static(s::Symbol) = StaticSymbol(s)

Base.show(io::IO, s::StaticSymbol) = show(io, Symbol(s))
Base.println(s::StaticSymbol) = println(Symbol(s))
Base.print(s::StaticSymbol) = print(Symbol(s))

# Keys are type parameters
struct StaticDict{K, V} <: AbstractDict{K,V}
    values::V
end
StaticDict(ps::Base.Generator) = StaticDict(ps...)
StaticDict(ps::Pair...) = StaticDict(ps)
function StaticDict(ps::Tuple{Vararg{Pair}})
    keys = _static(ntuple(i -> ps[i].first, Val(length(ps))))
    values = ntuple(i -> ps[i].second, Val(length(ps)))
    return StaticDict{keys, typeof(values)}(values)
end
StaticDict(keys::Tuple, values::Tuple) = StaticDict{_static(keys), typeof(values)}(values)

Base.Dict(d::StaticDict) = Dict(k => v for (k, v) in d)
@generated function Base.getindex(d::StaticDict{keys}, k) where {keys}
    expr = Expr(:block)
    for (i, _k) in enumerate(QuoteNode.(keys))
        push!(expr.args, quote
            k === $_k && return d.values[$i]
        end)
    end
    push!(expr.args, :(throw(ArgumentError("Key $k not found."))))
    return expr
end

Base.keys(::StaticDict{keys}) where {keys} = keys
Base.values(d::StaticDict) = d.values

Base.length(d::StaticDict) = length(d.values)
Base.eltype(d::StaticDict) = eltype(d.values)
function Base.iterate(d::StaticDict, state=iterate(keys(d)))
    state !== nothing && return (state[1] => d[state[1]]), iterate(keys(d), state[2])
    return nothing
end

Base.show(io::IO, d::StaticDict) = show(io, Dict(d))

export StaticDict
