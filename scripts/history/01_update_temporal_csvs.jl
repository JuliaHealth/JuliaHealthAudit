# scripts/history/01_update_temporal_csvs.jl

using CSV
using DataFrames
using Dates

const AUDIT_PACKAGES_INPUT = "data/results/audit_packages.csv"
const PACKAGES_TIMESERIES_OUTPUT = "data/history/packages_timeseries.csv"
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

function build_packages_timeseries(packages_df::DataFrame, run_month::String, run_ts::String, run_id::String)
    preferred_cols = [
        :package_name,
        :in_general_registry,
        :is_fork,
        :is_archived,
        :stars,
        :monthly_downloads,
        :total_downloads,
        :human_contributors_count,
        :bot_contributors_count,
        :maintainers_count,
        :active_maintainers_count,
        :has_active_maintainers,
        :maintenance_status,
        :readme_completeness_score,
        :has_ci_workflow,
        :has_gh_pages,
        :open_issues_count,
        :open_prs_count,
        :avg_pr_merge_days,
        :days_since_last_activity,
    ]

    available = Set(Symbol.(names(packages_df)))
    select_cols = [c for c in preferred_cols if c in available]

    timeseries = select(packages_df, select_cols)
    timeseries.run_month = fill(run_month, nrow(timeseries))
    timeseries.run_timestamp = fill(run_ts, nrow(timeseries))
    timeseries.run_id = fill(run_id, nrow(timeseries))

    ordered_cols = [
        :run_month,
        :run_timestamp,
        :run_id,
        :package_name,
        :in_general_registry,
        :is_fork,
        :is_archived,
        :stars,
        :monthly_downloads,
        :total_downloads,
        :human_contributors_count,
        :bot_contributors_count,
        :maintainers_count,
        :active_maintainers_count,
        :has_active_maintainers,
        :maintenance_status,
        :readme_completeness_score,
        :has_ci_workflow,
        :has_gh_pages,
        :open_issues_count,
        :open_prs_count,
        :avg_pr_merge_days,
        :days_since_last_activity,
    ]

    final_cols = [c for c in ordered_cols if c in Set(Symbol.(names(timeseries)))]
    return timeseries[:, final_cols]
end

function build_monthly_tops(packages_df::DataFrame, run_month::String, run_ts::String, run_id::String)
    tops = DataFrame(
        run_month=String[],
        run_timestamp=String[],
        run_id=String[],
        metric=String[],
        rank=Int[],
        package_name=String[],
        value=Float64[],
    )

    metrics = [
        (:stars, "stars"),
        (:monthly_downloads, "monthly_downloads"),
        (:total_downloads, "total_downloads"),
    ]

    available = Set(Symbol.(names(packages_df)))

    for (metric_col, metric_name) in metrics
        metric_col in available || continue

        ranked = sort(packages_df, metric_col; rev=true)
        top_n = min(15, nrow(ranked))

        for i in 1:top_n
            row = ranked[i, :]
            raw_val = row[metric_col]
            val = ismissing(raw_val) ? 0.0 : Float64(raw_val)

            push!(tops, (
                run_month,
                run_ts,
                run_id,
                metric_name,
                i,
                String(row.package_name),
                val,
            ))
        end
    end

    return tops
end

function build_run_summary(packages_df::DataFrame, run_month::String, run_ts::String, run_id::String)
    total_packages = nrow(packages_df)
    available = Set(Symbol.(names(packages_df)))

    stars_total = :stars in available ? sum(skipmissing(packages_df.stars)) : 0
    monthly_downloads_total = :monthly_downloads in available ? sum(skipmissing(packages_df.monthly_downloads)) : 0
    total_downloads_total = :total_downloads in available ? sum(skipmissing(packages_df.total_downloads)) : 0

    ci_adoption_pct = :has_ci_workflow in available ? round(100 * sum(packages_df.has_ci_workflow) / max(total_packages, 1); digits=1) : 0.0
    gh_pages_adoption_pct = :has_gh_pages in available ? round(100 * sum(packages_df.has_gh_pages) / max(total_packages, 1); digits=1) : 0.0
    active_maintainers_pct = :has_active_maintainers in available ? round(100 * sum(packages_df.has_active_maintainers) / max(total_packages, 1); digits=1) : 0.0

    top_stars_package = ""
    top_monthly_downloads_package = ""
    top_total_downloads_package = ""

    if total_packages > 0 && :stars in available
        top_stars_package = String(sort(packages_df, :stars; rev=true)[1, :package_name])
    end
    if total_packages > 0 && :monthly_downloads in available
        top_monthly_downloads_package = String(sort(packages_df, :monthly_downloads; rev=true)[1, :package_name])
    end
    if total_packages > 0 && :total_downloads in available
        top_total_downloads_package = String(sort(packages_df, :total_downloads; rev=true)[1, :package_name])
    end

    return DataFrame(
        run_month=[run_month],
        run_timestamp=[run_ts],
        run_id=[run_id],
        total_packages=[total_packages],
        stars_total=[stars_total],
        monthly_downloads_total=[monthly_downloads_total],
        total_downloads_total=[total_downloads_total],
        ci_adoption_pct=[ci_adoption_pct],
        gh_pages_adoption_pct=[gh_pages_adoption_pct],
        active_maintainers_pct=[active_maintainers_pct],
        top_stars_package=[top_stars_package],
        top_monthly_downloads_package=[top_monthly_downloads_package],
        top_total_downloads_package=[top_total_downloads_package],
    )
end

function update_temporal_csvs()
    if get(ENV, "GITHUB_ACTIONS", "false") != "true"
        println("Skipping temporal CSV update (not running in GitHub Actions)")
        return
    end

    isfile(AUDIT_PACKAGES_INPUT) || error("Missing input: $AUDIT_PACKAGES_INPUT")

    packages_df = CSV.read(AUDIT_PACKAGES_INPUT, DataFrame)

    now_utc = now(UTC)
    run_month = Dates.format(now_utc, "yyyy-mm")
    run_ts = Dates.format(now_utc, "yyyy-mm-ddTHH:MM:SS") * "Z"
    run_id = get(ENV, "GITHUB_RUN_ID", run_ts)

    current_timeseries = build_packages_timeseries(packages_df, run_month, run_ts, run_id)
    current_tops = build_monthly_tops(packages_df, run_month, run_ts, run_id)
    current_summary = build_run_summary(packages_df, run_month, run_ts, run_id)

    ensure_parent_dir(PACKAGES_TIMESERIES_OUTPUT)
    ensure_parent_dir(MONTHLY_TOPS_OUTPUT)
    ensure_parent_dir(RUN_SUMMARY_OUTPUT)

    existing_timeseries = load_or_empty(PACKAGES_TIMESERIES_OUTPUT, current_timeseries[1:0, :])
    existing_tops = load_or_empty(MONTHLY_TOPS_OUTPUT, current_tops[1:0, :])
    existing_summary = load_or_empty(RUN_SUMMARY_OUTPUT, current_summary[1:0, :])

    updated_timeseries = vcat(existing_timeseries, current_timeseries; cols=:union)
    updated_tops = vcat(existing_tops, current_tops; cols=:union)
    updated_summary = vcat(existing_summary, current_summary; cols=:union)

    sort!(updated_timeseries, [:run_timestamp, :package_name])
    sort!(updated_tops, [:run_timestamp, :metric, :rank])
    sort!(updated_summary, :run_timestamp)

    CSV.write(PACKAGES_TIMESERIES_OUTPUT, updated_timeseries)
    CSV.write(MONTHLY_TOPS_OUTPUT, updated_tops)
    CSV.write(RUN_SUMMARY_OUTPUT, updated_summary)

    println("Temporal CSV update complete:")
    println("- $PACKAGES_TIMESERIES_OUTPUT")
    println("- $MONTHLY_TOPS_OUTPUT")
    println("- $RUN_SUMMARY_OUTPUT")
end

update_temporal_csvs()
