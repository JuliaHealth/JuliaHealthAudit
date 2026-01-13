#!/usr/bin/env julia
# scripts/discover_registry.jl
# Scan local General Registry for JuliaHealth packages
# Requires: General Registry cloned to "General Registry/General"
# Output: data/baselines/registry_packages.csv, registry_mismatches.csv

using TOML
using CSV
using DataFrames

const REGISTRY_PATH = "General Registry/General"
const ORG_REPOS_FILE = "data/baselines/org_repositories.csv"
const OUT_REGISTRY_PACKAGES = "data/baselines/registry_packages.csv"
const OUT_MISMATCHES = "data/baselines/registry_mismatches.csv"

isdir(REGISTRY_PATH) || error(
    "Registry not found at $REGISTRY_PATH\nClone it: git clone https://github.com/JuliaRegistries/General.git \"General Registry/General\"",
)
isfile(ORG_REPOS_FILE) || error("$ORG_REPOS_FILE not found. Run discover_org.jl first.")

org_repos = CSV.read(ORG_REPOS_FILE, DataFrame)

function strip_jl(name::String)
    replace(name, r"\.jl$" => "")
end

# Get all org repo names (with .jl stripped)
org_repo_names = Set(strip_jl.(org_repos.name))

registry_packages = String[]
moved_packages = String[]

# Scan registry directory structure (A/, B/, ..., Z/)
for letter_dir in readdir(REGISTRY_PATH)
    letter_path = joinpath(REGISTRY_PATH, letter_dir)
    !isdir(letter_path) && continue
    letter_dir ∉ [
        "A",
        "B",
        "C",
        "D",
        "E",
        "F",
        "G",
        "H",
        "I",
        "J",
        "K",
        "L",
        "M",
        "N",
        "O",
        "P",
        "Q",
        "R",
        "S",
        "T",
        "U",
        "V",
        "W",
        "X",
        "Y",
        "Z",
    ] && continue

    for pkg_dir in readdir(letter_path)
        pkg_path = joinpath(letter_path, pkg_dir)
        !isdir(pkg_path) && continue

        # Check if this package is from JuliaHealth org
        pkg_toml_file = joinpath(pkg_path, "Package.toml")
        if isfile(pkg_toml_file)
            try
                pkg_toml = TOML.parsefile(pkg_toml_file)
                repo_url = lowercase(get(pkg_toml, "repo", ""))

                if occursin("github.com/juliahealth/", repo_url)
                    push!(registry_packages, pkg_dir)
                else
                    # Check if it was a JuliaHealth package that moved
                    if pkg_dir in org_repo_names
                        push!(moved_packages, pkg_dir)
                    end
                end
            catch
                # Skip packages with invalid Package.toml
            end
        end
    end
end

registry_packages = sort(unique(registry_packages))
moved_packages = sort(unique(moved_packages))

mkpath(dirname(OUT_REGISTRY_PACKAGES))
CSV.write(OUT_REGISTRY_PACKAGES, DataFrame(; package_name=registry_packages))
CSV.write(OUT_MISMATCHES, DataFrame(; package_name=moved_packages))

println("Scanned the General Registry")
println("Found $(length(registry_packages)) JuliaHealth packages")
println("Saved to: data/baselines/registry_packages.csv")
if !isempty(moved_packages)
    println("\nWarning: $(length(moved_packages)) packages have moved from JuliaHealth:")
    for name in moved_packages
        println("  - $name")
    end
    println("Saved to: data/baselines/registry_mismatches.csv")
end
