# scripts/audit/01_separate_packages.jl

using HTTP
using JSON3
using CSV
using DataFrames

include("../utils.jl")

const OUTPUT_PACKAGES = "data/results/packages.csv"
const OUTPUT_NONPACKAGES = "data/results/non_packages.csv"

function discover_org_repos(org::String)
    println("Discovering organization repositories for: $org")

    headers = [
        "User-Agent" => GITHUB_USER_AGENT, "Authorization" => "token $GITHUB_TOKEN"
    ]

    repos = DataFrame(; name=String[], html_url=String[])

    page = 1
    per_page = 100

    while true
        url = "$GITHUB_API/orgs/$org/repos?per_page=$per_page&page=$page"
        try
            response = HTTP.get(url, headers)
            data = JSON3.read(response.body)
            isempty(data) && break

            for r in data
                push!(repos, (r.name, r.html_url))
            end
            page += 1
        catch e
            @error "Failed to fetch page $page: $e"
            break
        end
    end

    println("Discovered $(nrow(repos)) repositories in $org\n")
    return repos
end

function is_package(name::String)
    endswith(name, ".jl")
end

org_repos = discover_org_repos(TARGET_ORG)

packages_df = DataFrame(; package_name=String[], github_repo_url=String[])

non_packages_df = DataFrame(; repo_name=String[], github_repo_url=String[])

println("Separating packages from non-packages")
for row in eachrow(org_repos)
    if is_package(row.name)
        push!(packages_df, (row.name, row.html_url))
    else
        push!(non_packages_df, (row.name, row.html_url))
    end
end

sort!(packages_df, [:package_name])
sort!(non_packages_df, [:repo_name])

mkpath("data/results")
CSV.write(OUTPUT_PACKAGES, packages_df)
CSV.write(OUTPUT_NONPACKAGES, non_packages_df)

println("\nSeparation complete:")
println("PACKAGES: $(nrow(packages_df)) -> $OUTPUT_PACKAGES")
println("NON-PACKAGES: $(nrow(non_packages_df)) -> $OUTPUT_NONPACKAGES")
