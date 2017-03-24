# maybe in the future add not supported on this type instead of error
abstract type AbstractManifold end

struct Sphere <: AbstractManifold
    m::Int
    n::Int
end

 #TODO FIX!
dim(s::Sphere) = length(s) - 1

typicaldist(s::Sphere) = pi

inner(s::Sphere, X, U, V) = dot(U,V)

norm(s::Sphere, X, U) = norm(U)


function dist(s::Sphere, U, V)
    inner_prod = max(min(inner(s,nothing, U, V), 1), -1)
    return acos(inner_prod)
end

proj(s::Sphere, X, H) = H - inner(s,nothing, X, H) * X

function ehess2rhess(s::Sphere, X, egrad, ehess, U)
    return proj(s,X,ehess) - inner(s,nothing, X, egrad) * U
end

function exp(s::Sphere, X, U)
    norm_U = norm(s,nothing,U)
    if norm_U > 1e-3
        return X * cos(norm_U) + U * sin(norm_U) / norm_U
    else
        return retr(s,U)
    end
end

retr(s::Sphere, X, U) = _normalize(s, X + U)

function log(s::Sphere, X, Y)
    P = proj(s,X,Y-X)
    distance = dist(s,X,Y)
    if dist > 1e-6
        P *= distance / norm(s,nothing,P)
    end
    return P
end

rand(s::Sphere) = _normalize(randn(s.m,s.n))

function randvec(s::Sphere,X)
    H = randn(s.m, s.n)
    P = proj(s,X,H)
    return _normalize(P)
end

transp(s::Sphere, X, Y, U) = proj(s, Y, U)

pairmean(s::Sphere, X, Y) = _normalize(s, X + Y)

_normalize(s::Sphere, X) = X / norm(s,nothing, X)


# TODO SphereSubspaceComplementIntersection at the bottom of sphere.py
