struct PositiveDefinite <: AbstractManifold
    n::Int
    k::Int
end

dim(s::PositiveDefinite) = s.k * 0.5 * s.n * (s.n + 1)

typicaldist(s::PositiveDefinite) = sqrt(s.k * 0.5 * s.n * (s.n + 1))

inner(s::PositiveDefinite, X, U, V) = full_tensor_dot(X\U, X\V)

Base.norm(s::PositiveDefinite, X, U) = norm(U)

# make sure the X, c, and c_inv are of positive definite type
# so that factorize and multilog work
function dist(s::PositiveDefinite, X, Y)
    c = cholfact(X)
    c_inv = inv(c)
    l = multilog(multiprod(multiprod(c_inv, Y), multitransp(c_inv)))
    return  norm(multiprod(multiprod(c, l), c_inv))
end

proj(s::PositiveDefinite, X, G) = multisym(G)

egrad2grad(s::PositiveDefinite, X, U) = multiprod(multiprod(S, multisym(U)), X)

function ehess2rhess(s::PositiveDefinite, X, egrad, ehess, U)
    return multiprod(multiprod(X, multisym(ehess)), X) + multisym(multiprod(multiprod(U, multisym(egrad)), X))
end

# make sure the X, c, and c_inv are of positive definite type
# so that factorize and multilog work
function Base.exp(s::PositiveDefinite, X, U)
    c = la.cholesky(X)
    c_inv = la.inv(c)
    e = multiexp(multiprod(multiprod(c_inv, U), multitransp(c_inv)))
    return multiprod(multiprod(c, e), multitransp(c))
end

retr(s::PositiveDefinite, X, G) = exp(X, G)

# make sure the X, c, and c_inv are of positive definite type
function Base.log(s::PositiveDefinite, X, Y)
    c = cholfact(X)
    c_inv = inv(c)
    l = multilog(multiprod(multiprod(c_inv, Y), multitransp(c_inv)))
    return multiprod(multiprod(c, l), multitransp(c))
end

# Maybe do type checking instead
function Base.rand(s::PositiveDefinite)
    d = ones(s.k, s.n, 1) + rand(s.k, s.n, 1)

    u = zeros(s.k, s.n, s.n)
    for i in 1:s.k
        u[i], r = qr(randn(s.n, s.n))
    end

    if s.k == 1
        return multiprod(u, d * multitransp(u))[1]
    else
        return multiprod(u, d * multitransp(u))
    end
end

function randvec(s::PositiveDefinite,X)
    if s.k == 1
        u = multisym(randn(s.n,s.n))
    else
        u = multisym(randn(s.k, s.n, s.n))
    end
    return u / norm(X, u)
end

transp(s::PositiveDefinite, X, Y, D) = D

pairmean(s::PositiveDefinite, X, Y) = @assert false "not implemented"






struct PSDFixedRank <: AbstractManifold
    n::Int
    k::Int
end

dim(s::PSDFixedRank) = s.k * s.n - s.k * (s.k - 1) / 2

typicaldist(s::PSDFixedRank) = 10 + s.k

inner(s::PSDFixedRank, X, U, V) = full_tensor_dot(X\U, X\V)

Base.norm(s::PSDFixedRank, X, U) = vecnorm(U)

dist(s::PSDFixedRank, X, Y) = @assert false "not implemented"

function proj(s::PSDFixedRank, X, G)
    YtY = dot(X, X')
    AS = dot(X', G) - dot(G', X)
    Omega = lyap(YtY, AS)
    return H - dot(X, Omega)
end

egrad2grad(s::PSDFixedRank, X, egrad) = egrad

ehess2rhess(s::PSDFixedRank, X, egrad, ehess, U) = proj(s, X, ehess)

# make sure the X, c, and c_inv are of positive definite type
# so that factorize and multilog work
function Base.exp(s::PSDFixedRank, X, U)
    warn("Exponential map for symmetric, fixed-rank. Manifold not implemented yet. Used retraction instead.")
    return retr(s, X, U)
end

retr(s::PSDFixedRank, X, G) = X + U

Base.log(s::PSDFixedRank, X, Y) = @assert false "not implemented"

Base.rand(s::PSDFixedRank) = randn(s.n, s.k)

function randvec(s::PSDFixedRank,X)
    H = rand()
    P = proj(s, X, H)
    return _normalize(s, P)
end

transp(s::PSDFixedRank, Y, Z, U) = proj(s, Z, U)

pairmean(s::PSDFixedRank, X, Y) = @assert false "not implemented"

__normalize(s::PSDFixedRank, Y) = Y / norm(s, nothing, Y)





# TODO maybe add *args and **kwargs to the initialization
struct PSDFixedRankComplex <: AbstractManifold
    n::Int
    k::Int
end

dim(s::PSDFixedRankComplex) = 2 * s.k * s.n - s.k * s.k

typicaldist(s::PSDFixedRankComplex) = 10 + s.k

inner(s::PSDFixedRankComplex, X, U, V) = full_tensor_dot(X\U, X\V)

Base.norm(s::PSDFixedRankComplex, Y, U) = sqrt(inner(s, Y, U, U))

function dist(s::PSDFixedRankComplex, U, V)
    S, A, D = svd(vecdot(conj(V'),U))
    E = U - dot(dot(S,V),D)
    return inner(s, nothing, E, E) / 2
end

function proj(s::PSDFixedRankComplex, X, G)
    YtY = dot(X, X')
    AS = dot(X', G) - dot(G', X)
    Omega = lyap(YtY, AS)
    return H - dot(X, Omega)
end

egrad2grad(s::PSDFixedRankComplex, X, egrad) = egrad

ehess2rhess(s::PSDFixedRankComplex, X, egrad, ehess, U) = proj(s, X, ehess)

# make sure the X, c, and c_inv are of positive definite type
# so that factorize and multilog work
function Base.exp(s::PSDFixedRankComplex, X, U)
    warn("Exponential map for symmetric, fixed-rank. Manifold not implemented yet. Used retraction instead.")
    return retr(s, X, U)
end

retr(s::PSDFixedRankComplex, X, G) = X + U

Base.log(s::PSDFixedRankComplex, X, Y) = @assert false "not implemented"

Base.rand(s::PSDFixedRankComplex) = rand(randn(s.n, s.k)) + im * rand(randn(s.n, s.k))

function randvec(s::PSDFixedRankComplex,X)
    H = rand()
    P = proj(s, X, H)
    return _normalize(s, P)
end

transp(s::PSDFixedRankComplex, Y, Z, U) = proj(s, Z, U)

pairmean(s::PSDFixedRankComplex, X, Y) = @assert false "not implemented"

__normalize(s::PSDFixedRankComplex, Y) = Y / norm(s, nothing, Y)





struct Elliptope <: AbstractManifold
    n::Int
    k::Int
end

dim(s::Elliptope) = s.n * (s.k - 1) - s.k * (s.k - 1) / 2

typicaldist(s::Elliptope) = 10 * s.k

inner(s::Elliptope, X, U, V) = full_tensor_dot(X\U, X\V)

Base.norm(s::Elliptope, Y, U) = sqrt(inner(s,Y,U,U))

dist(s::Elliptope, X, Y) = @assert false "not implemented"

function proj(s::Elliptope, Y, H)
    eta = _project_rows(s, Y, H)
    YtY = dot(Y,Y')
    AS = dot(eta,Y') - dot(Y,H')
    Omega = lyap(YtY, -AS)
    return eta - dot((Omega - Omega.T) / 2, Y)
end

egrad2grad(s::Elliptope, Y, egrad) = _project_rows(Y, egrad)

function ehess2rhess(s::Elliptope, Y, egrad, ehess, U)
    scaling_grad = sum((egrad * Y),1)
    hess = ehess - U * reshape(scaling_grad, (1,size(scaling_grad)...))
    scaling_hess = sum((U * egrad + Y * ehess), 1)
    hess -= Y * reshape(scaling_hess, (1, size(scaling_hess)))
    return proj(s, Y, hess)
end

function Base.exp(s::Elliptope, X, U)
    warn("Exponential map for symmetric, fixed-rank. Manifold not implemented yet. Used retraction instead.")
    return retr(s, X, U)
end

retr(s::Elliptope, X, G) = X + U

Base.log(s::Elliptope, X, Y) = @assert false "not implemented"

Base.rand(s::Elliptope) = __normalize_rows(s, randn(s.n, s.k))

function randvec(s::Elliptope,X)
    H = proj(s, X, rand())
    return H / norm(s, X, H)
end

transp(s::Elliptope, Y, Z, U) = proj(s, Z, U)

pairmean(s::Elliptope, X, Y) = @assert false "not implemented"

__normalize_rows(s::Elliptope, Y) = Y / reshape(norm(s, nothing, Y), (1,size(norm(s, nothing, Y))))

function _project_rows(s::Elliptope,Y,H)
    inners = sum(Y*H, 1)
    return H - Y * reshape(inners, (1, size(inners)))
end
