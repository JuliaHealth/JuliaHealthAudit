# scripts/main.jl

include("utils.jl")

function main()
    println("\n$TARGET_ORG Ecosystem Audit Pipeline\n")

    load_env_vars()
    println("Target organization: $TARGET_ORG")
    println("GitHub token loaded\n")

    println("\nPhase 1: Separation of Packages")
    include("audit/01_separate_packages.jl")

    println("\nPhase: Registry Discovery ")
    include("audit/02_discover_registry.jl")

    println("\nPhase 2: Auditing Packages\n")
    include("audit/03_audit_packages.jl")

    println("\nPhase 3: Auditing Non-Packages\n")
    include("audit/04_audit_non_packages.jl")

    println("\nPhase 4: Contributor Summary\n")
    include("audit/05_audit_contributors.jl")

    println("\nPhase 5: Generating audit lists\n")
    include("audit/generate_audit_lists.jl")

    println("\nPhase 6: Generating Visualizations\n")
    include("visualizations/visualize.jl")

    println("\nPhase 7: Updating Temporal CSVs\n")
    include("history/01_update_temporal_csvs.jl")

    println("\nAudit Complete!")
    println("Results saved to:")
    println("  - data/results/audit_packages.csv")
    println("  - data/results/audit_non_packages.csv")
    println("  - data/results/registry_packages.csv")
    println("  - data/results/registry_mismatches.csv")
    println("  - data/results/audit_contributors.csv")
    println("  - data/visualizations/*.png")
    println("  - data/history/*.csv")
    println("  - data/results/lists/*.csv")
    println("  - RESULTS.md (comprehensive report)")
end

main()
