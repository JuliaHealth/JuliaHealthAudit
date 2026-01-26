# scripts/viz_packages.jl

using DataFrames
using VegaLite
using Dates

# Progress tracking
viz_counter = Ref(0)
function print_progress(name::String)
    viz_counter[] += 1
    println("[$(viz_counter[])] Generating: $name")
end

# STANDARDS COMPLIANCE - Which packages have which features
print_progress("Standards Compliance Heatmap")
compliance_cols = [
    :has_src_dir,
    :has_test_dir,
    :has_project_toml,
    :has_license,
    :follows_standard_layout,
    :has_docs_dir,
    :has_ci_workflow,
    :has_code_coverage,
    :has_contributing_md,
    :has_code_of_conduct,
]
compliance_df = packages_df[:, [:package_name; compliance_cols]]

compliance_long = DataFrame()
for pkg in compliance_df.package_name
    for col in compliance_cols
        push!(
            compliance_long,
            (
                package_name=pkg,
                standard=col,
                present=compliance_df[compliance_df.package_name .== pkg, col][1],
            ),
        )
    end
end
compliance_long.present_int = Int.(compliance_long.present)
compliance_long.present_label = ifelse.(compliance_long.present, "Yes", "No")
p1 = @vlplot(
    :rect,
    x=:standard,
    y={:package_name, sort="-x"},
    color="present_label:n",
    width=700,
    height={step=14},
    title="Standards Compliance: All Packages"
)(
    compliance_long
)
save("data/visualizations/packages_standards_compliance.png")(p1)

# STANDARDS COMPLIANCE SUMMARY (percent of packages meeting each standard)
summary_rows = DataFrame(; standard=String[], percent=Float64[], count=Int[])
for col in compliance_cols
    values = packages_df[!, col]
    push!(
        summary_rows,
        (
            standard=String(col),
            percent=100 * sum(values) / length(values),
            count=sum(values),
        ),
    )
end
compliance_summary = sort(summary_rows, :percent; rev=true)
save("data/visualizations/packages_standards_percentages.png")(
    @vlplot(
        :bar,
        x="percent:q",
        y={:standard, sort="-x"},
        width=700,
        height={step=18},
        title="Standards Compliance: Percentage of Packages",
    )(
        compliance_summary
    ),
)

# STYLE GUIDE DISTRIBUTION
print_progress("Style Guide Distribution Pie Chart")
style_counts = combine(groupby(packages_df, :style_guide_type), nrow => :count)
style_counts.percent = round.(
    100 .* style_counts.count ./ sum(style_counts.count); digits=1
)
style_counts.label =
    style_counts.style_guide_type .* " (" .* string.(style_counts.percent) .* "%)"

p2 = @vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=350,
    height=350,
    title="Code Style Guide Adoption"
)(
    style_counts
)
save("data/visualizations/packages_style_guide_distribution.png")(p2)

# TOP 15 BY STARS
print_progress("Top 15 Packages by Stars")
top_stars = sort(packages_df, :stars; rev=true)[1:15, [:package_name, :stars]]
save("data/visualizations/packages_top15_stars.png")(
    @vlplot(
        :bar,
        x="stars:q",
        y={:package_name, sort="-x"},
        width=700,
        height={step=20},
        title="Top 15 Packages by GitHub Stars"
    )(
        top_stars
    ),
)

# TOP 15 BY CONTRIBUTORS
print_progress("Top 15 Packages by Contributors")
top_contrib = sort(packages_df, :human_contributors_count; rev=true)[
    1:15, [:package_name, :human_contributors_count]
]
save("data/visualizations/packages_top15_contributors.png")(
    @vlplot(
        :bar,
        x="human_contributors_count:q",
        y={:package_name, sort="-x"},
        width=700,
        height={step=20},
        title="Top 15 Packages by Contributors"
    )(
        top_contrib
    ),
)

# TOP 15 BY RELEASES
print_progress("Top 15 Packages by Release Count")
top_releases = sort(packages_df, :releases_count; rev=true)[
    1:15, [:package_name, :releases_count]
]
save("data/visualizations/packages_top_releases.png")(
    @vlplot(
        :bar,
        x="releases_count:q",
        y={:package_name, sort="-x"},
        width=700,
        height={step=20},
        title="Top 15 Packages by Release Count"
    )(
        top_releases
    ),
)

# CI/CD ADOPTION (arc chart for better visibility)
print_progress("CI/CD Adoption Arc Chart")
ci_with = sum(packages_df.has_ci_workflow)
ci_without = nrow(packages_df) - ci_with
ci_adoption = DataFrame(
    status=["With CI/CD", "Without CI/CD"],
    count=[ci_with, ci_without]
)
ci_adoption.percent = round.(100 .* ci_adoption.count ./ nrow(packages_df); digits=1)
ci_adoption.label = ci_adoption.status .* " (" .* string.(ci_adoption.percent) .* "%)"

save("data/visualizations/packages_ci_adoption.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=320,
        height=320,
        title="CI/CD Workflow Adoption"
    )(
        ci_adoption
    ),
)

# STARS DISTRIBUTION (histogram)
print_progress("Stars Distribution Histogram")
save("data/visualizations/packages_stars_distribution.png")(
    @vlplot(
        :bar,
        x="stars:q",
        y="count()",
        width=500,
        height=300,
        title="Distribution of GitHub Stars"
    )(
        packages_df
    ),
)

# GITHUB PAGES ADOPTION
gh_with = sum(packages_df.has_gh_pages)
gh_without = nrow(packages_df) - gh_with
gh_pages = DataFrame(
    status=["Has GitHub Pages", "No GitHub Pages"],
    count=[gh_with, gh_without]
)
gh_pages.percent = round.(100 .* gh_pages.count ./ nrow(packages_df); digits=1)
gh_pages.label = gh_pages.status .* " (" .* string.(gh_pages.percent) .* "%)"

save("data/visualizations/packages_github_pages_adoption.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=360,
        height=320,
        title="GitHub Pages Adoption"
    )(
        gh_pages
    ),
)

# CONTRIBUTORS DISTRIBUTION
print_progress("Contributors Distribution Histogram")
save("data/visualizations/packages_contributors_distribution.png")(
    @vlplot(
        :bar,
        x="human_contributors_count:q",
        y="count()",
        width=500,
        height=300,
        title="Distribution of Contributors"
    )(
        packages_df
    ),
)

# RELEASES DISTRIBUTION
print_progress("Releases Distribution Histogram")
save("data/visualizations/packages_releases_distribution.png")(
    @vlplot(
        :bar,
        x="releases_count:q",
        y="count()",
        width=500,
        height=300,
        title="Distribution of Release Counts"
    )(
        packages_df
    ),
)

# ARCHIVE STATUS (arc chart for better visibility)
print_progress("Archive Status Distribution")
archived_count = sum(packages_df.is_archived)
active_count = nrow(packages_df) - archived_count
archive_status = DataFrame(
    status=["Active", "Archived"],
    count=[active_count, archived_count]
)
archive_status.percent = round.(100 .* archive_status.count ./ nrow(packages_df); digits=1)
archive_status.label = archive_status.status .* " (" .* string.(archive_status.percent) .* "%)"

save("data/visualizations/packages_archive_status.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=320,
        height=320,
        title="Package Archive Status"
    )(
        archive_status
    ),
)

# FORK STATUS (arc chart for better visibility)
print_progress("Fork Status Distribution")
fork_count = sum(packages_df.is_fork)
original_count = nrow(packages_df) - fork_count
fork_status = DataFrame(
    status=["Original", "Fork"],
    count=[original_count, fork_count]
)
fork_status.percent = round.(100 .* fork_status.count ./ nrow(packages_df); digits=1)
fork_status.label = fork_status.status .* " (" .* string.(fork_status.percent) .* "%)"

save("data/visualizations/packages_fork_status.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={field=:label, type="nominal"},
        width=320,
        height=320,
        title="Package Fork Status"
    )(
        fork_status
    ),
)

# OPEN ISSUES vs CLOSED ISSUES (Top 15)
print_progress("Open vs Closed Issues Comparison")
top_issues = sort(packages_df, :open_issues_count; rev=true)[
    1:15, [:package_name, :open_issues_count, :closed_issues_count]
]

# Manually reshape for issues
top_issues_long = DataFrame()
for row in eachrow(top_issues)
    push!(
        top_issues_long,
        (package_name=row.package_name, status="Open", count=row.open_issues_count),
    )
    push!(
        top_issues_long,
        (package_name=row.package_name, status="Closed", count=row.closed_issues_count),
    )
end
save("data/visualizations/packages_issues_comparison.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:package_name, sort="-x"},
        color=:status,
        width=750,
        height={step=18},
        title="Top 15 Packages: Open vs Closed Issues"
    )(
        top_issues_long
    ),
)

# OPEN PRS vs CLOSED PRS (Top 15)
print_progress("Open vs Closed PRs Comparison")
top_prs = sort(packages_df, :open_prs_count; rev=true)[
    1:15, [:package_name, :open_prs_count, :closed_prs_count]
]

# Manually reshape for PRs
top_prs_long = DataFrame()
for row in eachrow(top_prs)
    push!(
        top_prs_long,
        (package_name=row.package_name, status="Open", count=row.open_prs_count),
    )
    push!(
        top_prs_long,
        (package_name=row.package_name, status="Closed", count=row.closed_prs_count),
    )
end
save("data/visualizations/packages_prs_comparison.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:package_name, sort="-x"},
        color=:status,
        width=750,
        height={step=18},
        title="Top 15 Packages: Open vs Closed PRs"
    )(
        top_prs_long
    ),
)

# DOCUMENTATION AUDIT: Coverage of documentation features
docs_audit = DataFrame(;
    feature=[
        "Has docs/",
        "Has gh-pages",
        "Uses Documenter",
        "Has CONTRIBUTING.md",
        "Has CODE_OF_CONDUCT.md",
    ],
    count=[
        sum(packages_df.has_docs_dir),
        sum(packages_df.has_gh_pages),
        sum(packages_df.uses_documenter),
        sum(packages_df.has_contributing_md),
        sum(packages_df.has_code_of_conduct),
    ],
)
docs_audit.percent = round.(100 .* docs_audit.count ./ nrow(packages_df); digits=1)

save("data/visualizations/packages_docs_audit_coverage.png")(
    @vlplot(
        :bar,
        x={:percent, axis={title="Coverage (%)"}},
        y={:feature, sort="-x"},
        color={value="#1f77b4"},
        width=600,
        height=250,
        title="Documentation Audit: Feature Coverage Across Packages"
    )(
        docs_audit
    ),
)

# CI/CD STATUS: GitHub Actions adoption and coverage
print_progress("CI/CD Status")
ci_status = DataFrame(;
    feature=["Has CI Workflow", "Has Code Coverage", "Standard Repository Layout"],
    count=[
        sum(packages_df.has_ci_workflow),
        sum(packages_df.has_code_coverage),
        sum(packages_df.follows_standard_layout),
    ],
)
ci_status.percent = round.(100 .* ci_status.count ./ nrow(packages_df); digits=1)

save("data/visualizations/packages_ci_status.png")(
    @vlplot(
        :bar,
        x={:percent, axis={title="Adoption (%)"}},
        y={:feature, sort="-x"},
        color={value="#2ca02c"},
        width=600,
        height=220,
        title="CI/CD Status: Automation & Coverage Adoption"
    )(
        ci_status
    ),
)

print_progress("Registry Adoption Status")
in_registry_count = sum(packages_df.in_general_registry)
not_in_registry_count = nrow(packages_df) - in_registry_count

registry_data = DataFrame(
    category=["In General Registry", "Not in Registry"],
    count=[in_registry_count, not_in_registry_count]
)

registry_data.percent = round.(100 .* registry_data.count ./ nrow(packages_df); digits=1)
registry_data.label =
    registry_data.category .* " (" .* string.(registry_data.percent) .* "%)"

save("data/visualizations/packages_registry_status.png")(
    @vlplot(
        mark={:arc, innerRadius=0},
        theta=:count,
        color={field=:label, type="nominal", scale={scheme="category10"}},
        width=500,
        height=300,
        title="Registry Adoption: Ecosystem Maturity Status"
    )(
        registry_data
    ),
)

# CODE COVERAGE STATUS: Which packages have coverage configured
print_progress("Code Coverage Status")
coverage_with = sum(packages_df.has_code_coverage)
coverage_without = nrow(packages_df) - coverage_with
coverage_status = DataFrame(
    status=["Has Code Coverage", "No Code Coverage"],
    count=[coverage_with, coverage_without]
)

coverage_status.percent = round.(
    100 .* coverage_status.count ./ nrow(packages_df); digits=1
)
coverage_status.label =
    coverage_status.status .* " (" .* string.(coverage_status.percent) .* "%)"

save("data/visualizations/packages_code_coverage.png")(
    @vlplot(
        mark={:arc, innerRadius=0},
        theta=:count,
        color={field=:label, type="nominal", scale={scheme="greens"}},
        width=500,
        height=300,
        title="Code Coverage Status: Testing Infrastructure Adoption"
    )(
        coverage_status
    ),
)

print_progress("Package Maturity Tiers")
packages_df.maturity_tier = map(eachrow(packages_df)) do row
    in_registry = row.in_general_registry
    releases = row.releases_count
    
    if !in_registry
        "Not Registered"
    elseif releases == 0
        "Registered (No Releases)"
    elseif releases >= 20
        "Mature (20+ releases)"
    elseif releases >= 5
        "Stable (5-19 releases)"
    else
        "Early Release (1-4 releases)"
    end
end

maturity_counts = combine(groupby(packages_df, :maturity_tier), nrow => :count)
maturity_order = Dict(
    "Mature (20+ releases)" => 1,
    "Stable (5-19 releases)" => 2,
    "Early Release (1-4 releases)" => 3,
    "Registered (No Releases)" => 4,
    "Not Registered" => 5
)
maturity_counts.sort_order = [get(maturity_order, tier, 99) for tier in maturity_counts.maturity_tier]
sort!(maturity_counts, :sort_order)

save("data/visualizations/packages_maturity_tiers.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:maturity_tier, sort="-x", title="Maturity Tier"},
        color={:maturity_tier, scale={scheme="viridis"}, legend={disable=true}},
        width=600,
        height=250,
        title="Package Maturity Tiers: Ecosystem Distribution"
    )(
        maturity_counts
    ),
)

# README COMPLETENESS SCORE DISTRIBUTION
print_progress("README Completeness Score Distribution")
# readme_completeness_score is on 0-8 scale, show distribution

readme_score_counts = combine(groupby(packages_df, :readme_completeness_score), nrow => :count)
sort!(readme_score_counts, :readme_completeness_score)

save("data/visualizations/packages_readme_completeness.png")(
    @vlplot(
        :bar,
        y={:readme_completeness_score, type="ordinal", title="README Completeness Score (0-8)", sort="ascending", axis={labelAngle=0}},
        x={:count, title="Number of Packages"},
        color={value="#FF8C00"},
        width=720,
        height={step=34},
        mark={type=:bar, size=28},
        title="README Completeness Score Distribution"
    )(
        readme_score_counts
    ),
)

# LICENSE PRESENCE 
print_progress("License Presence Percentage")
license_present_count = sum(packages_df.has_license)
license_absent_count = nrow(packages_df) - license_present_count
license_percent = round(100 * license_present_count / nrow(packages_df); digits=1)

license_presence_df = DataFrame(
    status=["Licensed", "No License"],
    count=[license_present_count, license_absent_count],
    percent=[license_percent, 100.0 - license_percent]
)

save("data/visualizations/packages_license_presence.png")(
    @vlplot(
        :bar,
        x={:percent, title="Percentage of Packages (%)"},
        y={:status, sort="-x"},
        color={:status, scale={scheme="greens"}, legend={disable=true}},
        width=600,
        height=150,
        title="License Presence: $license_percent% of packages have licenses"
    )(
        license_presence_df
    ),
)

# LICENSE TYPE DISTRIBUTION
print_progress("License Type Distribution")
license_counts = combine(groupby(packages_df, :license_type), nrow => :count)
sort!(license_counts, :count; rev=true)

# Calculate percentages
license_counts.percent = round.(100 * license_counts.count / sum(license_counts.count); digits=1)

save("data/visualizations/packages_license_types.png")(
    @vlplot(
        :arc,
        theta=:count,
        color={
            :license_type,
            scale={scheme="category20"},
            legend={title="License Type"}
        },
        width=400,
        height=400,
        title="License Type Distribution Across Packages"
    )(
        license_counts
    ),
)

print_progress("Days Since Last Activity")
activity_data = packages_df[.!ismissing.(packages_df.days_since_last_activity), [:package_name, :days_since_last_activity]]
if nrow(activity_data) > 0
    save("data/visualizations/packages_activity_recency.png")(
        @vlplot(
            :bar,
            x={:days_since_last_activity, title="Days Since Last Activity"},
            y="count()",
            width=600,
            height=300,
            title="Distribution of Activity Recency",
            color={value="#F5A623"}
        )(
            activity_data
        ),
    )
end

# MAINTAINERS vs ACTIVE MAINTAINERS (Top 15)
print_progress("Maintainers vs Active Maintainers Comparison")
top_maintainers = sort(packages_df, :maintainers_count; rev=true)[
    1:15, [:package_name, :maintainers_count, :active_maintainers_count]
]

maintainers_long = DataFrame()
for row in eachrow(top_maintainers)
    push!(
        maintainers_long,
        (package_name=row.package_name, status="All Maintainers", count=row.maintainers_count),
    )
    push!(
        maintainers_long,
        (package_name=row.package_name, status="Active (6mo)", count=row.active_maintainers_count),
    )
end
save("data/visualizations/packages_maintainers_comparison.png")(
    @vlplot(
        :bar,
        x=:count,
        y={:package_name, sort="-x"},
        color=:status,
        width=750,
        height={step=18},
        title="Top 15 Packages: All Maintainers vs Active Maintainers"
    )(
        maintainers_long
    ),
)

# MAINTENANCE STATUS DISTRIBUTION
print_progress("Maintenance Status Distribution")
status_counts = combine(groupby(packages_df, :maintenance_status), nrow => :count)

save("data/visualizations/packages_maintenance_status.png")(
    @vlplot(
        :bar,
        x={:count, axis={title="Number of Packages"}},
        y={:maintenance_status, sort="-x"},
        color={value="#1f77b4"},
        width=700,
        height=250,
        title="Package Maintenance Status Distribution"
    )(
        status_counts
    ),
)

println("\nPackage visualizations complete!")

