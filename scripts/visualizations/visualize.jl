# scripts/visualizations/visualize.jl
# Main visualization orchestrator - generates all audit visualizations

using CSV
using DataFrames
using VegaLite
using Statistics
using Dates

mkpath("data/visualizations")

println("Loading audit data...")
packages_df = CSV.read("data/results/audit_packages.csv", DataFrame)
nonpackages_df = CSV.read("data/results/audit_non_packages.csv", DataFrame)

num_packages = nrow(packages_df)
num_nonpackages = nrow(nonpackages_df)
total_repos = num_packages + num_nonpackages

println("Loaded $num_packages packages and $num_nonpackages non-packages\n")

println("Updating RESULTS.md with dynamic coverage stats...")
results_content = read("RESULTS.md", String)

# Get current date
current_date = Dates.format(today(), "B d, Y") 

# Replace placeholders with actual values
updated_content = results_content
updated_content = replace(updated_content, "{{LAST_UPDATED}}" => current_date)
updated_content = replace(updated_content, "{{TOTAL_REPOS}}" => string(total_repos))
updated_content = replace(updated_content, "{{PACKAGE_COUNT}}" => string(num_packages))
updated_content = replace(updated_content, "{{NONPACKAGE_COUNT}}" => string(num_nonpackages))

write("RESULTS.md", updated_content)

include("viz_packages.jl")

include("viz_nonpackages.jl")

println("All visualizations generated successfully!")
println("Saved to: data/visualizations/")
