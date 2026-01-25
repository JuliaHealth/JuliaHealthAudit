# scripts/visualizations/viz_contributors.jl

println("\nGenerating contributor visualizations")

contributors_df = CSV.read("data/results/audit_contributors.csv", DataFrame)

# Progress tracking
viz_counter = Ref(0)
function print_progress(name::String)
    viz_counter[] += 1
    println("[$(viz_counter[])] Generating: $name")
end

    
# Top Contributors by Total Contributions
print_progress("Top Contributors by Total Contributions")
top_by_total = sort(contributors_df, :total_contributions; rev=true)
top_by_total = first(top_by_total, min(30, nrow(top_by_total)))
@vlplot(
    :bar,
    title="Top Contributors by Total Contributions",
    width=800,
    height=600,
    x={:total_contributions, title="Total Contributions", axis={grid=true}},
    y={:name, sort="-x", title="Contributor", axis={labelLimit=320}},
    color={value="#388E3C"},
    data=top_by_total
) |> save("data/visualizations/contributors_top_by_total.png")

# Contribution Distribution (Histogram)
print_progress("Contribution Distribution")
@vlplot(
    :bar,
    title="Distribution of Total Contributions",
    width=800,
    height=400,
    x={:total_contributions, bin={step=50}, title="Total Contributions (binned)"},
    y={"count()", title="Number of Contributors"},
    color={value="#1976D2"},
    data=contributors_df
) |> save("data/visualizations/contributors_contribution_distribution.png")

# Contributor Engagement Tiers
print_progress("Contributor Engagement Tiers")
tier_counts = combine(groupby(contributors_df, :contributor_tier), nrow => :count)
@vlplot(
    :bar,
    title="Contributor Engagement Tiers",
    width=700,
    height=400,
    x={:contributor_tier, sort=["Core", "Regular", "Occasional", "One-time"], title="Tier"},
    y={:count, title="Contributors"},
    color={:contributor_tier, scale={domain=["Core","Regular","Occasional","One-time"], range=["#2E7D32","#1976D2","#F9A825","#D32F2F"]}},
    data=tier_counts
) |> save("data/visualizations/contributors_engagement_tiers.png")

# Top Contributors by Repo Count
print_progress("Top Contributors by Repo Count")
top_by_repos = sort(contributors_df, :num_repos_contributed; rev=true)
top_by_repos = first(top_by_repos, min(30, nrow(top_by_repos)))
@vlplot(
    :bar,
    title="Top Contributors by Repo Count",
    width=800,
    height=600,
    x={:num_repos_contributed, title="Repos Contributed"},
    y={:name, sort="-x", title="Contributor", axis={labelLimit=320}},
    color={value="#0288D1"},
    data=top_by_repos
) |> save("data/visualizations/contributors_top_by_repo_count.png")

println("Contributor visualizations complete!")
