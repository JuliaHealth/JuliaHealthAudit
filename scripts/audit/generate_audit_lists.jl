# scripts/audit/generate_audit_lists.jl

using CSV
using DataFrames

const PACKAGE_CSV = "data/results/audit_packages.csv"
const NONPACKAGE_CSV = "data/results/audit_non_packages.csv"
const OUTPUT_DIR = "data/results/lists"

function create_boolean_feature_csv(packages_df, nonpackages_df, feature_col, output_file)
    true_repos = String[]
    false_repos = String[]
    
    if hasproperty(packages_df, feature_col)
        for row in eachrow(packages_df)
            repo_name = string(row.package_name)
            if get(row, feature_col, false)
                push!(true_repos, repo_name)
            else
                push!(false_repos, repo_name)
            end
        end
    end
    
    if hasproperty(nonpackages_df, feature_col)
        for row in eachrow(nonpackages_df)
            repo_name = string(row.repo_name)
            if get(row, feature_col, false)
                push!(true_repos, repo_name)
            else
                push!(false_repos, repo_name)
            end
        end
    end

    max_length = max(length(true_repos), length(false_repos))
    while length(true_repos) < max_length
        push!(true_repos, "")
    end
    while length(false_repos) < max_length
        push!(false_repos, "")
    end

    feature_df = DataFrame(
        "true" => true_repos,
        "false" => false_repos
    )
    
    CSV.write(output_file, feature_df)
end

function create_categorical_feature_csv(packages_df, nonpackages_df, feature_col, output_file, categories=nothing)
    category_repos = Dict{String, Vector{String}}()
    
    if hasproperty(packages_df, feature_col)
        for row in eachrow(packages_df)
            repo_name = string(row.package_name)
            value = string(get(row, feature_col, "none"))
            value = isempty(strip(value)) ? "none" : strip(value)
            
            if !haskey(category_repos, value)
                category_repos[value] = String[]
            end
            push!(category_repos[value], repo_name)
        end
    end

    if hasproperty(nonpackages_df, feature_col)
        for row in eachrow(nonpackages_df)
            repo_name = string(row.repo_name)
            value = string(get(row, feature_col, "none"))
            value = isempty(strip(value)) ? "none" : strip(value)
            
            if !haskey(category_repos, value)
                category_repos[value] = String[]
            end
            push!(category_repos[value], repo_name)
        end
    else
        if !haskey(category_repos, "none")
            category_repos["none"] = String[]
        end
        for row in eachrow(nonpackages_df)
            repo_name = string(row.repo_name)
            push!(category_repos["none"], repo_name)
        end
    end
    
    for cat in categories
        if !haskey(category_repos, cat)
            category_repos[cat] = String[]
        end
    end
    
    all_categories = sort(collect(keys(category_repos)))
    max_length = maximum(length(repos) for repos in values(category_repos))
    
    feature_df = DataFrame()
    for category in all_categories
        repos = category_repos[category]
        
        while length(repos) < max_length
            push!(repos, "")
        end
        
        feature_df[!, Symbol(category)] = repos
    end
    
    CSV.write(output_file, feature_df)
end

function create_contributors_csv(packages_df, nonpackages_df, output_file)
    contributors_file = "data/results/audit_contributors.csv"    
    contributors_df = CSV.read(contributors_file, DataFrame)
    
    core_contributors = String[]
    regular_contributors = String[]
    occasional_contributors = String[]
    one_time_contributors = String[]
    
    for row in eachrow(contributors_df)
        tier = get(row, :contributor_tier, "")
        name = get(row, :name, get(row, :login, ""))
        
        if tier == "Core"
            push!(core_contributors, name)
        elseif tier == "Regular"
            push!(regular_contributors, name)
        elseif tier == "Occasional"
            push!(occasional_contributors, name)
        elseif tier == "One-time"
            push!(one_time_contributors, name)
        end
    end

    sort!(core_contributors)
    sort!(regular_contributors)
    sort!(occasional_contributors)
    sort!(one_time_contributors)
    max_length = max(length(core_contributors), length(regular_contributors), length(occasional_contributors), length(one_time_contributors))
    while length(core_contributors) < max_length
        push!(core_contributors, "")
    end
    while length(regular_contributors) < max_length
        push!(regular_contributors, "")
    end
    while length(occasional_contributors) < max_length
        push!(occasional_contributors, "")
    end
    while length(one_time_contributors) < max_length
        push!(one_time_contributors, "")
    end

    output_df = DataFrame(
        core = core_contributors,
        regular = regular_contributors,
        occasional = occasional_contributors,
        one_time = one_time_contributors
    )
    
    CSV.write(output_file, output_df)
end

function create_human_bot_csv(packages_df, nonpackages_df, output_file)
    contributors_file = "data/results/audit_contributors.csv"
    
    contributors_df = CSV.read(contributors_file, DataFrame)
    human_contributors = String[]
    bot_contributors = String[]
    
    for row in eachrow(contributors_df)
        is_bot = get(row, :is_bot, false)
        name = get(row, :name, get(row, :login, ""))
        
        if is_bot
            push!(bot_contributors, name)
        else
            push!(human_contributors, name)
        end
    end

    sort!(human_contributors)
    sort!(bot_contributors)
    max_length = max(length(human_contributors), length(bot_contributors))
    while length(human_contributors) < max_length
        push!(human_contributors, "")
    end
    while length(bot_contributors) < max_length
        push!(bot_contributors, "")
    end

    output_df = DataFrame(
        human_contributors = human_contributors,
        bot_contributors = bot_contributors
    )
    
    CSV.write(output_file, output_df)
end

function generate_audit_lists()    
    mkpath(OUTPUT_DIR)
    
    packages = CSV.read(PACKAGE_CSV, DataFrame)
    non_packages = CSV.read(NONPACKAGE_CSV, DataFrame)

    boolean_features = [
        :in_general_registry,
        :is_fork,
        :is_archived,
        :has_src_dir,
        :has_test_dir,
        :has_project_toml,
        :has_license,
        :follows_standard_layout,
        :has_docs_dir,
        :has_gh_pages,
        :uses_documenter,
        :has_contributing_md,
        :has_code_of_conduct,
        :has_ci_workflow,
        :has_code_coverage
    ]
    
    for feature in boolean_features
        output_file = joinpath(OUTPUT_DIR, "$(feature).csv")
        create_boolean_feature_csv(packages, non_packages, feature, output_file)
    end
    
    style_output = joinpath(OUTPUT_DIR, "style_guide.csv")
    create_categorical_feature_csv(packages, non_packages, :style_guide_type, style_output)
    
    license_output = joinpath(OUTPUT_DIR, "license.csv")
    create_categorical_feature_csv(packages, non_packages, :license_type, license_output)
    
    maturity_repos = Dict{String, Vector{String}}()
    maturity_repos["not_registered"] = String[]
    maturity_repos["registered_no_releases"] = String[]
    maturity_repos["early_release"] = String[]    
    maturity_repos["stable"] = String[]          
    maturity_repos["mature"] = String[]           
    
    for row in eachrow(packages)
        repo_name = string(row.package_name)
        in_registry = get(row, :in_general_registry, false)
        releases_count = get(row, :releases_count, 0)
        
        if !in_registry
            category = "not_registered"
        elseif releases_count == 0
            category = "registered_no_releases"
        elseif releases_count >= 20
            category = "mature"
        elseif releases_count >= 5
            category = "stable"
        else
            category = "early_release"
        end
        
        push!(maturity_repos[category], repo_name)
    end
    
    for row in eachrow(non_packages)
        repo_name = string(row.repo_name)
        push!(maturity_repos["not_registered"], repo_name)
    end
    
    max_length = maximum(length(repos) for repos in values(maturity_repos))
    maturity_df = DataFrame()
    for (category, repos) in maturity_repos
        while length(repos) < max_length
            push!(repos, "")
        end
        maturity_df[!, Symbol(category)] = repos
    end
    
    maturity_output = joinpath(OUTPUT_DIR, "package_maturity.csv")
    CSV.write(maturity_output, maturity_df)

    contributors_output = joinpath(OUTPUT_DIR, "contributors.csv")
    create_contributors_csv(packages, non_packages, contributors_output)
    
    human_bot_output = joinpath(OUTPUT_DIR, "human_bot_contributors.csv")
    create_human_bot_csv(packages, non_packages, human_bot_output)
end

generate_audit_lists()
    