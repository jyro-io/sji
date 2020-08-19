using sji
using Test

@testset "sji.jl" begin
    socrates = sji.Socrates(
        log_level=3,
        protocol="https",
        host="api.jyro.io",
        username="test",
        password="7Dz26dv9iFn7",
        verify=true
    )
end
