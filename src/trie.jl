##################
# Trie #
##################

struct Trie{N}
    # Can be any nested (key => value) mapping, e.g. nested dict, static dict, named tuples, tuples, arrays or a combination
    nodes::N
end
Trie() = Trie(Dict{Any,Any}())
function Base.keys(t::Trie)
    return TrieMultiKey(StaticDict(k => t isa Trie ? keys(t) : nothing for (k, t) in t.nodes))
end

function Base.getindex(trie::Trie, key::TrieMultiKey)
    return Trie(
        StaticDict(
            map(keys(key.keys)) do k1
                k2 = key.keys[k1]
                k1 => (k2 === nothing ? trie.nodes[k1] : trie.nodes[k1][k2])
            end
        )
    )
end

Base.getindex(trie::Trie, key) = trie[TrieKey(key)]
function Base.getindex(trie::Trie, key::AbstractTrieKey)
    temp = get(trie.nodes, first(key), missing)
    (temp === missing || length(key) == 1) && return temp
    return temp[Base.tail(key)]
end

Base.setindex!(trie::Trie, value, key) = trie[TrieKey(key)] = value
function Base.setindex!(trie::Trie, value, key::AbstractTrieKey)
    if length(key) == 1
        setindex!(trie.nodes, value, first(key))
    else
        _trie = get!(trie.nodes, first(key), Trie{Any}())
        setindex!(_trie, value, Base.tail(key))
    end
    return value
end

function dummy(::Type{Trie})
    return Trie(
        Dict{Any,Any}(
            :x => rand(),
            :y => Trie(
                Dict{Any, Any}(
                    1 => rand(),
                    2 => rand(),
                )
            ),
        )
    )
end

import JSON
Base.show(io::IO, trie::Trie) = print(io, JSON.json(trie, 2))
Base.println(trie::Trie) = println(JSON.json(trie, 2))
Base.print(trie::Trie) = print(JSON.json(trie, 2))

function Base.Dict(t::Trie)
    keys = []
    values = []
    return TrieMultiKey(StaticDict(k => t isa Trie ? Dict(t) :  for (k, t) in t.nodes))
end

export Trie, dummy

# Missing functionality
# - Remove an element
# - Linearise
# - De-linearise
#      sort keys by length
#      find deps using subsume - single parent per node
#      shape function and reshape with a shape arg - shape defaults to size for arrays but can be anything
# - Merge
# - getindex with a bunch of keys
# - type specialise
# - explore https://github.com/andyferris/Dictionaries.jl
# - isempty
# - delete
# - merge
