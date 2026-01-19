# scripts/main.jl
# JuliaHealth Package Audit - Main Entry Point
# Run this script to execute the full reproducible audit pipeline

using CSV
using DataFrames

include("utils.jl")

function main()
    println("\nJuliaHealth Package Audit Pipeline\n")

    token = load_env_vars()
    println("GitHub token loaded from .env\n")

    has_baselines =
        isfile("data/baselines/org_repositories.csv") &&
        isfile("data/baselines/registry_packages.csv")

    if has_baselines
        println("Found existing baseline data in data/baselines/\n")
    else
        println("Baselines not found. Generating...\n")
        println("Fetching JuliaHealth Organization Repositories\n")
        include("discover_org.jl")
        println("\nGenerating Registry Package List (Local or Committed)\n")

        if isdir("General Registry/General")
            println("Found local General Registry clone. Scanning...")
            include("discover_registry.jl")
        else
            println("No local General Registry found.")
            println("To scan the registry, clone it locally:")
            println(
                "  git clone https://github.com/JuliaRegistries/General.git \"General Registry/General\"",
            )
            println("Then run: julia scripts/discover_registry.jl")
            println("For now, using committed baselines only.\n")
        end
    end

    println("Phase 1: Separating Repositories (Packages vs Non-Packages)")
    include("audit/01_separate_packages.jl")

    println("\nPhase 2: Auditing Packages\n")
    include("audit/02_audit_packages.jl")

    println("\nPhase 3: Auditing Non-Packages\n")
    include("audit/03_audit_non_packages.jl")

    println("\nPhase 4: Generating Visualizations\n")
    include("visualizations/visualize.jl")

    println("\nPhase 5: Generating audit lists\n")
    include("discovery/generate_audit_lists.jl")

    println("\nAudit Complete!")
    println("Results saved to:")
    println("- data/results/audit_packages.csv")
    println("- data/results/audit_non_packages.csv")
    println("- data/visualizations/*.html")
    println("- data/results/lists/*.txt")
    println("- RESULTS.md (comprehensive report)\n")
end

main()
