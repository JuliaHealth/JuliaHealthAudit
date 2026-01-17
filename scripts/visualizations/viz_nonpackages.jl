# scripts/viz_nonpackages.jl
# Generate all non-package audit visualizations

# 1. ALL NON-PACKAGES BY STARS (sorted highest on top)
println("\n[1/15] Generating: All Non-Packages by Stars")
all_np_stars = sort(nonpackages_df, :stars, rev=true)[:, [:repo_name, :stars]]
all_np_stars |>
@vlplot(
    :bar,
    x=:stars,
    y={:repo_name, sort="-x"},
    color=:stars,
    width=700,
    height={step=18},
    title="All Non-Packages by GitHub Stars",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:stars, type="quantitative"}]
) |>
save("data/visualizations/18_nonpackages_all_stars.png")

# 2. ALL NON-PACKAGES BY CONTRIBUTORS (sorted highest on top)
println("[2/15] Generating: All Non-Packages by Contributors")
all_np_contrib = sort(nonpackages_df, :contributors_count, rev=true)[:, [:repo_name, :contributors_count]]
all_np_contrib |>
@vlplot(
    :bar,
    x=:contributors_count,
    y={:repo_name, sort="-x"},
    color=:contributors_count,
    width=700,
    height={step=18},
    title="All Non-Packages by Contributors",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:contributors_count, type="quantitative"}]
) |>
save("data/visualizations/19_nonpackages_all_contributors.png")

# 3. ARCHIVE STATUS (Non-Packages)
println("[3/15] Generating: Non-Packages Archive Status")
np_archive = DataFrame(
    status=["Active", "Archived"],
    count=[
        nrow(nonpackages_df) - sum(nonpackages_df.is_archived),
        sum(nonpackages_df.is_archived),
    ],
)
np_archive |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="Non-Packages Archive Status",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/20_nonpackages_archive_status.png")

# 4. CI/CD ADOPTION (Non-Packages)
println("[4/15] Generating: Non-Packages CI/CD Adoption")
np_ci = DataFrame(
    status=["With CI/CD", "Without CI/CD"],
    count=[
        sum(nonpackages_df.has_ci_workflow),
        nrow(nonpackages_df) - sum(nonpackages_df.has_ci_workflow),
    ],
)
np_ci |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="Non-Packages CI/CD Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/21_nonpackages_ci_adoption.png")

# 5. LICENSE STATUS (Non-Packages)
println("[5/15] Generating: Non-Packages License Status")
np_license = DataFrame(
    status=["Has License", "No License"],
    count=[
        sum(nonpackages_df.has_license),
        nrow(nonpackages_df) - sum(nonpackages_df.has_license),
    ],
)
np_license |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="Non-Packages License Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/22_nonpackages_license_status.png")

# 6. ISSUE RESOLUTION RATES (Non-Packages)
println("[6/12] Generating: Non-Packages Issue Resolution Rates")
np_issues = sort(nonpackages_df, :issue_resolution_rate, rev=true)[:, [:repo_name, :issue_resolution_rate]]
np_issues |>
@vlplot(
    :bar,
    x=:issue_resolution_rate,
    y={:repo_name, sort="-x"},
    color=:issue_resolution_rate,
    width=700,
    height={step=18},
    title="Non-Packages: Issue Resolution Rates (%)",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:issue_resolution_rate, type="quantitative"}]
) |>
save("data/visualizations/23_nonpackages_issue_resolution.png")

# 7. PR RESOLUTION RATES (Non-Packages)
println("[7/12] Generating: Non-Packages PR Resolution Rates")
np_prs = sort(nonpackages_df, :pr_resolution_rate, rev=true)[:, [:repo_name, :pr_resolution_rate]]
np_prs |>
@vlplot(
    :bar,
    x=:pr_resolution_rate,
    y={:repo_name, sort="-x"},
    color=:pr_resolution_rate,
    width=700,
    height={step=18},
    title="Non-Packages: PR Resolution Rates (%)",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:pr_resolution_rate, type="quantitative"}]
) |>
save("data/visualizations/24_nonpackages_pr_resolution.png")

# 8. OPEN ISSUES vs CLOSED ISSUES (Non-Packages)
println("[8/12] Generating: Non-Packages Open vs Closed Issues")
np_top_issues = sort(nonpackages_df, :open_issues_count, rev=true)[:, [:repo_name, :open_issues_count, :closed_issues_count]]

# Manually reshape for issues
np_issues_long = DataFrame()
for row in eachrow(np_top_issues)
    push!(np_issues_long, (repo_name=row.repo_name, status="Open", count=row.open_issues_count))
    push!(np_issues_long, (repo_name=row.repo_name, status="Closed", count=row.closed_issues_count))
end
np_issues_long |>
@vlplot(
    :bar,
    x=:count,
    y={:repo_name, sort="-x"},
    color=:status,
    width=750,
    height={step=18},
    title="Non-Packages: Open vs Closed Issues",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/25_nonpackages_issues_comparison.png")

# 9. OPEN PRS vs CLOSED PRS (Non-Packages)
println("[9/12] Generating: Non-Packages Open vs Closed PRs")
np_top_prs = sort(nonpackages_df, :open_prs_count, rev=true)[:, [:repo_name, :open_prs_count, :closed_prs_count]]

# Manually reshape for PRs
np_prs_long = DataFrame()
for row in eachrow(np_top_prs)
    push!(np_prs_long, (repo_name=row.repo_name, status="Open", count=row.open_prs_count))
    push!(np_prs_long, (repo_name=row.repo_name, status="Closed", count=row.closed_prs_count))
end
np_prs_long |>
@vlplot(
    :bar,
    x=:count,
    y={:repo_name, sort="-x"},
    color=:status,
    width=750,
    height={step=18},
    title="Non-Packages: Open vs Closed PRs",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/26_nonpackages_prs_comparison.png")

println("\nAll non-package & comparison visualizations generated!")
