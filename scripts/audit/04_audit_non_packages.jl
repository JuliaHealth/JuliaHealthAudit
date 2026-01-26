# scripts/audit/04_audit_non_packages.jl

using CSV
using DataFrames

include("../utils.jl")

const NON_PACKAGES_INPUT = "data/results/non_packages.csv"
const AUDIT_NONPACKAGES_OUTPUT = "data/results/audit_non_packages.csv"

function audit_non_package(row)
    repo_name = row.repo_name
    repo_url = row.github_repo_url

    owner, repo = parse_repo_url(repo_url)
    repo_info = get_repo_info(owner, repo)
    isnothing(repo_info) && (println("Failed to fetch repo info"); return nothing)

    tree = get_tree(owner, repo, repo_info.default_branch)
    has_license = any(contains.(tree, "LICENSE"))
    license_type = get_license_info(owner, repo)

    human_contributors_list, human_contributors_count, bot_contributors_list, bot_contributors_count = get_all_contributors_list(owner, repo)
    maintainers_list, maintainers_count, active_maintainers_list, active_maintainers_count = get_maintainers_info(owner, repo)

    open_issues, open_prs = get_open_issues_count(owner, repo)
    closed_issues = get_closed_issues_count(owner, repo)
    closed_prs = get_closed_prs_count(owner, repo)

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

    readme_content = get_readme_content(owner, repo)
    readme_info = assess_readme_completeness(readme_content)

    pr_metrics = get_pr_metrics(owner, repo)
    activity_data = get_last_activity_date(owner, repo)
    days_since_activity = activity_data.days_since_activity
    
    # For non-packages, releases_count is assumed 0 (not in registry)
    maintenance_status = classify_maintenance_status(maintainers_count, active_maintainers_count, days_since_activity, 0)
    has_active_maintainers = active_maintainers_count > 0

    return (
        repo_name=repo_name,
        github_repo_url=repo_url,
        is_archived=repo_info.archived,
        has_license=has_license,
        license_type=license_type,
        pushed_at=repo_info.pushed_at,
        stars=repo_info.stars,
        open_issues_count=open_issues,
        closed_issues_count=closed_issues,
        issue_resolution_rate=issue_resolution_rate,
        open_prs_count=open_prs,
        closed_prs_count=closed_prs,
        pr_resolution_rate=pr_resolution_rate,
        readme_has_code_blocks=readme_info.has_code_blocks,
        readme_line_count=readme_info.readme_size,
        readme_has_install=readme_info.has_install,
        readme_has_usage=readme_info.has_usage,
        readme_has_contributing=readme_info.has_contributing,
        readme_lists_count=readme_info.lists_count,
        readme_links_count=readme_info.links_count,
        readme_code_blocks_count=readme_info.code_blocks_count,
        readme_badges_count=readme_info.badges_count,
        readme_sections_count=readme_info.sections_count,
        readme_completeness_score=readme_info.completeness_score,
        human_contributors_list=human_contributors_list,
        human_contributors_count=human_contributors_count,
        bot_contributors_list=bot_contributors_list,
        bot_contributors_count=bot_contributors_count,
        maintainers_list=maintainers_list,
        maintainers_count=maintainers_count,
        active_maintainers_list=active_maintainers_list,
        active_maintainers_count=active_maintainers_count,
        has_active_maintainers=has_active_maintainers,
        maintenance_status=maintenance_status,
        has_ci_workflow=has_ci,
        avg_pr_merge_days=pr_metrics.avg_merge_days,
        days_since_last_activity=days_since_activity
    )
end

function run_audit_non_packages()
    non_packages = CSV.read(NON_PACKAGES_INPUT, DataFrame)
    println("Auditing $(nrow(non_packages)) non-package repositories..\n")

    results = []
    for (idx, row) in enumerate(eachrow(non_packages))
        try
            println("[$(idx)/$(nrow(non_packages))] Auditing: $(row.repo_name)")
            result = audit_non_package(row)
            if !isnothing(result)
                push!(results, result)
            end
        catch e
            println("Error: $(e)")
        end
    end

    isempty(results) && error("No non-packages audited successfully")

    audit_df = DataFrame(results)
    mkpath(dirname(AUDIT_NONPACKAGES_OUTPUT))
    CSV.write(AUDIT_NONPACKAGES_OUTPUT, audit_df)

    println("\nDone. Audited $(nrow(audit_df)) non-package repositories")
    println("Saved to: $AUDIT_NONPACKAGES_OUTPUT")
end

run_audit_non_packages()
