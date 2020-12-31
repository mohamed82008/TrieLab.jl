abstract type AbstractTrieKey end

struct TrieKey{E <: Tuple} <: AbstractTrieKey
    elements::E
    TrieKey(k::Tuple) = new{typeof(k)}(k)
    TrieKey(ks...) = TrieKey(ks)
end
Base.Tuple(k::TrieKey) = k.elements

Base.first(k::TrieKey) = first(Tuple(k))
Base.tail(k::TrieKey) = TrieKey(Base.tail(Tuple(k)))

struct StaticTrieKey{E} <: AbstractTrieKey
    StaticTrieKey(k::Tuple) = new{k}()
    StaticTrieKey(ks...) = StaticTrieKey(ks)
end
Base.Tuple(::StaticTrieKey{k}) where {k} = k

Base.first(::StaticTrieKey{k}) where {k} = first(k)
Base.tail(::StaticTrieKey{k}) where {k} = StaticTrieKey{Base.tail(k)}()

Base.size(k::AbstractTrieKey) = size(Tuple(k))
Base.length(k::AbstractTrieKey) = length(Tuple(k))
Base.eltype(k::AbstractTrieKey) = eltype(Tuple(k))
function Base.iterate(k::AbstractTrieKey, i::Integer=1)
    i <= length(k) && return Tuple(k)[i]
    return nothing
end

struct TrieMultiKey{K}
    keys::K
end

import JSON
Base.show(io::IO, key::TrieMultiKey) = print(io, JSON.json(key, 2))
Base.println(key::TrieMultiKey) = println(JSON.json(key, 2))
Base.print(key::TrieMultiKey) = print(JSON.json(key, 2))

export TrieKey, StaticTrieKey, TrieMultiKey

# Missing functionality
# - subsume
# - turn to graph for visualisation
# - allow tuple of indices keys - change to cartesian indices
