# scripts/history/01_update_temporal_csvs.jl

using CSV
using DataFrames
using Dates

const AUDIT_PACKAGES_INPUT = "data/results/audit_packages.csv"
const AUDIT_CONTRIBUTORS_INPUT = "data/results/audit_contributors.csv"
const MONTHLY_TOPS_OUTPUT = "data/history/monthly_tops.csv"
const RUN_SUMMARY_OUTPUT = "data/history/run_summary.csv"

function ensure_parent_dir(path::String)
    mkpath(dirname(path))
end

function load_or_empty(path::String, schema::DataFrame)
    if isfile(path)
        return CSV.read(path, DataFrame)
    end
    return schema
end

function align_schema_or_reset(existing::DataFrame, schema::DataFrame, label::String)
    if isempty(existing)
        return existing
    end

    existing_cols = Set(Symbol.(names(existing)))
    schema_cols = Set(Symbol.(names(schema)))
    if existing_cols == schema_cols
        return existing
    end

    println("Schema changed for $label; resetting existing history for this file")
    return schema[1:0, :]
end

function get_total(packages_df::DataFrame, available::Set{Symbol}, metric_col::Symbol)
    return metric_col in available ? sum(skipmissing(packages_df[!, metric_col])) : 0
end

function count_true(packages_df::DataFrame, available::Set{Symbol}, col::Symbol)
    if !(col in available)
        return 0
    end
    return sum(packages_df[!, col])
end

function count_status(packages_df::DataFrame, available::Set{Symbol}, status::String)
    if !(:maintenance_status in available)
        return 0
    end
    return sum(
        lowercase(String(s)) == lowercase(status) for
        s in skipmissing(packages_df.maintenance_status)
    )
end

function get_top(packages_df::DataFrame, available::Set{Symbol}, metric_col::Symbol)
    if nrow(packages_df) == 0 || !(metric_col in available)
        return "", 0.0
    end

    ranked = sort(packages_df, metric_col; rev=true)
    top_row = ranked[1, :]
    raw_val = top_row[metric_col]
    top_val = ismissing(raw_val) ? 0.0 : Float64(raw_val)
    return String(top_row.package_name), top_val
end

function dedup_human_bot_counts(contributors_df::DataFrame)
    if nrow(contributors_df) == 0
        return 0, 0
    end

    contributor_cols = Set(Symbol.(names(contributors_df)))
    if !(:is_bot in contributor_cols)
        return 0, 0
    end

    bot_total = sum(contributors_df.is_bot)
    human_total = nrow(contributors_df) - bot_total
    return human_total, bot_total
end

function build_monthly_tops(
    packages_df::DataFrame,
    run_month::String,
    run_ts::String,
    run_id::String,
)
    tops = DataFrame(
        run_month=[run_month],
        run_timestamp=[run_ts],
        run_id=[run_id],
    )

    metrics = [
        (:stars, "stars"),
        (:monthly_downloads, "monthly_downloads"),
        (:human_contributors_count, "human_contributors_count"),
        (:active_maintainers_count, "active_maintainers_count"),
    ]

    available = Set(Symbol.(names(packages_df)))

    for (metric_col, metric_name) in metrics
        ranked = metric_col in available ?
            sort(packages_df, metric_col; rev=true) :
            packages_df[1:0, :]
        top_n = min(5, nrow(ranked))

        for i in 1:5
            package_col = Symbol("$(metric_name)_top$(i)_package")
            value_col = Symbol("$(metric_name)_top$(i)_value")

            if i <= top_n
                row = ranked[i, :]
                raw_val = row[metric_col]
                tops[!, package_col] = [String(row.package_name)]
                tops[!, value_col] = [ismissing(raw_val) ? 0.0 : Float64(raw_val)]
            else
                tops[!, package_col] = [""]
                tops[!, value_col] = [0.0]
            end
        end
    end

    return tops
end

function build_run_summary(
    packages_df::DataFrame,
    contributors_df::DataFrame,
    run_month::String,
    run_ts::String,
    run_id::String,
)
    total_packages = nrow(packages_df)
    available = Set(Symbol.(names(packages_df)))
    human_total_dedup, bot_total_dedup = dedup_human_bot_counts(contributors_df)

    top_stars_package, top_stars_value = get_top(packages_df, available, :stars)
    top_monthly_downloads_package, top_monthly_downloads_value = get_top(packages_df, available, :monthly_downloads)
    top_human_contributors_package, top_human_contributors_value = get_top(packages_df, available, :human_contributors_count)
    top_active_maintainers_package, top_active_maintainers_value = get_top(packages_df, available, :active_maintainers_count)

    return DataFrame(
        run_month=[run_month],
        run_timestamp=[run_ts],
        run_id=[run_id],

        total_packages=[total_packages],
        in_general_registry_count=[count_true(packages_df, available, :in_general_registry)],
        forks_count=[count_true(packages_df, available, :is_fork)],
        archived_count=[count_true(packages_df, available, :is_archived)],

        has_src_dir_count=[count_true(packages_df, available, :has_src_dir)],
        has_test_dir_count=[count_true(packages_df, available, :has_test_dir)],
        has_project_toml_count=[count_true(packages_df, available, :has_project_toml)],
        has_license_count=[count_true(packages_df, available, :has_license)],
        has_docs_dir_count=[count_true(packages_df, available, :has_docs_dir)],

        has_gh_pages_count=[count_true(packages_df, available, :has_gh_pages)],
        has_ci_workflow_count=[count_true(packages_df, available, :has_ci_workflow)],
        has_code_coverage_count=[count_true(packages_df, available, :has_code_coverage)],
        has_active_maintainers_count=[count_true(packages_df, available, :has_active_maintainers)],

        releases_total=[get_total(packages_df, available, :releases_count)],
        stars_total=[get_total(packages_df, available, :stars)],
        monthly_downloads_total=[get_total(packages_df, available, :monthly_downloads)],
        total_downloads_total=[get_total(packages_df, available, :total_downloads)],
        open_issues_total=[get_total(packages_df, available, :open_issues_count)],
        closed_issues_total=[get_total(packages_df, available, :closed_issues_count)],
        open_prs_total=[get_total(packages_df, available, :open_prs_count)],
        closed_prs_total=[get_total(packages_df, available, :closed_prs_count)],
        human_contributors_total=[human_total_dedup],
        bot_contributors_total=[bot_total_dedup],

        maintenance_active_count=[count_status(packages_df, available, "Active")],
        maintenance_inactive_count=[count_status(packages_df, available, "Inactive")],
        maintenance_abandoned_count=[count_status(packages_df, available, "Abandoned")],
        maintenance_concept_count=[count_status(packages_df, available, "Concept")],

        top_stars_package=[top_stars_package],
        top_stars_value=[top_stars_value],
        top_monthly_downloads_package=[top_monthly_downloads_package],
        top_monthly_downloads_value=[top_monthly_downloads_value],
        top_human_contributors_package=[top_human_contributors_package],
        top_human_contributors_value=[top_human_contributors_value],
        top_active_maintainers_package=[top_active_maintainers_package],
        top_active_maintainers_value=[top_active_maintainers_value],
    )
end

function update_temporal_csvs()
    if get(ENV, "GITHUB_ACTIONS", "false") != "true"
        println("Skipping temporal CSV update (not running in GitHub Actions)")
        return
    end

    isfile(AUDIT_PACKAGES_INPUT) || error("Missing input: $AUDIT_PACKAGES_INPUT")

    packages_df = CSV.read(AUDIT_PACKAGES_INPUT, DataFrame)
    contributors_df = isfile(AUDIT_CONTRIBUTORS_INPUT) ?
        CSV.read(AUDIT_CONTRIBUTORS_INPUT, DataFrame) :
        DataFrame(login=String[], is_bot=Bool[])

    now_utc = now(UTC)
    run_month = Dates.format(now_utc, "yyyy-mm-dd")
    run_ts = Dates.format(now_utc, "yyyy-mm-ddTHH:MM:SS") * "Z"
    run_id = get(ENV, "GITHUB_RUN_ID", run_ts)

    current_tops = build_monthly_tops(packages_df, run_month, run_ts, run_id)
    current_summary = build_run_summary(packages_df, contributors_df, run_month, run_ts, run_id)

    ensure_parent_dir(MONTHLY_TOPS_OUTPUT)
    ensure_parent_dir(RUN_SUMMARY_OUTPUT)

    existing_tops = align_schema_or_reset(
        load_or_empty(MONTHLY_TOPS_OUTPUT, current_tops[1:0, :]),
        current_tops,
        MONTHLY_TOPS_OUTPUT,
    )
    existing_summary = align_schema_or_reset(
        load_or_empty(RUN_SUMMARY_OUTPUT, current_summary[1:0, :]),
        current_summary,
        RUN_SUMMARY_OUTPUT,
    )

    updated_tops = vcat(existing_tops, current_tops; cols=:union)
    updated_summary = vcat(existing_summary, current_summary; cols=:union)

    sort!(updated_tops, :run_timestamp)
    sort!(updated_summary, :run_timestamp)

    CSV.write(MONTHLY_TOPS_OUTPUT, updated_tops)
    CSV.write(RUN_SUMMARY_OUTPUT, updated_summary)

    println("Temporal CSV update complete:")
    println("- $MONTHLY_TOPS_OUTPUT")
    println("- $RUN_SUMMARY_OUTPUT")
end

update_temporal_csvs()
