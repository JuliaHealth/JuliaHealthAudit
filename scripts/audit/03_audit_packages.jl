# scripts/audit/03_audit_packages.jl

using CSV
using DataFrames

include("../utils.jl")

const PACKAGES_INPUT = "data/results/packages.csv"
const REGISTRY_PACKAGES = "data/results/registry_packages.csv"
const AUDIT_PACKAGES_OUTPUT = "data/results/audit_packages.csv"

function audit_package(row, registry_set)
    pkg_name = row.package_name
    repo_url = row.github_repo_url

    owner, repo = parse_repo_url(repo_url)
    repo_info = get_repo_info(owner, repo)
    isnothing(repo_info) && (println("Failed to fetch repo info"); return nothing)

    tree_paths = get_tree(owner, repo, repo_info.default_branch)

    has_docs_dir = any(p -> startswith(p, "docs/"), tree_paths)
    has_src_dir = any(p -> startswith(p, "src/"), tree_paths)
    has_test_dir = any(p -> startswith(p, "test/"), tree_paths)
    has_ci = any(p -> startswith(p, ".github/workflows/"), tree_paths)
    code_coverage_config = has_code_coverage(owner, repo, tree_paths)
    has_gh_pages = has_gh_pages_branch(owner, repo)
    uses_documenter = any(p -> p == "docs/make.jl", tree_paths)
    has_project_toml = "Project.toml" in tree_paths
    has_license = any(p -> startswith(uppercase(p), "LICENSE"), tree_paths)
    has_contributing = "CONTRIBUTING.md" in tree_paths
    has_code_of_conduct = "CODE_OF_CONDUCT.md" in tree_paths

    readme_content = get_readme_content(owner, repo)
    readme_info = assess_readme_completeness(readme_content)

    style_guide = detect_style_guide(owner, repo, tree_paths)
    license_type = get_license_info(owner, repo)

    contributors_count, bot_count = get_contributors_count(owner, repo)
    all_contributors_str = get_all_contributors_list(owner, repo)

    open_issues, open_prs = get_open_issues_count(owner, repo)
    closed_issues = get_closed_issues_count(owner, repo)
    closed_prs = get_closed_prs_count(owner, repo)

    releases_count = get_releases_count(owner, repo)
    latest_release_date = get_latest_release_date(owner, repo)

    pr_metrics = get_pr_metrics(owner, repo)
    activity = get_last_activity_date(owner, repo)

    recommended_checks = (
        has_src_dir,
        has_project_toml,
        has_license,
        has_test_dir,
        has_docs_dir,
        has_ci,
        uses_documenter,
        code_coverage_config,
    )
    follows_standard = all(recommended_checks)

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

    pkg_name_clean = replace(pkg_name, ".jl" => "")
    in_general_registry_val = pkg_name_clean in registry_set || pkg_name in registry_set

    return (
        package_name=pkg_name,
        github_repo_url=repo_url,
        in_general_registry=in_general_registry_val,
        is_fork=repo_info.is_fork,
        is_archived=repo_info.archived,
        has_src_dir=has_src_dir,
        has_test_dir=has_test_dir,
        has_project_toml=has_project_toml,
        has_license=has_license,
        follows_standard_layout=follows_standard,
        has_docs_dir=has_docs_dir,
        has_gh_pages=has_gh_pages,
        uses_documenter=uses_documenter,
        has_contributing_md=has_contributing,
        has_code_of_conduct=has_code_of_conduct,
        has_ci_workflow=has_ci,
        has_code_coverage=code_coverage_config,
        releases_count=releases_count,
        latest_release_date=latest_release_date,
        pushed_at=isempty(repo_info.pushed_at) ? missing : repo_info.pushed_at,
        stars=repo_info.stars,
        open_issues_count=open_issues,
        closed_issues_count=closed_issues,
        open_prs_count=open_prs,
        closed_prs_count=closed_prs,
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
        style_guide_type=style_guide,
        license_type=license_type,
        all_contributors_list=all_contributors_str,
        contributors_count=contributors_count,
        bot_contributors_count=bot_count,
        avg_pr_merge_days=pr_metrics.avg_merge_days,
        days_since_last_activity=activity.days_since_activity,
    )
end

function run_audit_packages()
    targets = CSV.read(PACKAGES_INPUT, DataFrame)
    println("Auditing $(nrow(targets)) packages..\n")

    registry_set = Set{String}()
    if isfile(REGISTRY_PACKAGES)
        registry_df = CSV.read(REGISTRY_PACKAGES, DataFrame)
        for pkg in registry_df.package_name
            push!(registry_set, pkg)
            push!(registry_set, replace(pkg, ".jl" => ""))
        end
        println("Loaded $(length(registry_set)) registry package entries")
    else
        println("Warning: registry_packages.csv not found")
    end

    results = []
    for (idx, row) in enumerate(eachrow(targets))
        try
            println("[$(idx)/$(nrow(targets))] Auditing: $(row.package_name)")
            result = audit_package(row, registry_set)
            if !isnothing(result)
                push!(results, result)
            end
        catch e
            println("Error: $(e)")
        end
    end

    isempty(results) && error("No packages audited successfully")

    audit_df = DataFrame(results)
    mkpath(dirname(AUDIT_PACKAGES_OUTPUT))
    CSV.write(AUDIT_PACKAGES_OUTPUT, audit_df)

    println("\nDone. Audited $(nrow(audit_df)) packages")
    println("Saved to: $AUDIT_PACKAGES_OUTPUT")
end

run_audit_packages()
