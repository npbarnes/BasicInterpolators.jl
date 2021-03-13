export CubicSplineInterpolator,
       ParametricCurveInterpolator,
       BicubicSplineInterpolator

#-------------------------------------------------------------------------------
# piecewise cubics with continuous derivatives (splines!)

struct CubicSplineInterpolator
    r::InterpolatorRange
    α::Array{Float64,2} #4xN array of cubic polynomial coefficients
end

"""
    CubicSplineInterpolator(x, y)

Construct a `CubicSplineInterpolator` for the points defined by coordinates `x` and values `y`. This constructor creates a natural spline, where the second derivative is set to zero at the boundaries.
"""
function CubicSplineInterpolator(x::AbstractVector{<:Real},
                                 y::AbstractVector{<:Real})
    #construct the underlying range, triggering some checks
    r = InterpolatorRange(x, y)
    n = r.n
    #compute coefficients
    #Burden, Richard L., and J. Douglas Faires. Numerical Analysis. 2011.
    a = collect(Float64, r.y)
    b = zeros(n - 1)
    d = zeros(n - 1)
    h = diff(r.x)
    α = zeros(n-1)
    for i = 2:n-1
        α[i] = 3*(a[i+1] - a[i])/h[i] - 3*(a[i] - a[i-1])/h[i-1]
    end
    c = zeros(n)
    l = ones(n)
    μ = zeros(n)
    z = zeros(n)
    l[1] = 1
    for i = 2:n-1
        l[i] = 2*(x[i+1] - x[i-1]) - h[i-1]*μ[i-1]
        μ[i] = h[i]/l[i]
        z[i] = (α[i] - h[i-1]*z[i-1])/l[i]
    end
    for j = n-1:-1:1
        c[j] = z[j] - μ[j]*c[j+1]
        b[j] = (a[j+1] - a[j])/h[j] - h[j]*(c[j+1] + 2*c[j])/3
        d[j] = (c[j+1] - c[j])/(3*h[j])
    end
    a = a[1:end-1]
    c = c[1:end-1]
    #construct the object
    CubicSplineInterpolator(r, hcat(a, b, c, d)')
end

"""
    CubicSplineInterpolator(x, y, dy₁, dyₙ)

Construct a `CubicSplineInterpolator` for the points defined by coordinates `x` and values `y`. This constructor creates a clamped spline, where the first derivatives at the boundaries are set by `dy₁` and `dyₙ`.
"""
function CubicSplineInterpolator(x::AbstractVector{<:Real},
                                 y::AbstractVector{<:Real},
                                 dy₁::Real,
                                 dyₙ::Real)
    #construct the underlying range, triggering some checks
    r = InterpolatorRange(x, y)
    n = r.n
    #compute coefficients
    #Burden, Richard L., and J. Douglas Faires. Numerical Analysis. 2011.
    a = collect(Float64, r.y)
    b = zeros(n - 1)
    d = zeros(n - 1)
    h = diff(r.x)
    α = zeros(n)
    α[1] = 3*(a[2] - a[1])/h[1] - 3*dy₁
    for i = 2:n-1
        α[i] = 3*(a[i+1] - a[i])/h[i] - 3*(a[i] - a[i-1])/h[i-1]
    end
    α[n] = 3*dyₙ - 3*(a[n] - a[n - 1])/h[n-1]
    c = zeros(n)
    l = zeros(n)
    μ = zeros(n)
    z = zeros(n)
    l[1] = 2*h[1]
    μ[1] = 0.5
    z[1] = α[1]/l[1]
    for i = 2:n-1
        l[i] = 2*(x[i+1] - x[i-1]) - h[i-1]*μ[i-1]
        μ[i] = h[i]/l[i]
        z[i] = (α[i] - h[i-1]*z[i-1])/l[i]
    end
    l[n] = h[n-1]*(2 - μ[n-1])
    z[n] = (α[n] - h[n-1]*z[n-1])/l[n]
    c[n] = z[n]
    for j = n-1:-1:1
        c[j] = z[j] - μ[j]*c[j+1]
        b[j] = (a[j+1] - a[j])/h[j] - h[j]*(c[j+1] + 2*c[j])/3
        d[j] = (c[j+1] - c[j])/(3*h[j])
    end
    #coefficient table
    α = hcat(a[1:end-1], b, c[1:end-1], d)'
    #construct the object
    CubicSplineInterpolator(r, α)
end

"""
    CubicSplineInterpolator(f, xa, xb, n)

Construct a `CubicSplineInterpolator` for the function `f` using `n` evenly spaced function evaluations in the range [`xa`,`xb`]. A natural spline is created.
"""
function CubicSplineInterpolator(f::Function, xa::Real, xb::Real, n::Int)
    linstruct(CubicSplineInterpolator, f, xa, xb, n)
end

function (ϕ::CubicSplineInterpolator)(x::Real, bounds::Bool=true)::Float64
    #enforce boundaries if desired
    enforcebounds(x, ϕ.r.xa, ϕ.r.xb, bounds)
    #find the interpolation point
    i = findcell(x, ϕ.r.x)
    #offset from the nearest lower point
    ξ = x - ϕ.r.x[i]
    #evaluate polynomial
    ϕ.α[1,i] + ϕ.α[2,i]*ξ + ϕ.α[3,i]*ξ^2 + ϕ.α[4,i]*ξ^3
end

#-------------------------------------------------------------------------------
# cubic splines on a regular grid

struct BicubicSplineInterpolator
    G::InterpolatorGrid
    α::Array{Array{Float64,2},2}
end

"""
    BicubicSplineInterpolator(x, y, Z)

Construct a `BicubicSplineInterpolator` for the grid of points points defined by coordinates `x`,`y` and values `Z`.
"""
function BicubicSplineInterpolator(x::AbstractVector{<:Real},
                                   y::AbstractVector{<:Real},
                                   Z::AbstractArray{<:Real,2})
    nx, ny = size(Z)
    #insist on at least 4 points in each dimension
    @assert nx >= 3 "bicubic interpolation requires at least 3 points along axis 1"
    @assert ny >= 3 "bicubic interpolation requires at least 3 points along axis 2"
    #insist on even spacing along both axes
    @assert all(diff(diff(x)) .< 1e-8*maximum(abs.(x))) "grid spacing along axis 1 must be uniform"
    @assert all(diff(diff(y)) .< 1e-8*maximum(abs.(y))) "grid spacing along axis 2 must be uniform"
    #space for derivatives
    dx = zeros(nx, ny)
    dy = zeros(nx, ny)
    dxy = zeros(nx, ny)
    #first derivatives for internal nodes
    for i = 2:nx-1
        for j = 1:ny
            dx[i,j] = (Z[i+1,j] - Z[i-1,j])/2
        end
    end
    for i = 1:nx
        for j = 2:ny-1
            dy[i,j] = (Z[i,j+1] - Z[i,j-1])/2
        end
    end
    #first derivatives for bounary nodes
    for i = 1:nx
        dy[i,1] = -3*Z[i,1]/2 + 2*Z[i,2] - Z[i,3]/2
        dy[i,ny] = Z[i,ny-2]/2 - 2*Z[i,ny-1] + 3*Z[i,ny]/2
    end
    for j = 1:ny
        dx[1,j] = -3*Z[1,j]/2 + 2*Z[2,j] - Z[3,j]/2
        dx[nx,j] = Z[nx-2,j]/2 - 2*Z[nx-1,j] + 3*Z[nx,j]/2
    end
    #mixed second order derivatives at internal nodes
    for i = 1:nx
        for j = 2:ny-1
            dxy[i,j] = (dx[i,j+1] - dx[i,j-1])/2
        end
    end
    #mixed second deriv along the sides
    for i = 1:nx
        dxy[i,1] = -3*dx[i,1]/2 + 2*dx[i,2] - dx[i,3]/2
        dxy[i,ny] = dx[i,ny-2]/2 - 2*dx[i,ny-1] + 3*dx[i,ny]/2
    end
    #matrix needed to compute coefficients and its transpose
    A = [1. 0. 0. 0.; 0. 0. 1. 0.; -3. 3. -2. -1.; 2. -2. 1. 1.]
    Aᵀ = transpose(A)
    #space for coefficients
    f = zeros(4, 4)
    α = Array{Array{Float64,2},2}(undef, nx-1, ny-1)
    for i = 1:nx-1
        for j = 1:ny-1
            #load the matrix of 16 values and derivatives
            f[1,1] = Z[i,j]
            f[1,2] = Z[i,j+1]
            f[1,3] = dy[i,j]
            f[1,4] = dy[i,j+1]
            f[2,1] = Z[i+1,j]
            f[2,2] = Z[i+1,j+1]
            f[2,3] = dy[i+1,j]
            f[2,4] = dy[i+1,j+1]
            f[3,1] = dx[i,j]
            f[3,2] = dx[i,j+1]
            f[3,3] = dxy[i,j]
            f[3,4] = dxy[i,j+1]
            f[4,1] = dx[i+1,j]
            f[4,2] = dx[i+1,j+1]
            f[4,3] = dxy[i+1,j]
            f[4,4] = dxy[i+1,j+1]
            #get the 16 double spline coefficients
            α[i,j] = A*f*Aᵀ
        end
    end
    BicubicSplineInterpolator(InterpolatorGrid(x, y, Z), α)
end

"""
    BicubicSplineInterpolator(f, xa, xb, nx, ya, yb, ny)

Construct a `BicubicSplineInterpolator` for the function `f` using a grid of `nx` points evenly spaced on the first axis in [`xa`,`xb`] and `ny` points evenly spaced on the second axis in [`ya`,`yb`].
"""
function BicubicSplineInterpolator(f::Function,
                                   xa::Real, xb::Real, nx::Int,
                                   ya::Real, yb::Real, ny::Int)
    linstruct(BicubicSplineInterpolator, f, xa, xb, nx, ya, yb, ny)
end

function (Φ::BicubicSplineInterpolator)(x::Real,
                                        y::Real,
                                        bounds::Bool=true)::Float64
    #enforce boundaries if desired
    enforcebounds(x, Φ.G.xa, Φ.G.xb, y, Φ.G.ya, Φ.G.yb, bounds)
    #find the proper grid box to interpolate inside
    i = findcell(x, Φ.G.x)
    j = findcell(y, Φ.G.y)
    #get the coefficients
    α = Φ.α[i,j]
    #offsets
    Δx = (x - Φ.G.x[i])/(Φ.G.x[i+1] - Φ.G.x[i])
    Δy = (y - Φ.G.y[j])/(Φ.G.y[j+1] - Φ.G.y[j])
    #powers of the offsets
    x1, x2, x3 = Δx, Δx^2, Δx^3
    y1, y2, y3 = Δy, Δy^2, Δy^3
    #final interpolation calculation (fastest written out like this)
    ( α[1,1]    + α[2,1]*x1    + α[3,1]*x2    + α[4,1]*x3
    + α[1,2]*y1 + α[2,2]*x1*y1 + α[3,2]*x2*y1 + α[4,2]*x3*y1
    + α[1,3]*y2 + α[2,3]*x1*y2 + α[3,3]*x2*y2 + α[4,3]*x3*y2
    + α[1,4]*y3 + α[2,4]*x1*y3 + α[3,4]*x2*y3 + α[4,4]*x3*y3)
end
