# scripts/utils.jl

using DotEnv
using HTTP
using Dates
using JSON3
using Base64
using TOML

const GITHUB_API = "https://api.github.com"

"""
    load_env_vars()

Load GITHUB_TOKEN from .env file.
"""
function load_env_vars()
    DotEnv.load!()
    token = get(ENV, "GITHUB_TOKEN", "")
    token == "" && error("GITHUB_TOKEN not set in .env file")
    return token
end

const GITHUB_TOKEN = load_env_vars()

"""
    parse_repo_url(url)

Extract owner and repo name from GitHub URL.
"""
function parse_repo_url(url)
    url_clean = endswith(url, ".git") ? url[1:end-4] : url
    parts = split(url_clean, "/")
    owner = parts[end - 1]
    repo = parts[end]
    return owner, repo
end

"""
    github_request(endpoint)

Make authenticated API request to GitHub.
"""
function github_request(endpoint)
    headers = [
        "User-Agent" => "JuliaHealth-Audit", "Authorization" => "token $GITHUB_TOKEN"
    ]
    try
        response = HTTP.get("$GITHUB_API$endpoint", headers)
        return JSON3.read(String(response.body))
    catch e
        return nothing
    end
end

"""
    get_repo_info(owner, repo)

Get basic repo info from GitHub.
"""
function get_repo_info(owner, repo)
    data = github_request("/repos/$owner/$repo")
    isnothing(data) && return nothing

    return (
        stars=get(data, :stargazers_count, 0),
        pushed_at=something(get(data, :pushed_at, missing), missing),
        archived=get(data, :archived, false),
        is_fork=get(data, :fork, false),
        default_branch=get(data, :default_branch, "main"),
    )
end

"""
    get_tree(owner, repo, branch)

Get file tree recursively.
"""
function get_tree(owner, repo, branch)
    data = github_request("/repos/$owner/$repo/git/trees/$branch?recursive=1")
    isnothing(data) && return String[]

    tree = get(data, :tree, [])
    return [String(item.path) for item in tree]
end

"""
    classify_maintenance_status(maintainers_count, active_maintainers_count, days_since_activity, releases_count)

Figure out if a repo is actively maintained based on maintainer activity and releases.
"""
function classify_maintenance_status(maintainers_count::Int, active_maintainers_count::Int, days_since_activity, releases_count::Int)
    days = ismissing(days_since_activity) ? Inf : days_since_activity
    
    if releases_count < 1
        return "Concept"
    end

    if active_maintainers_count > 0
        return "Active"
    end

    if maintainers_count > 0
        if days < 540  
            return "Inactive"
        else  
            return "Abandoned"
        end
    end

    return "Abandoned"
end

"""
    get_maintainers_info(owner, repo)

Find people with push access who committed in the last 1-10 years.
Also tracks who was active in last 6 months.
"""
function get_maintainers_info(owner, repo)
    maintainers = String[]
    active_maintainers = String[]
    six_months_ago = Dates.now() - Dates.Month(6)
    
    for years_back in 1:10
        since_date = Dates.format(Dates.now() - Dates.Year(years_back), "yyyy-mm-dd")
        commits_endpoint = "/repos/$owner/$repo/commits?since=$since_date&per_page=100"
        
        committers = Set{String}()
        committers_with_dates = Dict{String, DateTime}()
        
        data = github_request(commits_endpoint)
        if !isnothing(data) && !isempty(data)
            for commit in data
                commit_date_str = get(get(commit, :commit, Dict()), :author, Dict())[:date]
                commit_date = DateTime(commit_date_str[1:19], "yyyy-mm-ddTHH:MM:SS")

                for key in (:author, :committer)
                    person = get(commit, key, nothing)
                    if !isnothing(person) && haskey(person, :login)
                        login = String(person.login)
                        login_lower = lowercase(login)
                        if !occursin("bot", login_lower) && login_lower != lowercase(owner) && login_lower ∉ ("web-flow", "renovate")
                            push!(committers, login)
                            if !haskey(committers_with_dates, login) || commit_date > committers_with_dates[login]
                                committers_with_dates[login] = commit_date
                            end
                        end
                    end
                end
            end
        end
        
        if !isempty(committers)
            collab_data = github_request("/repos/$owner/$repo/collaborators")
            if !isnothing(collab_data)
                for person_login in committers
                    for collaborator in collab_data
                        if String(collaborator.login) == person_login
                            permission = get(collaborator, :permissions, nothing)
                            if !isnothing(permission)
                                if get(permission, :push, false) || get(permission, :admin, false) || get(permission, :maintain, false)
                                    push!(maintainers, person_login)
                                    if haskey(committers_with_dates, person_login) && committers_with_dates[person_login] >= six_months_ago
                                        push!(active_maintainers, person_login)
                                    end
                                end
                            end
                            break
                        end
                    end
                end
            else
                # Can't verify permissions - trust the committers we found
                maintainers = collect(committers)
                for (login, last_commit) in committers_with_dates
                    if last_commit >= six_months_ago
                        push!(active_maintainers, login)
                    end
                end
            end
            if !isempty(maintainers)
                break
            end
        end
    end
    
    all_list = isempty(maintainers) ? "" : join(sort(unique(maintainers)), "; ")
    active_list = isempty(active_maintainers) ? "" : join(sort(unique(active_maintainers)), "; ")
    return (all_list, length(unique(maintainers)), active_list, length(unique(active_maintainers)))
end

"""
    get_readme_content(owner, repo)

Fetch and decode README content.
"""
function get_readme_content(owner, repo)
    data = github_request("/repos/$owner/$repo/readme")
    isnothing(data) && return ""

    content = get(data, :content, "")
    isempty(content) && return ""

    return String(base64decode(replace(content, "\n" => "")))
end

"""
    get_all_contributors_list(owner, repo)

Get human and bot contributors separately.
"""
function get_all_contributors_list(owner, repo)
    try
        all_contributors = []
        page = 1
        per_page = 100

        while true
            data = github_request("/repos/$owner/$repo/contributors?per_page=$per_page&page=$page")
            isnothing(data) && break
            isempty(data) && break
            append!(all_contributors, data)
            length(data) < per_page && break
            page += 1
        end

        humans = []
        bots = []
        
        for c in all_contributors
            login = get(c, :login, "")
            isempty(login) && continue
            
            api_type = get(c, :type, "User")
            login_lower = lowercase(login)
            
            is_bot = (api_type == "Bot") || occursin("bot", login_lower) || occursin("[bot]", login_lower)
            
            if is_bot
                push!(bots, login)
            else
                push!(humans, login)
            end
        end
        
        human_list = isempty(humans) ? "" : join(humans, "; ")
        bot_list = isempty(bots) ? "" : join(bots, "; ")
        
        return (human_list, length(humans), bot_list, length(bots))
    catch e
        return ("", 0, "", 0)
    end
end

"""
    get_open_issues_count(owner, repo)

Count open issues and PRs separately.
"""
function get_open_issues_count(owner, repo)
    try
        all_issues = []
        page = 1
        per_page = 100

        while true
            data = github_request("/repos/$owner/$repo/issues?state=open&per_page=$per_page&page=$page")
            isnothing(data) && break
            isempty(data) && break
            append!(all_issues, data)
            length(data) < per_page && break
            page += 1
        end

        issues = filter(item -> !haskey(item, :pull_request), all_issues)
        prs = filter(item -> haskey(item, :pull_request), all_issues)

        return length(issues), length(prs)
    catch e
        return 0, 0
    end
end

"""
    get_closed_issues_count(owner, repo)

Count closed issues (not PRs).
"""
function get_closed_issues_count(owner, repo)
    try
        all_issues = []
        page = 1
        per_page = 100

        while true
            data = github_request("/repos/$owner/$repo/issues?state=closed&per_page=$per_page&page=$page")
            isnothing(data) && break
            isempty(data) && break
            append!(all_issues, data)
            length(data) < per_page && break
            page += 1
        end

        issues = filter(item -> !haskey(item, :pull_request), all_issues)
        return length(issues)
    catch e
        return 0
    end
end

"""
    get_closed_prs_count(owner, repo)

Count closed/merged PRs.
"""
function get_closed_prs_count(owner, repo)
    try
        all_prs = []
        page = 1
        per_page = 100

        while true
            data = github_request("/repos/$owner/$repo/pulls?state=closed&per_page=$per_page&page=$page")
            isnothing(data) && break
            isempty(data) && break
            append!(all_prs, data)
            length(data) < per_page && break
            page += 1
        end

        return length(all_prs)
    catch e
        return 0
    end
end

"""
    get_releases_count(owner, repo)

Count total releases for repository.
"""
function get_releases_count(owner, repo)
    data = github_request("/repos/$owner/$repo/releases?per_page=100")
    isnothing(data) && return 0
    return length(data)
end

"""
    get_latest_release_date(owner, repo)

Get date of latest release.
"""
function get_latest_release_date(owner, repo)
    data = github_request("/repos/$owner/$repo/releases")
    if isnothing(data) || isempty(data)
        return missing
    end
    return get(data[1], :published_at, missing)
end

"""
    has_gh_pages_branch(owner, repo)

Check if repository has a gh-pages branch.
"""
function has_gh_pages_branch(owner, repo)
    data = github_request("/repos/$owner/$repo/branches")
    isnothing(data) && return false
    return any(b -> get(b, :name, "") == "gh-pages", data)
end

"""
    has_code_coverage(owner, repo, tree_paths)

Check for code coverage config (standalone files or in workflows).
"""
function has_code_coverage(owner, repo, tree_paths)
    has_standalone = any(p -> startswith(p, ".codecov") || startswith(p, "codecov.yml") || startswith(p, ".codacy"), tree_paths)
    has_standalone && return true
    
    workflow_files = filter(p -> startswith(p, ".github/workflows/") && endswith(p, ".yml"), tree_paths)
    for workflow_file in workflow_files
        try
            data = github_request("/repos/$owner/$repo/contents/$workflow_file")
            isnothing(data) && continue
            
            content_encoded = get(data, :content, "")
            isempty(content_encoded) && continue
            
            content = String(base64decode(replace(content_encoded, "\n" => "")))
            
            if occursin("codecov", lowercase(content))
                return true
            end
        catch
            continue
        end
    end
    
    return false
end

"""
    detect_style_guide(owner, repo, tree_paths)

Read style from .JuliaFormatter.toml if it exists.
"""
function detect_style_guide(owner, repo, tree_paths)
    if any(p -> p == ".JuliaFormatter.toml", tree_paths)
        try
            data = github_request("/repos/$owner/$repo/contents/.JuliaFormatter.toml")
            isnothing(data) && return "none"

            content_encoded = get(data, :content, "")
            isempty(content_encoded) && return "none"

            content = String(base64decode(replace(content_encoded, "\n" => "")))
            config = TOML.parse(content)

            style = get(config, "style", "none")
            return string(style)
        catch
            return "none"
        end
    end

    return "none"
end

"""
    get_license_info(owner, repo)

Get license from GitHub API.
"""
function get_license_info(owner, repo)
    data = github_request("/repos/$owner/$repo")
    isnothing(data) && return "Unknown"
    
    license_info = get(data, :license, nothing)
    isnothing(license_info) && return "Unknown"
    
    spdx_id = get(license_info, :spdx_id, nothing)
    if !isnothing(spdx_id) && spdx_id != "NOASSERTION"
        return String(spdx_id)
    end
    
    license_name = get(license_info, :name, "Unknown")
    return String(license_name)
end

function assess_readme_completeness(readme_content)
    isempty(readme_content) && return (
        has_install=false, has_usage=false, has_contributing=false,
        lists_count=0, links_count=0, code_blocks_count=0,
        badges_count=0, sections_count=0, readme_size=0,
        completeness_score=0, has_code_blocks=false
    )
    
    content_lower = lowercase(readme_content)
    lines = split(readme_content, '\n')
    readme_size = length(lines)
    
    has_install = occursin(r"##\s*(install|getting\s+started|setup)"i, readme_content)
    has_usage = occursin(r"##\s*(usage|examples?|quick\s*start|tutorial)"i, readme_content)
    has_contributing = occursin(r"##\s*contribut"i, readme_content) || 
                       occursin("contributing.md", content_lower)
    
    lists_count = count(r"^[\s]*[-*+]\s+"m, readme_content) + 
                  count(r"^[\s]*\d+\.\s+"m, readme_content)
    
    links_count = count(r"\]\(https?://"i, readme_content)
    
    code_blocks_count = count(r"```"i, readme_content) ÷ 2
    has_code_blocks = code_blocks_count > 0
    
    badges_count = count(r"\[!\[.*?\]\(.*?\)\]"i, readme_content)
    
    sections_count = count(r"^##\s+"m, readme_content)
    
    score = 0
    has_install && (score += 1)
    has_usage && (score += 1)
    has_contributing && (score += 1)
    (lists_count >= 3) && (score += 1)
    (links_count >= 5) && (score += 1)
    (code_blocks_count >= 2) && (score += 1)
    (badges_count >= 1) && (score += 1)
    (sections_count >= 4) && (score += 1)
    
    return (
        has_install=has_install,
        has_usage=has_usage,
        has_contributing=has_contributing,
        lists_count=lists_count,
        links_count=links_count,
        code_blocks_count=code_blocks_count,
        badges_count=badges_count,
        sections_count=sections_count,
        readme_size=readme_size,
        completeness_score=score,
        has_code_blocks=has_code_blocks
    )
end

function get_pr_metrics(org, repo)
    avg_merge_days = missing
    avg_response_days = missing
    
    page = 1
    all_prs = []
    while true
        data = github_request("/repos/$org/$repo/pulls?state=all&per_page=100&page=$page&sort=updated&direction=desc")
        isnothing(data) && break
        isempty(data) && break
        append!(all_prs, data)
        length(data) < 100 && break
        page += 1
    end
    
    if !isempty(all_prs)
        merge_times = []
        response_times = []
        merge_times_sum = 0.0
        merge_times_count = 0
        
        for pr in all_prs
            merged_at = get(pr, :merged_at, nothing)
            created_at_str = get(pr, :created_at, "")
            updated_at_str = get(pr, :updated_at, "")
            
            if !isnothing(merged_at) && !isempty(merged_at)
                try
                    created = DateTime(string(created_at_str)[1:end-1])
                    merged = DateTime(string(merged_at)[1:end-1])
                    days = Dates.value(merged - created) / (1000 * 60 * 60 * 24)
                    if days >= 0
                        push!(merge_times, days)
                        merge_times_sum += days
                        merge_times_count += 1
                    end
                catch
                end
            end
            
            created_at_str = get(pr, :created_at, "")
            if !isempty(created_at_str)
                try
                    created = DateTime(string(created_at_str)[1:end-1])
                    now_utc = now(UTC)
                    days_open = Dates.value(now_utc - created) / (1000 * 60 * 60 * 24)
                    
                    if isnothing(merged_at) || isempty(merged_at)
                        if days_open > 60
                            stale_pr_count += 1
                        end
                    end
                    
                    if days_open >= 0
                        push!(response_times, min(days_open, 30.0))
                    end
                catch
                end
            end
        end
        
        if !isempty(merge_times)
            avg_merge_days = merge_times_sum / merge_times_count
        end
        
        if !isempty(response_times)
            avg_response_days = sum(response_times) / length(response_times)
        end
    end
    
    return (
        avg_merge_days=avg_merge_days,
        avg_response_days=avg_response_days
    )
end

"""
    get_last_activity_date(org, repo)

Get days since last activity from recent events or commits.
Returns NamedTuple with days_since_activity field.
"""
function get_last_activity_date(org, repo)
    days_since = missing

    try
        events_data = github_request("/repos/$org/$repo/events?per_page=100")
        if !isnothing(events_data) && !isempty(events_data)
            last_event = events_data[1]
            created_at_str = get(last_event, :created_at, "")
            if !isempty(created_at_str)
                try
                    last_activity = DateTime(string(created_at_str)[1:end-1])
                    now_utc = now(UTC)
                    days_since = Dates.value(now_utc - last_activity) / (1000 * 60 * 60 * 24)
                catch
                end
            end
        end
    catch
    end

    if ismissing(days_since)
        try
            commits_data = github_request("/repos/$org/$repo/commits?per_page=1")
            if !isnothing(commits_data) && !isempty(commits_data)
                commit = commits_data[1]
                commit_info = get(commit, :commit, Dict())
                committer = get(commit_info, :committer, Dict())
                date_str = get(committer, :date, "")
                if !isempty(date_str)
                    last_activity = DateTime(string(date_str)[1:end-1])
                    now_utc = now(UTC)
                    days_since = Dates.value(now_utc - last_activity) / (1000 * 60 * 60 * 24)
                end
            end
        catch
        end
    end

    return (days_since_activity=days_since,)
end