# scripts/audit/03_audit_non_packages.jl
# Audit non-package repositories with 21 metrics via GitHub API

using CSV
using DataFrames

include("../utils.jl")

NON_PACKAGES_INPUT = "data/results/non_packages.csv"
AUDIT_NONPACKAGES_OUTPUT = "data/results/audit_non_packages.csv"

function audit_non_package(row)
    repo_name = row.repo_name
    repo_url = row.github_repo_url

    owner, repo = parse_repo_url(repo_url)
    repo_info = get_repo_info(owner, repo)
    isnothing(repo_info) && (println("   Failed to fetch repo info"); return nothing)

    tree = get_tree(owner, repo, repo_info.default_branch)
    has_license = any(contains.(tree, "LICENSE"))

    contributors = get_contributors_count(owner, repo)
    open_issues, open_prs = get_open_issues_count(owner, repo)
    closed_issues = get_closed_issues_count(owner, repo)
    closed_prs = get_closed_prs_count(owner, repo)

    commits_last_year = get_commits_last_year(owner, repo)

    issue_resolution_rate = if (open_issues + closed_issues > 0)
        round(100 * closed_issues / (open_issues + closed_issues); digits=1)
    else
        0
    end
    pr_resolution_rate = if (open_prs + closed_prs > 0)
        round(100 * closed_prs / (open_prs + closed_prs); digits=1)
    else
        0
    end

    has_ci = any(contains.(tree, ".github/workflows/"))

    return (
        # 1. Identity (3)
        repo_name=repo_name,
        github_repo_url=repo_url,
        is_archived=repo_info.archived,
        # 2. Repository Structure (1)
        has_license=has_license,
        # 3. Activity & Maintenance (9)
        pushed_at=if isempty(something(repo_info.pushed_at, ""))
            missing
        else
            repo_info.pushed_at
        end,
        stars=repo_info.stars,
        contributors_count=contributors,
        open_issues_count=open_issues,
        closed_issues_count=closed_issues,
        issue_resolution_rate=issue_resolution_rate,
        open_prs_count=open_prs,
        closed_prs_count=closed_prs,
        pr_resolution_rate=pr_resolution_rate,
        # 5. CI/CD (1)
        has_ci_workflow=has_ci,
    )
end

isfile(NON_PACKAGES_INPUT) ||
    error("$NON_PACKAGES_INPUT not found. Run 01_separate_packages.jl first.")

non_packages = CSV.read(NON_PACKAGES_INPUT, DataFrame)
println("Auditing $(nrow(non_packages)) non-package repositories...\n")

results = []
for (idx, row) in enumerate(eachrow(non_packages))
    try
        println("[$(idx)/$(nrow(non_packages))] Auditing: $(row.repo_name)")
        result = audit_non_package(row)
        if !isnothing(result)
            push!(results, result)
        end
    catch e
        println("  Error: $(e)")
    end
end

isempty(results) && error("No non-packages audited successfully")

audit_df = DataFrame(results)
sort!(audit_df, :stars; rev=true)

mkpath(dirname(AUDIT_NONPACKAGES_OUTPUT))
CSV.write(
    AUDIT_NONPACKAGES_OUTPUT, audit_df; transform=(col, val) -> something(val, missing)
)

println("\nDone. Audited $(nrow(audit_df)) non-package repositories")
println("Saved to: $AUDIT_NONPACKAGES_OUTPUT")
