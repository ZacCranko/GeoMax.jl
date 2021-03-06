#############
# contract! #
#############

macro contract!(c_expr, a_expr, b_expr)
    @assert c_expr.head == :ref && a_expr.head == :ref && b_expr.head == :ref

    a_name = a_expr.args[1]
    b_name = b_expr.args[1]
    c_name = c_expr.args[1]

    a_subscripts = a_expr.args[2:end]
    b_subscripts = b_expr.args[2:end]
    c_subscripts = c_expr.args[2:end]

    @assert setdiff(a_subscripts, b_subscripts) == setdiff(c_subscripts, b_subscripts)
    @assert setdiff(b_subscripts, a_subscripts) == setdiff(c_subscripts, a_subscripts)

    contraction_indices = findin(a_subscripts, b_subscripts)

    # Here, we build up the kernel which performs the sum
    # reduction over the matching `a` and `b` indices.
    kernel_result = gensym()
    kernel = :($kernel_result += $a_expr * $b_expr)
    for i in contraction_indices
        kernel = quote
            @inbounds for $(a_subscripts[i]) in indices($a_name, $i)
                $kernel
            end
        end
    end
    kernel = quote
        $kernel_result = zero(eltype($c_name))
        $kernel
        $c_expr = $kernel_result
    end

    # Here, we build up the loop over the `c` indices.
    # Note our indexing pattern: looping over the left-most
    # index in the inner-most loop, and the second left-most
    # index in the second inner-most loop, etc. This should
    # linearly index over `c`, due to how Julia lays out the
    # array in memory. However, this indexing is not necessarily
    # linear over `a` and `b` (figuring that out how to do that
    # would be more complicated).
    loop = kernel
    i = 1
    for subscript in c_subscripts
        loop = quote
            @inbounds for $subscript in indices($c_name, $i)
                $loop
            end
        end
        i += 1
    end
    return esc
end

################
# tensor_*_dot #
################

function tensor_single_dot(a::AbstractArray{<:Real,3},
                           b::AbstractArray{<:Real,3})
    c = similar(a, size(a, 1), size(b, 3))
    return tensor_double_dot!(c, a, b)
end

function tensor_single_dot!(c::AbstractArray{<:Real,4},
                            a::AbstractArray{<:Real,3},
                            b::AbstractArray{<:Real,3})
    return @contract!(c[i,j,l,m], a[i,j,k], b[k,l,m])
end

# same as np.tensordot(x, y)
function tensor_double_dot(a::AbstractArray{<:Real,3},
                           b::AbstractArray{<:Real,3})
    c = similar(a, size(a, 1), size(b, 3))
    return tensor_double_dot!(c, a, b)
end

function tensor_double_dot!(c::AbstractArray{<:Real,2},
                            a::AbstractArray{<:Real,3},
                            b::AbstractArray{<:Real,3})
    return @contract!(c[i,l], a[i,j,k], b[j,k,l])
end

tensor_full_dot(x, y) = vecdot(x, y)

#####################
# multiprod methods #
#####################

multiprod(A::AbstractArray{T1,2}, B::AbstractArray{T2,2}) where {T1,T2} = A * B
multiprod(A::AbstractArray{T1,3}, B::AbstractArray{T2,2}) where {T1,T2} = A .* B

multiprod(A::AbstractArray{T1,2}, B::AbstractArray{T2,3}) where {T1,T2} = multiprod(B,A)

function multiprod(a::AbstractArray{A,3}, b::AbstractArray{B,3}) where {A,B}
     c = similar(a, promote_type(A, B), size(a, 1), size(b, 2), size(a, 3))
     return multiprod!(c, a, b)
end

function multiprod!(c::AbstractArray{C,3},
                    a::AbstractArray{<:Number,3},
                    b::AbstractArray{<:Number,3}) where C<:Number
     for r = 1:size(a, 3)
        for i = 1:size(a, 1)
            for k = 1:size(b, 2)
                s = 0
                for j = 1:size(a, 2)
                    s += a[i,j,r] * b[j,k,r]
                end
                c[i,k,r] = s
            end
         end
      end
      return c
end
# function multiprod(a::AbstractArray{A,3}, b::AbstractArray{B,3}) where {A,B}
#     c = zeros(size(a, 1), size(a, 2), size(b, 3))
#     multiprod!(c, a, b)
#     return c
# end
#
# function multiprod!(c::AbstractArray{<:Real,3},
#                     a::AbstractArray{<:Real,3},
#                     b::AbstractArray{<:Real,3})
#     @contract!(c[i, j, r], a[i, j, k], b[i, k, r])
#     return c
# end

##################
# multi* methods #
##################

multitransp(A::AbstractArray) = permutedims(A, [2, 1, 3])
multitransp(A::AbstractArray{<:Any, 2}) = A'

multisym(A::AbstractArray) = 0.5 * (A + multitransp(A))

function multieye(k,n)
    A = zeros(n,n,k)
    multieye!(A)
end

multieye!(A) = mapslices(eye, A, (1,2))
    # a = zeros(k,n,n)
    # for i in 1:k
    #     a[:,:,i] = eye(n)
    # end
    # return a
# end

# TODO maybe do type checking of matrices. Split into errors and Hermitian
function multilog(A::AbstractArray)
    #@assert LinAlg.issymmetric(A) "not implemented"
    #@assert LinAlg.isposdef(A) "not implemented"
    l, v = eig(A)
    q = reshape(log.(l), 1, size(l)...)
    return multiprod(v, multitransp(v .* q))
#    l = reshape(log.(l'), 1, size(l)...)
#    return multiprod(v, l .* v)
end

# function multilog(A::AbstractArray{T,2}) where T
#     #@assert LinAlg.issymmetric(A) "not implemented"
#     #@assert LinAlg.isposdef(A) "not implemented"
#     l, v = eig(A)
#     l = reshape(log.(l), size(l)..., 1)'
#     return multiprod(v, collect(Iterators.flatten(l)) .* multitransp(v))
# end

function multiexp(A::AbstractArray)
    #@assert LinAlg.issymmetric(A) "not implemented"
    l, v = eig(A)
    l = reshape(exp.(l), 1, size(l)...)'
    return multiprod(v, l .* multitransp(v))
end

#############################
# Overwrite eig for tensors #
#############################

## TODO FIX PIRACY
function Base.eig(a::AbstractArray)
    s1, s2, s3 = size(a)
    @assert s1 == s2 "First two dimensions must be the same."
    a = mapslices(eig, a, (1,2))
    l = zeros(s1, s3)
    v = zeros(s1, s2, s3)
    for i in 1:s3
        l[:,i],v[:,:,i] = a[:,:,i][1]
    end
    return l,v
end

function solve(a::AbstractArray{A,3}, b::AbstractArray{B,3}) where {A,B}
   s = size(a,3)
   u = zeros(size(a)...)
   for i in 1:s
       u[:,:,i] = a[:,:,i]\b[:,:,i]
   end
   return u
end

function Base.cholfact(a::AbstractArray)
   @assert size(a,1) == size(a,2) "First two dimensions must be the same."
   #a = reshape(a, prod(size(a)[1:end-2]),size(a)[end-1:end]...)
   s = size(a,3)
   u = zeros(size(a)...)
   for i in 1:s
       u[:,:,i] = Array(cholfact(Hermitian(a[:,:,i]))[:L])
   end
   return u
end
