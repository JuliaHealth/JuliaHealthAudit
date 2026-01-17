# scripts/audit/02_audit_packages.jl
# Audit Julia packages with 36 metrics via GitHub API

using CSV
using DataFrames

include("../utils.jl")

PACKAGES_INPUT = "data/results/packages.csv"
AUDIT_PACKAGES_OUTPUT = "data/results/audit_packages.csv"

function audit_package(row)
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
    readme_has_code, readme_lines = check_readme_quality(readme_content)

    style_guide = detect_style_guide(owner, repo, tree_paths)

    contributors = get_contributors_count(owner, repo)
    open_issues, open_prs = get_open_issues_count(owner, repo)
    closed_issues = get_closed_issues_count(owner, repo)
    closed_prs = get_closed_prs_count(owner, repo)

    releases_count = get_releases_count(owner, repo)
    latest_release_date = get_latest_release_date(owner, repo)

    follows_standard = has_src_dir && has_test_dir && has_docs_dir && has_project_toml

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

    return (
        # 1. Identity (5)
        package_name=pkg_name,
        github_repo_url=repo_url,
        in_general_registry=row.in_general_registry,
        is_fork=repo_info.is_fork,
        is_archived=repo_info.archived,
        # 2. Repository Structure (5)
        has_src_dir=has_src_dir,
        has_test_dir=has_test_dir,
        has_project_toml=has_project_toml,
        has_license=has_license,
        follows_standard_layout=follows_standard,
        # 3. Documentation (5)
        has_docs_dir=has_docs_dir,
        has_gh_pages=has_gh_pages,
        uses_documenter=uses_documenter,
        has_contributing_md=has_contributing,
        has_code_of_conduct=has_code_of_conduct,
        # 4. CI/Testing (2)
        has_ci_workflow=has_ci,
        has_code_coverage=code_coverage_config,
        # 5. Package Maturity (2)
        releases_count=releases_count,
        latest_release_date=latest_release_date,
        # 6. Activity & Maintenance (9)
        pushed_at=isempty(repo_info.pushed_at) ? missing : repo_info.pushed_at,
        stars=repo_info.stars,
        contributors_count=contributors,
        open_issues_count=open_issues,
        closed_issues_count=closed_issues,
        issue_resolution_rate=issue_resolution_rate,
        open_prs_count=open_prs,
        closed_prs_count=closed_prs,
        pr_resolution_rate=pr_resolution_rate,
        # 7. Code Quality (3)
        readme_has_code_blocks=readme_has_code,
        readme_line_count=readme_lines,
        style_guide_type=style_guide,
    )
end

isfile(PACKAGES_INPUT) ||
    error("$PACKAGES_INPUT not found. Run 01_separate_packages.jl first.")

targets = CSV.read(PACKAGES_INPUT, DataFrame)
println("Auditing $(nrow(targets)) packages...\n")

results = []
for (idx, row) in enumerate(eachrow(targets))
    try
        println("[$(idx)/$(nrow(targets))] Auditing: $(row.package_name)")
        result = audit_package(row)
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
CSV.write(AUDIT_PACKAGES_OUTPUT, audit_df; transform=(col, val) -> something(val, missing))

println("\nDone. Audited $(nrow(audit_df)) packages")
println("Saved to: $AUDIT_PACKAGES_OUTPUT")