#!/usr/bin/env julia
# scripts/discovery/discover_org.jl
# Fetch JuliaHealth organization repositories via GitHub API
# Output: data/baselines/org_repositories.csv

using HTTP
using JSON3
using DataFrames
using CSV
using DotEnv

DotEnv.load!()

const GITHUB_API = "https://api.github.com"
const GITHUB_TOKEN = get(ENV, "GITHUB_TOKEN", "")
GITHUB_TOKEN == "" && error("GITHUB_TOKEN not set")

function list_juliahealth_repos()
    headers = Dict(
        "Authorization" => "Bearer $GITHUB_TOKEN",
        "Accept" => "application/vnd.github+json",
        "User-Agent" => "juliahealth-audit",
    )

    repos = DataFrame(;
        name=String[],
        html_url=String[],
        stars=Int[],
        archived=Bool[],
        fork=Bool[],
        created_at=String[],
        pushed_at=String[],
    )

    page = 1

    while true
        url = "$GITHUB_API/orgs/JuliaHealth/repos?per_page=100&page=$page"
        response = HTTP.get(url, headers)
        data = JSON3.read(response.body)

        isempty(data) && break

        for r in data
            push!(
                repos,
                (
                    r.name,
                    r.html_url,
                    r.stargazers_count,
                    r.archived,
                    r.fork,
                    r.created_at,
                    r.pushed_at,
                ),
            )
        end

        page += 1
    end

    mkpath("data/baselines")
    CSV.write("data/baselines/org_repositories.csv", repos)

    println("✓ Discovered $(nrow(repos)) repositories in JuliaHealth organization")
    println("  → data/baselines/org_repositories.csv")
end

list_juliahealth_repos()
