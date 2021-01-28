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

function StaticDict(trie::Trie)
    keys, values = _dict(trie)
    return StaticDict(StaticTrieKey.(_static(keys)), _static(values))
end
function Base.Dict(trie::Trie)
    keys, values = _dict(trie)
    return Dict(TrieKey(k) => v for (k, v) in zip(keys, values))
end
@inline function _dict(trie, old_keys=(), old_values=(), header=())
    new_keys_values = map(collect(keys(trie.nodes))) do k
        if trie.nodes[k] isa Trie
            return _dict(trie.nodes[k], old_keys, old_values, (header..., k))
        else
            return (header..., k), trie.nodes[k]
        end
    end
    new_keys = map(kv -> kv[1], new_keys_values)
    new_values = map(kv -> kv[2], new_keys_values)
    return vcat(old_keys..., new_keys...), vcat(old_values..., new_values...)
end

export Trie, dummy

# Missing functionality
# - Dict to Trie
#      sort keys by length
#      find deps using subsume - single parent per node
# - Reshaping
#      shape function and reshape with a shape arg - shape defaults to size for arrays but can be anything
# - Remove an element - delete
# - Linearise
# - De-linearise
# - Merge
# - getindex with a bunch of keys
# - type specialise
# - explore https://github.com/andyferris/Dictionaries.jl
# - isempty
# - merge
