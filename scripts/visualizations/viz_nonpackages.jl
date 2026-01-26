# scripts/viz_nonpackages.jl

# Progress tracking
viz_counter = Ref(0)
function print_progress(name::String)
    viz_counter[] += 1
    println("[$(viz_counter[])] Generating: $name")
end

# ALL NON-PACKAGES BY STARS (sorted highest on top)
print_progress("All Non-Packages by Stars")
all_np_stars = sort(nonpackages_df, :stars; rev=true)[:, [:repo_name, :stars]]
save("data/visualizations/nonpackages_all_stars.png")(
    @vlplot(
        :bar,
        x=:stars,
        y={:repo_name, sort="-x"},
        color=:stars,
        width=700,
        height={step=18},
        title="Non-Packages by GitHub Stars"
    )(
        all_np_stars
    ),
)

# ALL NON-PACKAGES BY CONTRIBUTORS (sorted highest on top)
print_progress("All Non-Packages by Contributors")
all_np_contrib = sort(nonpackages_df, :human_contributors_count; rev=true)[
    :, [:repo_name, :human_contributors_count]
]
save("data/visualizations/nonpackages_all_contributors.png")(
    @vlplot(
        :bar,
        x=:human_contributors_count,
        y={:repo_name, sort="-x"},
        color=:human_contributors_count,
        width=700,
        height={step=18},
        title="Non-Packages by Contributors"
    )(
        all_np_contrib
    ),
)

# CI/CD ADOPTION (Non-Packages)
print_progress("Non-Packages CI/CD Adoption")
ci_with = sum(nonpackages_df.has_ci_workflow)
ci_without = nrow(nonpackages_df) - ci_with
np_ci = DataFrame(
    status=["With CI/CD", "Without CI/CD"],
    count=[ci_with, ci_without]
)
np_ci.percent = round.(100 .* np_ci.count ./ nrow(nonpackages_df); digits=1)
np_ci.label = np_ci.status .* " (" .* string.(np_ci.percent) .* "%)"

save("data/visualizations/nonpackages_ci_adoption.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=320,
        height=320,
        title="Non-Packages CI/CD Adoption"
    )(
        np_ci
    ),
)

# LICENSE STATUS (Non-Packages)
print_progress("Non-Packages License Status")
license_with = sum(nonpackages_df.has_license)
license_without = nrow(nonpackages_df) - license_with
np_license = DataFrame(
    status=["Has License", "No License"],
    count=[license_with, license_without]
)
np_license.percent = round.(100 .* np_license.count ./ nrow(nonpackages_df); digits=1)
np_license.label = np_license.status .* " (" .* string.(np_license.percent) .* "%)"

save("data/visualizations/nonpackages_license_status.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=320,
        height=320,
        title="Non-Packages License Adoption"
    )(
        np_license
    ),
)

# OPEN ISSUES vs CLOSED ISSUES (Non-Packages)
print_progress("Non-Packages Open vs Closed Issues")
np_top_issues = sort(nonpackages_df, :open_issues_count; rev=true)[
    :, [:repo_name, :open_issues_count, :closed_issues_count]
]

# Manually reshape for issues
np_issues_long = DataFrame()
for row in eachrow(np_top_issues)
    push!(
        np_issues_long,
        (repo_name=row.repo_name, status="Open", count=row.open_issues_count),
    )
    push!(
        np_issues_long,
        (repo_name=row.repo_name, status="Closed", count=row.closed_issues_count),
    )
end
save("data/visualizations/nonpackages_issues_comparison.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:repo_name, sort="-x"},
        color=:status,
        width=750,
        height={step=18},
        title="Non-Packages: Open vs Closed Issues"
    )(
        np_issues_long
    ),
)

# OPEN PRS vs CLOSED PRS (Non-Packages)
print_progress("Non-Packages Open vs Closed PRs")
np_top_prs = sort(nonpackages_df, :open_prs_count; rev=true)[
    :, [:repo_name, :open_prs_count, :closed_prs_count]
]

# Manually reshape for PRs
np_prs_long = DataFrame()
for row in eachrow(np_top_prs)
    push!(np_prs_long, (repo_name=row.repo_name, status="Open", count=row.open_prs_count))
    push!(
        np_prs_long, (repo_name=row.repo_name, status="Closed", count=row.closed_prs_count)
    )
end
save("data/visualizations/nonpackages_prs_comparison.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:repo_name, sort="-x"},
        color=:status,
        width=750,
        height={step=18},
        title="Non-Packages: Open vs Closed PRs"
    )(
        np_prs_long
    ),
)

# LICENSE PRESENCE PERCENTAGE FOR NON-PACKAGES
print_progress("Non-Package License Presence Percentage")
np_license_present_count = sum(nonpackages_df.has_license)
np_license_absent_count = nrow(nonpackages_df) - np_license_present_count
np_license_percent = round(100 * np_license_present_count / nrow(nonpackages_df); digits=1)

np_license_presence_df = DataFrame(
    status=["Licensed", "No License"],
    count=[np_license_present_count, np_license_absent_count],
    percent=[np_license_percent, 100.0 - np_license_percent]
)

save("data/visualizations/nonpackages_license_presence.png")(
    @vlplot(
        :bar,
        x={:percent, title="Percentage of Non-Packages (%)"},
        y={:status, sort="-x"},
        color={:status, scale={scheme="greens"}, legend={disable=true}},
        width=600,
        height=150,
        title="Non-Package License Presence: $np_license_percent% have licenses"
    )(
        np_license_presence_df
    ),
)

# LICENSE TYPE DISTRIBUTION FOR NON-PACKAGES
print_progress("Non-Package License Type Distribution")
np_license_counts = combine(groupby(nonpackages_df, :license_type), nrow => :count)
sort!(np_license_counts, :count; rev=true)

# Calculate percentages
np_license_counts.percent = round.(100 * np_license_counts.count / sum(np_license_counts.count); digits=1)
np_license_counts.label = np_license_counts.license_type .* " (" .* string.(np_license_counts.percent) .* "%)"

save("data/visualizations/nonpackages_license_types.png")(
    @vlplot(
        :bar,
        x={:percent, title="Percentage of Non-Packages (%)"},
        y={:label, sort="-x"},
        color={:license_type, scale={scheme="set2"}, legend={title="License Type"}},
        width=600,
        height={step=18},
        title="License Type Distribution Across Non-Packages"
    )(
        np_license_counts
    ),
)

# MAINTAINERS vs ACTIVE MAINTAINERS (Non-Packages)
print_progress("Non-Packages Maintainers vs Active Maintainers")
np_top_maintainers = sort(nonpackages_df, :maintainers_count; rev=true)[
    :, [:repo_name, :maintainers_count, :active_maintainers_count]
]

np_maintainers_long = DataFrame()
for row in eachrow(np_top_maintainers)
    push!(
        np_maintainers_long,
        (repo_name=row.repo_name, status="All Maintainers", count=row.maintainers_count),
    )
    push!(
        np_maintainers_long,
        (repo_name=row.repo_name, status="Active (6mo)", count=row.active_maintainers_count),
    )
end
save("data/visualizations/nonpackages_maintainers_comparison.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:repo_name, sort="-x"},
        color=:status,
        width=750,
        height={step=18},
        title="Non-Packages: All Maintainers vs Active Maintainers"
    )(
        np_maintainers_long
    ),
)

# MAINTENANCE STATUS DISTRIBUTION (Non-Packages)
print_progress("Non-Packages Maintenance Status Distribution")
np_status_counts = combine(groupby(nonpackages_df, :maintenance_status), nrow => :count)

save("data/visualizations/nonpackages_maintenance_status.png")(
    @vlplot(
        :bar,
        x={:count, axis={title="Number of Non-Packages"}},
        y={:maintenance_status, sort="-x"},
        color={value="#ff7f0e"},
        width=700,
        height=250,
        title="Non-Packages Maintenance Status Distribution"
    )(
        np_status_counts
    ),
)

println("\nNon-package visualizations complete!")
