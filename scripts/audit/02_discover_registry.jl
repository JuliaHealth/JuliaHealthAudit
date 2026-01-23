# scripts/audit/02_discover_registry.jl

using HTTP
using TOML
using CSV
using DataFrames

include("../utils.jl")

const REGISTRY_BASE_URL = "https://raw.githubusercontent.com/JuliaRegistries/General/master"
const REGISTRY_PACKAGES_OUTPUT = "data/results/registry_packages.csv"
const MISMATCH_PACKAGES_OUTPUT = "data/results/registry_mismatches.csv"

function fetch_package_toml(pkg_path::String)
    url = "$REGISTRY_BASE_URL/$pkg_path/Package.toml"
    try
        response = HTTP.get(url; status_exception=false)
        if response.status == 200
            pkg_toml = TOML.parse(String(response.body))
            repo_url = get(pkg_toml, "repo", "")
            return (repo_url, true)
        end
    catch e
        @error "Failed to fetch Package.toml for $pkg_path: $e"
    end
    return ("", false)
end

function is_juliahealth_url(url::String)
    occursin(r"github\.com/juliahealth/"i, url)
end

org_repos_file = "data/results/packages.csv"
org_repos = CSV.read(org_repos_file, DataFrame)

strip_jl(name) = replace(String(name), r"\.jl$" => "")
juliahealth_packages = Set(strip_jl(pkg) for pkg in org_repos.package_name)

println("Discovering JuliaHealth packages in General Registry")
println("Loading Registry.toml...")

registry_url = "$REGISTRY_BASE_URL/Registry.toml"
response = HTTP.get(registry_url)
registry_toml = TOML.parse(String(response.body))

pkg_paths = Dict{String,String}()
if haskey(registry_toml, "packages")
    for (uuid, pkg_info) in registry_toml["packages"]
        pkg_paths[pkg_info["name"]] = pkg_info["path"]
    end
end

registry_packages = DataFrame(;
    package_name=String[],
    registry_path=String[],
    registry_repo_url=String[],
    url_matches_juliahealth=Bool[],
)

mismatch_packages = DataFrame(;
    package_name=String[], org_repo_url=String[], registry_repo_url=String[]
)

println("\nChecking JuliaHealth packages in General Registry")

for package_name in juliahealth_packages
    if !haskey(pkg_paths, package_name)
        continue
    end

    registry_path = pkg_paths[package_name]
    repo_url, fetch_success = fetch_package_toml(registry_path)

    if fetch_success
        is_juliahealth_org = is_juliahealth_url(repo_url)
        push!(
            registry_packages, (package_name, registry_path, repo_url, is_juliahealth_org)
        )

        if !is_juliahealth_org
            push!(
                mismatch_packages,
                (package_name, "https://github.com/JuliaHealth/$package_name.jl", repo_url),
            )
        end
    end
end

sort!(registry_packages, :package_name)
sort!(mismatch_packages, :package_name)

mkpath(dirname(REGISTRY_PACKAGES_OUTPUT))
CSV.write(REGISTRY_PACKAGES_OUTPUT, registry_packages)
CSV.write(MISMATCH_PACKAGES_OUTPUT, mismatch_packages)

println("\nRegistry discovery complete:")
println("Found $(nrow(registry_packages)) JuliaHealth packages in registry")
println("Mismatches Found in $(nrow(mismatch_packages)) JuliaHealth packages in registry")
println("Saved to: $REGISTRY_PACKAGES_OUTPUT")

