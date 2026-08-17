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

function is_target_org_repo_url(url::String, target_org::String)
    try
        owner, _ = parse_repo_url(url)
        return lowercase(owner) == lowercase(target_org)
    catch
        return false
    end
end

org_repos_file = "data/results/packages.csv"
org_repos = CSV.read(org_repos_file, DataFrame)

strip_jl(name) = replace(String(name), r"\.jl$" => "")
org_package_urls = Dict(strip_jl(row.package_name) => String(row.github_repo_url) for row in eachrow(org_repos))
org_packages = Set(keys(org_package_urls))

println("Discovering $TARGET_ORG packages in General Registry")
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
    url_matches_org=Bool[],
)

mismatch_packages = DataFrame(;
    package_name=String[], org_repo_url=String[], registry_repo_url=String[]
)

println("\nChecking $TARGET_ORG packages in General Registry")

for package_name in org_packages
    if !haskey(pkg_paths, package_name)
        continue
    end

    registry_path = pkg_paths[package_name]
    repo_url, fetch_success = fetch_package_toml(registry_path)

    if fetch_success
        org_repo_url = get(org_package_urls, package_name, "")
        isempty(org_repo_url) && continue

        is_target_org = is_target_org_repo_url(repo_url, TARGET_ORG)

        owner, repo = parse_repo_url(org_repo_url)
        repo_info = get_repo_info(owner, repo)
        
        if !isnothing(repo_info) && repo_info.is_fork
            continue
        end
        
        push!(registry_packages, (package_name, registry_path, repo_url, is_target_org))

        if !is_target_org
            push!(
                mismatch_packages,
                (package_name, org_repo_url, repo_url),
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
println("Found $(nrow(registry_packages)) $TARGET_ORG packages in registry")
println("Mismatches Found in $(nrow(mismatch_packages)) $TARGET_ORG packages in registry")
println("Saved to: $REGISTRY_PACKAGES_OUTPUT")
