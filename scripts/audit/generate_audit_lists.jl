# scripts/audit/generate_audit_lists.jl

using CSV
using DataFrames

const PACKAGE_CSV = "data/results/audit_packages.csv"
const NONPACKAGE_CSV = "data/results/audit_non_packages.csv"
const OUTPUT = "data/results/lists"

function is_true(val)
    if isa(val, Bool)
        return val
    end
end

function write_list(path, arr)
    mkpath(dirname(path))
    open(path, "w") do io
        for v in arr
            println(io, v)
        end
    end
end

function group_by_bool_column(df, col, name_col)
    true_list = String[]
    false_list = String[]

    for r in eachrow(df)
        if is_true(r[col])
            push!(true_list, string(r[name_col]))
        else
            push!(false_list, string(r[name_col]))
        end
    end

    return true_list, false_list
end

function group_by_category(df, col, name_col, prefix="")
    groups = Dict{String,Vector{String}}()

    for r in eachrow(df)
        value = strip(string(r[col]))
        if value == ""
            value = "none"
        end

        if !haskey(groups, value)
            groups[value] = String[]
        end
        push!(groups[value], string(r[name_col]))
    end

    return groups
end

function generate_audit_lists(pkg_csv=PACKAGE_CSV, np_csv=NONPACKAGE_CSV, out_dir=OUTPUT)
    mkpath(out_dir)

    packages = CSV.read(pkg_csv, DataFrame)
    non_packages = CSV.read(np_csv, DataFrame)

    println("\nGenerating audit lists for all features")

    bool_columns = [
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
        :has_code_coverage,
    ]

    for col in bool_columns
        true_list = String[]
        false_list = String[]

        if hasproperty(packages, col)
            pkg_true, pkg_false = group_by_bool_column(packages, col, :package_name)
            append!(true_list, pkg_true)
            append!(false_list, pkg_false)
        end

        if hasproperty(non_packages, col)
            np_true, np_false = group_by_bool_column(non_packages, col, :repo_name)
            append!(true_list, np_true)
            append!(false_list, np_false)
        end

        if !isempty(true_list) || !isempty(false_list)
            write_list(joinpath(out_dir, string(col, "_true.txt")), true_list)
            write_list(joinpath(out_dir, string(col, "_false.txt")), false_list)
        end
    end

    style_groups = group_by_category(packages, :style_guide_type, :package_name)
    for (style, pkgs) in style_groups
        filename = "style_" * replace(style, " "=>"_") * ".txt"
        write_list(joinpath(out_dir, filename), pkgs)
    end

    license_groups = group_by_category(packages, :license_type, :package_name)
    for (license, pkgs) in license_groups
        filename = "license_" * replace(license, " "=>"_", "/"=>"_") * ".txt"
        write_list(joinpath(out_dir, filename), pkgs)
    end

    println("\nGenerated lists in: $(out_dir)")
end

generate_audit_lists()

