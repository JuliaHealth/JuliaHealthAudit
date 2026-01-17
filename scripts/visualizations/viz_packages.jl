# scripts/viz_packages.jl
# Generate all package audit visualizations

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
compliance_df = packages_df[
    :,
    [:package_name; compliance_cols],
]

# Manually reshape: create long format
compliance_long = DataFrame()
for pkg in compliance_df.package_name
    for col in compliance_cols
        push!(compliance_long, (package_name=pkg, standard=col, present=compliance_df[compliance_df.package_name .== pkg, col][1]))
    end
end
compliance_long.present_int = Int.(compliance_long.present)
compliance_long.present_label = ifelse.(compliance_long.present, "Yes", "No")
p1 = compliance_long |>
@vlplot(
    :rect,
    x=:standard,
    y={:package_name, sort="-x"},
    color="present_label:n",
    width=700,
    height={step=14},
    title="Standards Compliance: All Packages"
)
p1 |> save("data/visualizations/packages_standards_compliance.png")

# STANDARDS COMPLIANCE SUMMARY (percent of packages meeting each standard)
summary_rows = DataFrame(standard=String[], percent=Float64[], count=Int[])
for col in compliance_cols
    values = packages_df[!, col]
    push!(summary_rows, (standard=String(col), percent=100 * sum(values) / length(values), count=sum(values)))
end
compliance_summary = sort(summary_rows, :percent, rev=true)
compliance_summary |>
@vlplot(
    :bar,
    x="percent:q",
    y={:standard, sort="-x"},
    width=700,
    height={step=18},
    title="Standards Compliance: Percentage of Packages",
    tooltip=[{field=:standard, type="nominal"}, {field=:percent, type="quantitative", format=".1f"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/packages_standards_percentages.png")

# STYLE GUIDE DISTRIBUTION
print_progress("Style Guide Distribution Pie Chart")
style_counts = combine(
    groupby(packages_df, :style_guide_type),
    nrow => :count
)
style_counts.percent = round.(100 .* style_counts.count ./ sum(style_counts.count); digits=1)
style_counts.label = style_counts.style_guide_type .* " (" .* string.(style_counts.percent) .* "%)"

p2 = style_counts |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=350,
    height=350,
    title="Code Style Guide Adoption",
    tooltip=[{field=:style_guide_type, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
)
p2 |> save("data/visualizations/packages_style_guide_distribution.png")

# TOP 15 BY STARS
print_progress("Top 15 Packages by Stars")
top_stars = sort(packages_df, :stars, rev=true)[1:15, [:package_name, :stars]]
top_stars |>
@vlplot(
    :bar,
    x="stars:q",
    y={:package_name, sort="-x"},
    width=700,
    height={step=20},
    title="Top 15 Packages by GitHub Stars",
    tooltip=[{field=:package_name, type="nominal"}, {field=:stars, type="quantitative"}]
) |>
save("data/visualizations/packages_top15_stars.png")

# TOP 15 BY CONTRIBUTORS
print_progress("Top 15 Packages by Contributors")
top_contrib = sort(packages_df, :contributors_count, rev=true)[1:15, [:package_name, :contributors_count]]
top_contrib |>
@vlplot(
    :bar,
    x="contributors_count:q",
    y={:package_name, sort="-x"},
    width=700,
    height={step=20},
    title="Top 15 Packages by Contributors",
    tooltip=[{field=:package_name, type="nominal"}, {field=:contributors_count, type="quantitative"}]
) |>
save("data/visualizations/packages_top15_contributors.png")

# TOP 15 BY RELEASES
print_progress("Top 15 Packages by Release Count")
top_releases = sort(packages_df, :releases_count, rev=true)[1:15, [:package_name, :releases_count]]
top_releases |>
@vlplot(
    :bar,
    x="releases_count:q",
    y={:package_name, sort="-x"},
    width=700,
    height={step=20},
    title="Top 15 Packages by Release Count",
    tooltip=[{field=:package_name, type="nominal"}, {field=:releases_count, type="quantitative"}]
) |>
save("data/visualizations/packages_top_releases.png")

# DOCUMENTATION ADOPTION (multiple metrics)
print_progress("Documentation Adoption Comparison")
doc_metrics = DataFrame(
    metric=["Has Docs Dir", "Uses Documenter", "Has GH Pages", "README w/ Code", "Has Contributing"],
    adoption_rate=[
        sum(packages_df.has_docs_dir) / nrow(packages_df) * 100,
        sum(packages_df.uses_documenter) / nrow(packages_df) * 100,
        sum(packages_df.has_gh_pages) / nrow(packages_df) * 100,
        sum(packages_df.readme_has_code_blocks) / nrow(packages_df) * 100,
        sum(packages_df.has_contributing_md) / nrow(packages_df) * 100,
    ],
)
doc_metrics |>
@vlplot(
    :bar,
    x=:adoption_rate,
    y=:metric,
    color=:metric,
    width=500,
    height=250,
    title="Documentation Standards Adoption (%)"
) |>
save("data/visualizations/packages_docs_audit_coverage.png")

# CI/CD ADOPTION (arc chart for better visibility)
print_progress("CI/CD Adoption Arc Chart")
ci_adoption = DataFrame(
    status=["With CI/CD", "Without CI/CD"],
    count=[
        sum(packages_df.has_ci_workflow),
        nrow(packages_df) - sum(packages_df.has_ci_workflow),
    ],
)
ci_adoption.percent = round.(100 .* ci_adoption.count ./ sum(ci_adoption.count); digits=1)
ci_adoption.label = ci_adoption.status .* " (" .* string.(ci_adoption.percent) .* "%)"

ci_adoption |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=320,
    height=320,
    title="CI/CD Workflow Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_ci_adoption.png")

# REGISTRY ADOPTION (arc chart for better visibility)
print_progress("Registry Adoption Distribution")
registry_adoption = DataFrame(
    status=["In General Registry", "Not in Registry"],
    count=[
        sum(packages_df.in_general_registry),
        nrow(packages_df) - sum(packages_df.in_general_registry),
    ],
)
registry_adoption.percent = round.(100 .* registry_adoption.count ./ sum(registry_adoption.count); digits=1)
registry_adoption.label = registry_adoption.status .* " (" .* string.(registry_adoption.percent) .* "%)"

registry_adoption |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=320,
    height=320,
    title="General Registry Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_registry_status.png")

# STARS DISTRIBUTION (histogram)
print_progress("Stars Distribution Histogram")
packages_df |>
@vlplot(
    :bar,
    x="stars:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of GitHub Stars"
) |>
save("data/visualizations/packages_stars_distribution.png")

# README QUALITY (line count distribution)
print_progress("README Quality (Line Count Distribution)")
packages_df |>
@vlplot(
    :bar,
    x="readme_line_count:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of README Line Counts"
) |>
save("data/visualizations/packages_readme_quality.png")

# GITHUB PAGES ADOPTION
gh_pages = DataFrame(
    status=["Has GitHub Pages", "No GitHub Pages"],
    count=[
        sum(packages_df.has_gh_pages),
        nrow(packages_df) - sum(packages_df.has_gh_pages),
    ],
)
gh_pages.percent = round.(100 .* gh_pages.count ./ sum(gh_pages.count); digits=1)
gh_pages.label = gh_pages.status .* " (" .* string.(gh_pages.percent) .* "%)"

gh_pages |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=360,
    height=320,
    title="GitHub Pages Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_github_pages_adoption.png")

# CONTRIBUTORS DISTRIBUTION
print_progress("Contributors Distribution Histogram")
packages_df |>
@vlplot(
    :bar,
    x="contributors_count:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of Contributors"
) |>
save("data/visualizations/packages_contributors_distribution.png")

# RELEASES DISTRIBUTION
print_progress("Releases Distribution Histogram")
packages_df |>
@vlplot(
    :bar,
    x="releases_count:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of Release Counts"
) |>
save("data/visualizations/packages_releases_distribution.png")

# ARCHIVE STATUS (arc chart for better visibility)
print_progress("Archive Status Distribution")
archive_status = DataFrame(
    status=["Active", "Archived"],
    count=[
        nrow(packages_df) - sum(packages_df.is_archived),
        sum(packages_df.is_archived),
    ],
)
archive_status.percent = round.(100 .* archive_status.count ./ sum(archive_status.count); digits=1)
archive_status.label = archive_status.status .* " (" .* string.(archive_status.percent) .* "%)"

archive_status |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=320,
    height=320,
    title="Package Archive Status",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_archive_status.png")

# FORK STATUS (arc chart for better visibility)
print_progress("Fork Status Distribution")
fork_status = DataFrame(
    status=["Original", "Fork"],
    count=[
        nrow(packages_df) - sum(packages_df.is_fork),
        sum(packages_df.is_fork),
    ],
)
fork_status.percent = round.(100 .* fork_status.count ./ sum(fork_status.count); digits=1)
fork_status.label = fork_status.status .* " (" .* string.(fork_status.percent) .* "%)"

fork_status |>
@vlplot(
    :arc,
    theta=:count,
    color={field=:label, type="nominal"},
    width=320,
    height=320,
    title="Package Fork Status",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_fork_status.png")

# OPEN ISSUES vs CLOSED ISSUES (Top 15)
print_progress("Open vs Closed Issues Comparison")
top_issues = sort(packages_df, :open_issues_count, rev=true)[1:15, [:package_name, :open_issues_count, :closed_issues_count]]

# Manually reshape for issues
top_issues_long = DataFrame()
for row in eachrow(top_issues)
    push!(top_issues_long, (package_name=row.package_name, status="Open", count=row.open_issues_count))
    push!(top_issues_long, (package_name=row.package_name, status="Closed", count=row.closed_issues_count))
end
top_issues_long |>
@vlplot(
    :bar,
    x=:count,
    y={:package_name, sort="-x"},
    color=:status,
    width=750,
    height={step=18},
    title="Top 15 Packages: Open vs Closed Issues",
    tooltip=[{field=:package_name, type="nominal"}, {field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/packages_issues_comparison.png")

# OPEN PRS vs CLOSED PRS (Top 15)
print_progress("Open vs Closed PRs Comparison")
top_prs = sort(packages_df, :open_prs_count, rev=true)[1:15, [:package_name, :open_prs_count, :closed_prs_count]]

# Manually reshape for PRs
top_prs_long = DataFrame()
for row in eachrow(top_prs)
    push!(top_prs_long, (package_name=row.package_name, status="Open", count=row.open_prs_count))
    push!(top_prs_long, (package_name=row.package_name, status="Closed", count=row.closed_prs_count))
end
top_prs_long |>
@vlplot(
    :bar,
    x=:count,
    y={:package_name, sort="-x"},
    color=:status,
    width=750,
    height={step=18},
    title="Top 15 Packages: Open vs Closed PRs",
    tooltip=[{field=:package_name, type="nominal"}, {field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/packages_prs_comparison.png")

# DOCUMENTATION AUDIT: Coverage of documentation features
docs_audit = DataFrame(
    feature=["Has docs/", "Has gh-pages", "Uses Documenter", "Has CONTRIBUTING.md", "Has CODE_OF_CONDUCT.md"],
    count=[
        sum(packages_df.has_docs_dir),
        sum(packages_df.has_gh_pages),
        sum(packages_df.uses_documenter),
        sum(packages_df.has_contributing_md),
        sum(packages_df.has_code_of_conduct)
    ]
)
docs_audit.percent = round.(100 .* docs_audit.count ./ nrow(packages_df); digits=1)

docs_audit |>
@vlplot(
    :bar,
    x={:percent, axis={title="Coverage (%)"}},
    y={:feature, sort="-x"},
    color={value="#1f77b4"},
    width=600,
    height=250,
    title="Documentation Audit: Feature Coverage Across Packages",
    tooltip=[{field=:feature, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_docs_audit_coverage.png")

# CI/CD STATUS: GitHub Actions adoption and coverage
print_progress("CI/CD Status")
ci_status = DataFrame(
    feature=["Has CI Workflow", "Has Code Coverage", "Standard Repository Layout"],
    count=[
        sum(packages_df.has_ci_workflow),
        sum(packages_df.has_code_coverage),
        sum(packages_df.follows_standard_layout)
    ]
)
ci_status.percent = round.(100 .* ci_status.count ./ nrow(packages_df); digits=1)

ci_status |>
@vlplot(
    :bar,
    x={:percent, axis={title="Adoption (%)"}},
    y={:feature, sort="-x"},
    color={value="#2ca02c"},
    width=600,
    height=220,
    title="CI/CD Status: Automation & Coverage Adoption",
    tooltip=[{field=:feature, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_ci_status.png")

# MAINTENANCE HEALTH: Active vs Maintenance vs Inactive
activity_threshold_days = 180
current_date = now(UTC)

# Try parsing dates - handle both ISO 8601 and other formats
function safe_parse_datetime(date_str)
    isempty(date_str) && return nothing
    ismissing(date_str) && return nothing
    try
        # Try ISO 8601 format first (e.g., "2025-01-17T10:30:45Z")
        return DateTime(date_str[1:end-1])  # Remove Z
    catch
        try
            return DateTime(date_str)
        catch
            return nothing
        end
    end
end

packages_df.pushed_at_parsed = safe_parse_datetime.(packages_df.pushed_at)

# Calculate days since push
packages_df.days_since_push = [
    if isnothing(dt)
        missing
    else
        try
            days = Dates.value(current_date - dt) / (1000 * 60 * 60 * 24)
            days >= 0 ? days : missing
        catch
            missing
        end
    end
    for dt in packages_df.pushed_at_parsed
]

# Count valid dates for each category
valid_dates = .!ismissing.(packages_df.days_since_push)
active_count = sum((packages_df.days_since_push .< activity_threshold_days) .& valid_dates)
maintenance_count = sum(((packages_df.days_since_push .>= activity_threshold_days) .& (packages_df.days_since_push .< 365)) .& valid_dates)
inactive_count = sum((packages_df.days_since_push .>= 365) .& valid_dates)
unknown_count = sum(.!valid_dates)

maintenance_status = DataFrame(
    status=String[],
    count=Int[]
)
push!(maintenance_status, (status="Active (< 180 days)", count=active_count))
push!(maintenance_status, (status="Maintenance (180-365 days)", count=maintenance_count))
push!(maintenance_status, (status="Inactive (> 365 days)", count=inactive_count))
if unknown_count > 0
    push!(maintenance_status, (status="Unknown", count=unknown_count))
end

maintenance_status |>
@vlplot(
    :bar,
    x=:count,
    y={:status, sort="-x"},
    color={:status, scale={scheme="set2"}, legend={disable=true}},
    width=600,
    height=200,
    title="Maintenance Health: Active vs Maintenance vs Inactive Packages",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/packages_maintenance_health.png")

# REGISTRY ADOPTION: Ecosystem maturity
print_progress("Registry Adoption Status")
registry_data = DataFrame(
    category=String[],
    count=Int[]
)
push!(registry_data, (category="In General Registry", count=sum(packages_df.in_general_registry)))
push!(registry_data, (category="Not in Registry", count=sum(.!packages_df.in_general_registry)))

registry_data.percent = round.(100 .* registry_data.count ./ nrow(packages_df); digits=1)
registry_data.label = registry_data.category .* " (" .* string.(registry_data.percent) .* "%)"

registry_data |>
@vlplot(
    mark={:arc, innerRadius=0},
    theta=:count,
    color={field=:label, type="nominal", scale={scheme="category10"}},
    width=500,
    height=300,
    title="Registry Adoption: Ecosystem Maturity Status",
    tooltip=[{field=:category, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_registry_status.png")

# CODE COVERAGE STATUS: Which packages have coverage configured
print_progress("Code Coverage Status")
coverage_status = DataFrame(
    status=String[],
    count=Int[]
)
push!(coverage_status, (status="Has Code Coverage", count=sum(packages_df.has_code_coverage)))
push!(coverage_status, (status="No Code Coverage", count=nrow(packages_df) - sum(packages_df.has_code_coverage)))

coverage_status.percent = round.(100 .* coverage_status.count ./ nrow(packages_df); digits=1)
coverage_status.label = coverage_status.status .* " (" .* string.(coverage_status.percent) .* "%)"

coverage_status |>
@vlplot(
    mark={:arc, innerRadius=0},
    theta=:count,
    color={field=:label, type="nominal", scale={scheme="greens"}},
    width=500,
    height=300,
    title="Code Coverage Status: Testing Infrastructure Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_code_coverage.png")

# PACKAGE MATURITY TIERS: Stable vs Developing vs Early
print_progress("Package Maturity Tiers")
packages_df.maturity_tier = map(eachrow(packages_df)) do row
    in_registry = row.in_general_registry
    releases = row.releases_count
    
    if !in_registry
        "Early"
    elseif releases >= 10
        "Stable"
    elseif releases >= 1
        "Developing"
    else
        "Early"
    end
end

maturity_counts = combine(
    groupby(packages_df, :maturity_tier),
    nrow => :count
)

# Order by count
sort!(maturity_counts, :count, rev=true)
maturity_counts |>
@vlplot(
    :bar,
    x=:count,
    y={:maturity_tier, sort="-x"},
    color={:maturity_tier, scale={scheme="blues"}},
    width=600,
    height=200,
    title="Package Maturity Tiers: Ecosystem Distribution",
    tooltip=[{field=:maturity_tier, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/packages_maturity_tiers.png")

# REPOSITORY STRUCTURE COMPLIANCE: Missing key directories
print_progress("Repository Structure Compliance")

structure_compliance = DataFrame(
    feature=["Has src/ directory", "Has test/ directory", "Has docs/ directory", "Has Project.toml"],
    count=[
        sum(packages_df.has_src_dir),
        sum(packages_df.has_test_dir),
        sum(packages_df.has_docs_dir),
        sum(packages_df.has_project_toml)
    ]
)
structure_compliance.percent = round.(100 .* structure_compliance.count ./ nrow(packages_df); digits=1)

structure_compliance |>
@vlplot(
    :bar,
    x={:percent, axis={title="Adoption (%)"}},
    y={:feature, sort="-x"},
    color={value="#3498db"},
    width=600,
    height=200,
    title="Repository Structure Compliance: Standard Layout Adoption",
    tooltip=[{field=:feature, type="nominal"}, {field=:count, type="quantitative"}, {field=:percent, type="quantitative"}]
) |>
save("data/visualizations/packages_structure_compliance.png")

println("\n[Done] All package visualizations generated!")

