# BasicInterpolators.jl ![downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/BasicInterpolators)

*Quick and easy interpolation methods for basic applications*

| Documentation | Status |
| :-----------: | :----: |
| [![docs](https://img.shields.io/badge/docs-latest-blue.svg)](https://markmbaum.github.io/BasicInterpolators.jl/dev)  | [![Build Status](https://github.com/markmbaum/BasicInterpolators.jl/workflows/CI/badge.svg)](https://github.com/markmbaum/BasicInterpolators.jl/actions) [![codecov](https://codecov.io/gh/markmbaum/BasicInterpolators.jl/branch/main/graph/badge.svg?token=yRg33tFcL3)](https://codecov.io/gh/markmbaum/BasicInterpolators.jl)  |

-----

### Installation

Use Julia's package manager to install
```
julia> ]add BasicInterpolators
```

-----

### Interpolation Methods

##### One Dimension

- [x] linear
- [x] piecewise cubic
- [x] cubic spline (natural or clamped)
- [x] Chebyshev
- [x] arbitrary order polynomials (Neville's method)
- [x] polynomial coefficients (efficient Vandermonde solver)
- [x] end-point cubic Hermite

##### Two Dimensions, Regular Grid

- [x] linear
- [x] piecewise cubic
- [x] Chebyshev

##### N-Dimensions, Scattered Points

- [x] radial basis functions (any choice of function)
- [x] Shepard

See the [**documentation**](https://markmbaum.github.io/BasicInterpolators.jl/dev/) for examples, discussion, and details.

-----

### Other packages

If you need other/advanced applications, check out:
1. [Interpolations.jl](https://github.com/JuliaMath/Interpolations.jl)
2. [Dierckx.jl](https://github.com/kbarbary/Dierckx.jl)
3. [GridInterpolations.jl](https://github.com/sisl/GridInterpolations.jl)
4. [ApproXD.jl](https://github.com/floswald/ApproXD.jl)
5. [FastChebInterp.jl](https://github.com/stevengj/FastChebInterp.jl)
