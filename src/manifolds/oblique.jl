struct Oblique <: AbstractManifold
    m::Int
    n::Int
end
dim(s::Oblique) = (s.m - 1) * s.n

typicaldist(s::Oblique) = pi * sqrt(s.n)

# TODO FIGURE OUT TENSORDOT
inner(s::Oblique, X, U, V) = @assert false "not implemented"

norm(s::Oblique, X, U) = norm(U)

function dist(s::Oblique, X, Y)
    XY = sum(X * Y, 1)
    XY[XY >. 1] = 1
    return norm(acos(XY))
end

proj(s::Oblique, X, H) = H - X * reshape(sum(X * H, 1), (1,size(sum(X * H, 1))...))

egrad2grad = proj

function ehess2rhess(s::Oblique, X, egrad, ehess, U)
    PXehess = proj(s, X, ehess)
    return PXehess - U * reshape(sum(X * egrad, 1), (1,size(sum(X * egrad, 1))...))
end

### TODO check that this works
function exp(s::Oblique, X, U)
    expression = sqrt(sum(U^2,1))
    norm_U = reshape(expression, (1,expression...))

    Y = X * cos(norm_U) + U * (sin(norm_U) / norm_U)

    exclude = np.nonzero(norm_U <= 4.5e-8)[-1]
    Y[:, exclude] = _normalize_columns(a, X[:, exclude] + U[:, exclude])

    return Y
end


retr(s::Oblique, X, U) = _normalize_columns(s, X + U)

function log(s::Oblique, X, Y)
    V = self.proj(X, Y - X)
    dists = acos(sum((X * Y),1))
    norms = real(sqrt(sum((V^2))))
    factors = dists ./ norms
    factors[dists <= 1e-6] = 1
    return V * factors
end

rand(s::Oblique) = _normalize_columns(randn(s.d...))

function randvec(s::Oblique,X)
    H = randn(size(X)...)
    P = proj(s, X, H)
    return P / norm(s, X, P)
end

transp(s::Oblique, X, Y, U) = proj(s, Y, U)

pairmean(s::Oblique, X, Y) = _normalize_columns(s, X + Y)

_normalize_columns(s::Oblique, X) = X / reshape(norm(X), (1, size(norm(X))...))
