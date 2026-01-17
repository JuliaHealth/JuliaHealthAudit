# scripts/viz_nonpackages.jl
# Generate all non-package audit visualizations

# Progress tracking
viz_counter = Ref(0)
function print_progress(name::String)
    viz_counter[] += 1
    println("[$(viz_counter[])] Generating: $name")
end

# ALL NON-PACKAGES BY STARS (sorted highest on top)
print_progress("All Non-Packages by Stars")
all_np_stars = sort(nonpackages_df, :stars, rev=true)[:, [:repo_name, :stars]]
all_np_stars |>
@vlplot(
    :bar,
    x=:stars,
    y={:repo_name, sort="-x"},
    color=:stars,
    width=700,
    height={step=18},
    title="Non-Packages by GitHub Stars",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:stars, type="quantitative"}]
) |>
save("data/visualizations/nonpackages_all_stars.png")

# ALL NON-PACKAGES BY CONTRIBUTORS (sorted highest on top)
print_progress("All Non-Packages by Contributors")
all_np_contrib = sort(nonpackages_df, :contributors_count, rev=true)[:, [:repo_name, :contributors_count]]
all_np_contrib |>
@vlplot(
    :bar,
    x=:contributors_count,
    y={:repo_name, sort="-x"},
    color=:contributors_count,
    width=700,
    height={step=18},
    title="Non-Packages by Contributors",
    tooltip=[{field=:repo_name, type="nominal"}, {field=:contributors_count, type="quantitative"}]
) |>
save("data/visualizations/nonpackages_all_contributors.png")

# CI/CD ADOPTION (Non-Packages)
print_progress("Non-Packages CI/CD Adoption")
np_ci = DataFrame(
    status=["With CI/CD", "Without CI/CD"],
    count=[
        sum(nonpackages_df.has_ci_workflow),
        nrow(nonpackages_df) - sum(nonpackages_df.has_ci_workflow),
    ],
)
np_ci.percent = round.(100 .* np_ci.count ./ sum(np_ci.count); digits=1)
np_ci.label = np_ci.status .* " (" .* string.(np_ci.percent) .* "%)"

np_ci |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=320,
    height=320,
    title="Non-Packages CI/CD Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/nonpackages_ci_adoption.png")

# LICENSE STATUS (Non-Packages)
print_progress("Non-Packages License Status")
np_license = DataFrame(
    status=["Has License", "No License"],
    count=[
        sum(nonpackages_df.has_license),
        nrow(nonpackages_df) - sum(nonpackages_df.has_license),
    ],
)
np_license.percent = round.(100 .* np_license.count ./ sum(np_license.count); digits=1)
np_license.label = np_license.status .* " (" .* string.(np_license.percent) .* "%)"

np_license |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=320,
    height=320,
    title="Non-Packages License Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/nonpackages_license_status.png")

# OPEN ISSUES vs CLOSED ISSUES (Non-Packages)
print_progress("Non-Packages Open vs Closed Issues")
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
save("data/visualizations/nonpackages_issues_comparison.png")

# OPEN PRS vs CLOSED PRS (Non-Packages)
print_progress("Non-Packages Open vs Closed PRs")
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
save("data/visualizations/nonpackages_prs_comparison.png")

println("\nAll non-package visualizations generated!")
