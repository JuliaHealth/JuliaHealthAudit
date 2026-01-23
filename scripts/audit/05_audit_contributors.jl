# scripts/audit/05_audit_contributors.jl

using CSV
using DataFrames

include("../utils.jl")

const ORG = "juliahealth"
const CONTRIBUTORS_OUTPUT = "data/results/audit_contributors.csv"

println("Fetching repositories for org: $ORG")
repos = String[]
page = 1

while true
    data = github_request("/orgs/$ORG/repos?per_page=100&page=$page&type=all")
    isnothing(data) && break
    isempty(data) && break

    for repo in data
        repo_name = get(repo, :name, "")
        !isempty(repo_name) && push!(repos, String(repo_name))
    end

    length(data) < 100 && break
    page += 1
end

println("Found $(length(repos)) repositories")

contributors = Dict{String,Dict{Symbol,Any}}()

for (idx, repo_name) in enumerate(repos)
    println("[$idx/$(length(repos))] $repo_name")

    page = 1
    while true
        data = github_request("/repos/$ORG/$repo_name/contributors?per_page=100&page=$page")
        isnothing(data) && break
        isempty(data) && break

        for contributor in data
            login = get(contributor, :login, "")
            isempty(login) && continue

            user_type = get(contributor, :type, "User")
            user_type == "Bot" && continue

            contribution_count = get(contributor, :contributions, 0)

            if !haskey(contributors, login)
                contributors[login] = Dict(:contributions => 0, :repos => Set{String}())
            end

            contributors[login][:contributions] += contribution_count
            push!(contributors[login][:repos], repo_name)
        end

        length(data) < 100 && break
        page += 1
    end
end

println("Building results for $(length(contributors)) contributors..")

results = []

for (login, info) in contributors
    profile = github_request("/users/$login")

    display_name = if !isnothing(profile)
        profile_name = get(profile, :name, nothing)
        !isempty(String(profile_name)) ? String(profile_name) : login
    else
        login
    end

    repos_contributed = sort(collect(info[:repos]))
    repos_list_str = join(repos_contributed, "; ")

    push!(
        results,
        (
            login=login,
            name=display_name,
            num_repos_contributed=length(repos_contributed),
            total_contributions=info[:contributions],
            repos_list=repos_list_str,
        ),
    )
end

results_df = DataFrame(results)
sort!(results_df, :total_contributions; rev=true)

mkpath(dirname(CONTRIBUTORS_OUTPUT))
CSV.write(CONTRIBUTORS_OUTPUT, results_df)

println("Saved to: $CONTRIBUTORS_OUTPUT")

