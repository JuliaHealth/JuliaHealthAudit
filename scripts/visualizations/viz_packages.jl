# scripts/viz_packages.jl
# Generate all package audit visualizations

using DataFrames
using VegaLite
using Statistics

# 1. STANDARDS COMPLIANCE - Which packages have which features
println("\n[1/20] Generating: Standards Compliance Heatmap")
compliance_cols = [
    :has_src_dir,
    :has_test_dir,
    :has_project_toml,
    :has_license,
    :follows_standard_layout,
    :has_docs_dir,
    :has_ci_workflow,
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
p1 |> save("data/visualizations/01_packages_standards_compliance.png")
p1 |> save("data/visualizations/01_packages_standards_compliance.png")

# 1b. STANDARDS COMPLIANCE SUMMARY (percent of packages meeting each standard)
summary_rows = DataFrame(standard=String[], percent=Float64[], count=Int[])
for col in compliance_cols
    values = packages_df[!, col]
    push!(summary_rows, (standard=String(col), percent=100 * mean(values), count=sum(values)))
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
save("data/visualizations/02_packages_standards_percentages.png")

# 2. STYLE GUIDE DISTRIBUTION
println("[2/20] Generating: Style Guide Distribution Pie Chart")
style_counts = combine(
    groupby(packages_df, :style_guide_type),
    nrow => :count
)
p2 = style_counts |>
@vlplot(
    :arc,
    theta=:count,
    color="style_guide_type:n",
    width=350,
    height=350,
    title="Code Style Guide Adoption",
    tooltip=[{field=:style_guide_type, type="nominal"}, {field=:count, type="quantitative"}]
)
p2 |> save("data/visualizations/03_packages_style_guide_distribution.png")

# 3. TOP 15 BY STARS
println("[3/20] Generating: Top 15 Packages by Stars")
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
save("data/visualizations/04_packages_top15_stars.png")

# 4. TOP 15 BY CONTRIBUTORS
println("[4/20] Generating: Top 15 Packages by Contributors")
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
save("data/visualizations/05_packages_top15_contributors.png")

# 5. TOP 15 BY RELEASES
println("[5/20] Generating: Top 15 Packages by Release Count")
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
save("data/visualizations/06_packages_top15_releases.png")

# 6. DOCUMENTATION ADOPTION (multiple metrics)
println("[6/20] Generating: Documentation Adoption Comparison")
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
save("data/visualizations/07_packages_documentation_adoption.png")

# 7. CI/CD ADOPTION (arc chart for better visibility)
println("[7/20] Generating: CI/CD Adoption Arc Chart")
ci_adoption = DataFrame(
    status=["With CI/CD", "Without CI/CD"],
    count=[
        sum(packages_df.has_ci_workflow),
        nrow(packages_df) - sum(packages_df.has_ci_workflow),
    ],
)
ci_adoption |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="CI/CD Workflow Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/08_packages_ci_adoption.png")

# 8. REGISTRY ADOPTION (arc chart for better visibility)
println("[8/20] Generating: Registry Adoption Distribution")
registry_adoption = DataFrame(
    status=["In General Registry", "Not in Registry"],
    count=[
        sum(packages_df.in_general_registry),
        nrow(packages_df) - sum(packages_df.in_general_registry),
    ],
)
registry_adoption |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="General Registry Adoption",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/09_packages_registry_adoption.png")

# 9. STARS DISTRIBUTION (histogram)
println("[9/17] Generating: Stars Distribution Histogram")
packages_df |>
@vlplot(
    :bar,
    x="stars:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of GitHub Stars"
) |>
save("data/visualizations/10_packages_stars_distribution.png")

# 10. README QUALITY (line count distribution)
println("[10/17] Generating: README Quality (Line Count Distribution)")
packages_df |>
@vlplot(
    :bar,
    x="readme_line_count:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of README Line Counts"
) |>
save("data/visualizations/11_packages_readme_quality.png")

# 11. CONTRIBUTORS DISTRIBUTION
println("[11/17] Generating: Contributors Distribution Histogram")
packages_df |>
@vlplot(
    :bar,
    x="contributors_count:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of Contributors"
) |>
save("data/visualizations/12_packages_contributors_distribution.png")

# 12. RELEASES DISTRIBUTION
println("[12/17] Generating: Releases Distribution Histogram")
packages_df |>
@vlplot(
    :bar,
    x="releases_count:q",
    y="count()",
    width=500,
    height=300,
    title="Distribution of Release Counts"
) |>
save("data/visualizations/13_packages_releases_distribution.png")

# 13. ARCHIVE STATUS (arc chart for better visibility)
println("[13/17] Generating: Archive Status Distribution")
archive_status = DataFrame(
    status=["Active", "Archived"],
    count=[
        nrow(packages_df) - sum(packages_df.is_archived),
        sum(packages_df.is_archived),
    ],
)
archive_status |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="Package Archive Status",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/14_packages_archive_status.png")

# 14. FORK STATUS (arc chart for better visibility)
println("[14/17] Generating: Fork Status Distribution")
fork_status = DataFrame(
    status=["Original", "Fork"],
    count=[
        nrow(packages_df) - sum(packages_df.is_fork),
        sum(packages_df.is_fork),
    ],
)
fork_status |>
@vlplot(
    :arc,
    theta=:count,
    color="status:n",
    width=320,
    height=320,
    title="Package Fork Status",
    tooltip=[{field=:status, type="nominal"}, {field=:count, type="quantitative"}]
) |>
save("data/visualizations/15_packages_fork_status.png")

# 15. OPEN ISSUES vs CLOSED ISSUES (Top 15)
println("[15/17] Generating: Open vs Closed Issues Comparison")
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
save("data/visualizations/16_packages_issues_comparison.png")

# 16. OPEN PRS vs CLOSED PRS (Top 15)
println("[16/17] Generating: Open vs Closed PRs Comparison")
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
save("data/visualizations/17_packages_prs_comparison.png")
