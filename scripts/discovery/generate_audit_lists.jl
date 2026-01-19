using CSV, DataFrames

const DEFAULT_PKG_CSV = "data/results/audit_packages.csv"
const DEFAULT_NP_CSV = "data/results/audit_non_packages.csv"
const DEFAULT_OUT_DIR = "data/results/lists"

"""
is_true(val) -> Bool

Interpret common boolean-like values as `true`.
Returns `false` for `missing` or `nothing`.
Recognized true values: Bool true, the strings "true", "1", "yes" (case-insensitive).
"""
function is_true(val)
    if val === nothing || ismissing(val)
        return false
    end
    if isa(val, Bool)
        return val
    end
    sval = lowercase(string(val))
    return sval in ("true", "1", "yes")
end

"""
write(path, arr)

Write elements of `arr` to `path`, one per line. Creates parent directories as needed.
"""
function write(path, arr)
    mkpath(dirname(path))
    open(path, "w") do io
        for v in arr
            println(io, v)
        end
    end
end

"""
generate_audit_lists(; pkg_csv=DEFAULT_PKG_CSV, np_csv=DEFAULT_NP_CSV, out_dir=DEFAULT_OUT_DIR)

Generate yes/no and style lists from audit CSVs and write them into `out_dir`.
"""
function generate_audit_lists(
    pkg_csv=DEFAULT_PKG_CSV, np_csv=DEFAULT_NP_CSV, out_dir=DEFAULT_OUT_DIR
)
    mkpath(out_dir)

    df = CSV.read(pkg_csv, DataFrame)
    np = CSV.read(np_csv, DataFrame)

    # Features to export as yes/no lists
    features = Dict(
        :has_src_dir => (col->col),
        :has_test_dir => (col->col),
        :has_project_toml => (col->col),
        :has_license => (col->col),
        :follows_standard_layout => (col->col),
        :has_docs_dir => (col->col),
        :has_gh_pages => (col->col),
        :uses_documenter => (col->col),
        :has_contributing_md => (col->col),
        :has_code_of_conduct => (col->col),
        :has_ci_workflow => (col->col),
        :has_code_coverage => (col->col),
        :readme_has_code_blocks => (col->col),
    )

    # For each feature, write *_yes.txt and *_no.txt
    for (s, _) in features
        col = string(s)
        yes = String[]
        no = String[]
        if hasproperty(df, Symbol(col))
            for r in eachrow(df)
                v = r[Symbol(col)]
                if is_true(v)
                    push!(yes, r.package_name)
                else
                    push!(no, r.package_name)
                end
            end
            write(joinpath(out_dir, string(col, "_yes.txt")), yes)
            write(joinpath(out_dir, string(col, "_no.txt")), no)
        end
    end

    # Combined lists for is_fork and is_archived across packages and non-packages
    combined_is_fork = String[]
    if hasproperty(df, :is_fork)
        for r in eachrow(df)
            if is_true(r[:is_fork])
                push!(combined_is_fork, r.package_name)
            end
        end
    end
    write(joinpath(out_dir, "is_fork_yes.txt"), combined_is_fork)

    combined_is_archived = String[]
    if hasproperty(df, :is_archived)
        for r in eachrow(df)
            if is_true(r[:is_archived])
                push!(combined_is_archived, r.package_name)
            end
        end
    end
    write(joinpath(out_dir, "is_archived_yes.txt"), combined_is_archived)

    # releases_count: have any releases?
    with_releases = String[]
    without_releases = String[]
    if hasproperty(df, :releases_count)
        for r in eachrow(df)
            rc = r.releases_count
            if !ismissing(rc) && tryparse(Int, string(rc)) !== nothing && Int(rc) > 0
                push!(with_releases, r.package_name)
            else
                push!(without_releases, r.package_name)
            end
        end
        write(joinpath(out_dir, "with_releases.txt"), with_releases)
        write(joinpath(out_dir, "without_releases.txt"), without_releases)
    end

    if hasproperty(df, :style_guide_type)
        styles = Dict{String,Vector{String}}()
        for r in eachrow(df)
            s = strip(lowercase(string(r.style_guide_type)))
            if s == "" || s == "none"
                s = "none"
            end
            styles[s] = get(styles, s, String[])
            push!(styles[s], r.package_name)
        end
        for (s, arr) in styles
            if s == "blue" || s == "sciml" || s == "scilm" || occursin("sci", s)
                write(
                    joinpath(out_dir, string("style_", replace(s, " "=>"_"), ".txt")), arr
                )
            end
        end
    end

    if hasproperty(np, :has_ci_workflow)
        yes_path = joinpath(out_dir, "has_ci_workflow_yes.txt")
        no_path = joinpath(out_dir, "has_ci_workflow_no.txt")
        yes = isfile(yes_path) ? readlines(yes_path) : String[]
        no = isfile(no_path) ? readlines(no_path) : String[]
        for r in eachrow(np)
            v = r[:has_ci_workflow]
            if is_true(v)
                push!(yes, r.repo_name)
            else
                push!(no, r.repo_name)
            end
        end
        write(yes_path, unique(yes))
        write(no_path, unique(no))
    end

    println("Output dir: $(out_dir)")
end

generate_audit_lists()
