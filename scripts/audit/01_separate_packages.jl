# scripts/audit/01_separate_packages.jl
# Separate all repositories into packages (.jl) and non-packages (no .jl)
# No filtering - all 60 repos included

using CSV
using DataFrames
using Dates

include("../utils.jl")

ORG_REPOS = "data/baselines/org_repositories.csv"
REGISTRY_PKGS = "data/baselines/registry_packages.csv"
REGISTRY_MISMATCHES = "data/baselines/registry_mismatches.csv"
PACKAGES_OUTPUT = "data/results/packages.csv"
NONPACKAGES_OUTPUT = "data/results/non_packages.csv"

isfile(ORG_REPOS) || error("$ORG_REPOS not found. Run scripts/discover_org.jl first.")
isfile(REGISTRY_PKGS) ||
    error("$REGISTRY_PKGS not found. Run scripts/discover_registry.jl first.")

org_repos = CSV.read(ORG_REPOS, DataFrame)
registry_packages = Set(CSV.read(REGISTRY_PKGS, DataFrame).package_name)
registry_mismatches = if isfile(REGISTRY_MISMATCHES)
    Set(CSV.read(REGISTRY_MISMATCHES, DataFrame).package_name)
else
    Set{String}()
end

packages_df = DataFrame(;
    package_name=String[],
    github_repo_url=String[],
    stars=Int[],
    created_at=String[],
    pushed_at=String[],
    in_general_registry=Bool[],
)

non_packages_df = DataFrame(;
    repo_name=String[],
    github_repo_url=String[],
    stars=Int[],
    created_at=String[],
    pushed_at=String[],
)

function strip_jl(name::String)
    replace(name, r"\.jl$" => "")
end

function is_package(name::String)
    endswith(name, ".jl")
end

for row in eachrow(org_repos)
    if is_package(row.name)
        # PACKAGES: Include all with .jl suffix
        pkg_name = row.name
        pkg_name_base = strip_jl(row.name)
        in_registry =
            (pkg_name_base in registry_packages) || (pkg_name_base in registry_mismatches)

        push!(
            packages_df,
            (pkg_name, row.html_url, row.stars, row.created_at, row.pushed_at, in_registry),
        )
    else
        # NON-PACKAGES: Include all without .jl suffix
        push!(
            non_packages_df,
            (row.name, row.html_url, row.stars, row.created_at, row.pushed_at),
        )
    end
end

sort!(packages_df, [:in_general_registry, :stars, :pushed_at]; rev=true)
sort!(non_packages_df, [:stars, :pushed_at]; rev=true)

CSV.write(PACKAGES_OUTPUT, packages_df)
CSV.write(NONPACKAGES_OUTPUT, non_packages_df)

println("Separated repositories into packages and non-packages:")
println("PACKAGES: $(nrow(packages_df))")
println("  → $PACKAGES_OUTPUT")
println("NON-PACKAGES: $(nrow(non_packages_df))")
println("  → $NONPACKAGES_OUTPUT")
