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
        title="Non-Packages by GitHub Stars",
        tooltip=[{field=:repo_name, type="nominal"}, {field=:stars, type="quantitative"}]
    )(
        all_np_stars
    ),
)

# ALL NON-PACKAGES BY CONTRIBUTORS (sorted highest on top)
print_progress("All Non-Packages by Contributors")
all_np_contrib = sort(nonpackages_df, :contributors_count; rev=true)[
    :, [:repo_name, :contributors_count]
]
save("data/visualizations/nonpackages_all_contributors.png")(
    @vlplot(
        :bar,
        x=:contributors_count,
        y={:repo_name, sort="-x"},
        color=:contributors_count,
        width=700,
        height={step=18},
        title="Non-Packages by Contributors",
        tooltip=[
            {field=:repo_name, type="nominal"},
            {field=:contributors_count, type="quantitative"},
        ]
    )(
        all_np_contrib
    ),
)

# CI/CD ADOPTION (Non-Packages)
print_progress("Non-Packages CI/CD Adoption")
ci_with = sum(nonpackages_df.has_ci_workflow)
ci_without = nrow(nonpackages_df) - ci_with
np_ci = DataFrame(; status=["With CI/CD", "Without CI/CD"], count=[ci_with, ci_without])
np_ci.percent = round.(100 .* np_ci.count ./ nrow(nonpackages_df); digits=1)
np_ci.label = np_ci.status .* " (" .* string.(np_ci.percent) .* "%)"

save("data/visualizations/nonpackages_ci_adoption.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=320,
        height=320,
        title="Non-Packages CI/CD Adoption",
        tooltip=[
            {field=:status, type="nominal"},
            {field=:count, type="quantitative"},
            {field=:percent, type="quantitative"},
        ]
    )(
        np_ci
    ),
)

# LICENSE STATUS (Non-Packages)
print_progress("Non-Packages License Status")
license_with = sum(nonpackages_df.has_license)
license_without = nrow(nonpackages_df) - license_with
np_license = DataFrame(;
    status=["Has License", "No License"], count=[license_with, license_without]
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
        title="Non-Packages License Adoption",
        tooltip=[
            {field=:status, type="nominal"},
            {field=:count, type="quantitative"},
            {field=:percent, type="quantitative"},
        ]
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
        title="Non-Packages: Open vs Closed Issues",
        tooltip=[
            {field=:repo_name, type="nominal"},
            {field=:status, type="nominal"},
            {field=:count, type="quantitative"},
        ]
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
        title="Non-Packages: Open vs Closed PRs",
        tooltip=[
            {field=:repo_name, type="nominal"},
            {field=:status, type="nominal"},
            {field=:count, type="quantitative"},
        ]
    )(
        np_prs_long
    ),
)

# LICENSE PRESENCE PERCENTAGE FOR NON-PACKAGES
print_progress("Non-Package License Presence Percentage")
np_license_present_count = sum(nonpackages_df.has_license)
np_license_absent_count = nrow(nonpackages_df) - np_license_present_count
np_license_percent = round(100 * np_license_present_count / nrow(nonpackages_df); digits=1)

np_license_presence_df = DataFrame(;
    status=["Licensed", "No License"],
    count=[np_license_present_count, np_license_absent_count],
    percent=[np_license_percent, 100.0 - np_license_percent],
)

save("data/visualizations/nonpackages_license_presence.png")(
    @vlplot(
        :bar,
        x={:percent, title="Percentage of Non-Packages (%)"},
        y={:status, sort="-x"},
        color={:status, scale={scheme="greens"}, legend={disable=true}},
        width=600,
        height=150,
        title="Non-Package License Presence: $np_license_percent% have licenses",
        tooltip=[
            {field=:status, type="nominal"},
            {field=:count, type="quantitative"},
            {field=:percent, type="quantitative", format=".1f"},
        ]
    )(
        np_license_presence_df
    ),
)

# LICENSE TYPE DISTRIBUTION FOR NON-PACKAGES
print_progress("Non-Package License Type Distribution")
np_license_counts = combine(groupby(nonpackages_df, :license_type), nrow => :count)
sort!(np_license_counts, :count; rev=true)

# Calculate percentages
np_license_counts.percent = round.(
    100 * np_license_counts.count / sum(np_license_counts.count); digits=1
)
np_license_counts.label =
    np_license_counts.license_type .* " (" .* string.(np_license_counts.percent) .* "%)"

save("data/visualizations/nonpackages_license_types.png")(
    @vlplot(
        :bar,
        x={:percent, title="Percentage of Non-Packages (%)"},
        y={:label, sort="-x"},
        color={:license_type, scale={scheme="set2"}, legend={title="License Type"}},
        width=600,
        height={step=18},
        title="License Type Distribution Across Non-Packages",
        tooltip=[
            {field=:license_type, type="nominal", title="License"},
            {field=:count, type="quantitative", title="Count"},
            {field=:percent, type="quantitative", title="Percentage (%)", format=".1f"},
        ]
    )(
        np_license_counts
    ),
)

