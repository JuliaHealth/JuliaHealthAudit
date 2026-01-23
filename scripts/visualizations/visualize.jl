# scripts/visualizations/visualize.jl

using CSV
using DataFrames
using VegaLite

mkpath("data/visualizations")

println("Loading audit data..")
packages_df = CSV.read("data/results/audit_packages.csv", DataFrame)
nonpackages_df = CSV.read("data/results/audit_non_packages.csv", DataFrame)

num_packages = nrow(packages_df)
num_nonpackages = nrow(nonpackages_df)

println("Loaded $num_packages packages and $num_nonpackages non-packages\n")

include("viz_packages.jl")

include("viz_nonpackages.jl")

include("viz_contributors.jl")

println("All visualizations generated successfully!")
println("Saved to: data/visualizations/")
