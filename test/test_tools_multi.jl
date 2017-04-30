a = ones(2,2,2)
a[:,:,1] += 2
a[:,:,2] += 4
e_val, e_vec = eig(a)
@test isapprox(e_val, [0.0 8.0; 0.0 8.0])

v = [-0.857493 -0.707107; 0.514496 -0.707107]
@test isapprox(e_vec[:,:,1],  v, atol=1e-5)

a = ones(2,2,2)
@test JManOpt.multiprod(a, 2a) == 4*ones(2,2,2)

a = eye(4)
@test JManOpt.multiprod(a, 2a) == 2*eye(4)

a = reshape(1:10,2,5)
@test a' == JManOpt.multitransp(a)

a = reshape(1:12,2,2,3)
@test [1 3; 5 7; 9 11] == JManOpt.multitransp(a)[1,:,:]

a = reshape(1:8,2,2,2)
@test [1 4; 4 7] == JManOpt.multisym(a)[1,:,:]

k = 3
n = 2
me = JManOpt.multieye(k,n)
@test size(me) == (k,n,n)
@test me[1,:,:] == eye(n)

@test isapprox(JManOpt.multilog(100*eye(4)), 4.60517*eye(4), atol = 1e-6)

#TODO more testing of multiexp
a = eye(2)
@test isapprox(JManOpt.multiexp(a), e .* eye(2))
