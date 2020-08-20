## Socrates for Julia

### Overview

Julia is a high-performance language for technical computing,
and pairs well with the functionality Socrates offers.

This interface provides an environment where those versed in Julia
can hit the ground running.

### Install

This package supports Julia 1.5.0 

#### Stable

```bash
pkg> add https://github.com/jyro-io/sji/releases/tag/0.1.2
```

#### Latest

```bash
pkg> add https://github.com/jyro-io/sji
```

#### Usage

```julia
using sji

socrates = sji.Socrates(
      username="test",
      password="7Dz26dv9iFn7"
)
```
