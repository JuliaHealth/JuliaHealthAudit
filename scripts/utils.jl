# scripts/utils.jl
# Common utilities and GitHub API functions for the audit pipeline

using DotEnv
using HTTP
using JSON3
using Base64
using TOML

const GITHUB_API = "https://api.github.com"

"""
    load_env_vars()

Load environment variables from .env file in project root.
Ensures GITHUB_TOKEN is available for all scripts.
"""
function load_env_vars()
    DotEnv.load!()
    token = get(ENV, "GITHUB_TOKEN", "")
    token == "" && error("GITHUB_TOKEN not set in .env file")
    return token
end

# Initialize token as module-level variable
const GITHUB_TOKEN = load_env_vars()

# ===================================================================
# GitHub API Functions
# ===================================================================

"""
    parse_repo_url(url)

Extract owner and repo name from GitHub URL.
"""
function parse_repo_url(url)
    parts = split(replace(url, ".git" => ""), "/")
    owner = parts[end - 1]
    repo = parts[end]
    return owner, repo
end

"""
    github_request(endpoint)

Make authenticated GitHub API request.
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

Fetch basic repository information from GitHub API.
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

Get repository file tree recursively.
"""
function get_tree(owner, repo, branch)
    data = github_request("/repos/$owner/$repo/git/trees/$branch?recursive=1")
    isnothing(data) && return String[]

    tree = get(data, :tree, [])
    return [String(item.path) for item in tree]
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
    get_contributors_count(owner, repo)

Count total contributors by paginating through all pages.
"""
function get_contributors_count(owner, repo)
    try
        all_contributors = []
        page = 1
        per_page = 100

        while true
            data = github_request(
                "/repos/$owner/$repo/contributors?per_page=$per_page&page=$page"
            )
            isnothing(data) && break
            isempty(data) && break

            append!(all_contributors, data)

            length(data) < per_page && break
            page += 1
        end

        return length(all_contributors)
    catch e
        return 0
    end
end

"""
    get_open_issues_count(owner, repo)

Get count of open issues and PRs separately (GitHub API includes PRs in issues).
Returns (issues_count, prs_count).
"""
function get_open_issues_count(owner, repo)
    try
        all_issues = []
        page = 1
        per_page = 100

        while true
            data = github_request(
                "/repos/$owner/$repo/issues?state=open&per_page=$per_page&page=$page"
            )
            isnothing(data) && break
            isempty(data) && break

            append!(all_issues, data)

            length(data) < per_page && break
            page += 1
        end

        actual_issues = filter(item -> !haskey(item, :pull_request), all_issues)
        actual_prs = filter(item -> haskey(item, :pull_request), all_issues)

        return length(actual_issues), length(actual_prs)
    catch e
        return 0, 0
    end
end

"""
    get_closed_issues_count(owner, repo)

Get count of closed issues (excluding PRs).
"""
function get_closed_issues_count(owner, repo)
    try
        all_issues = []
        page = 1
        per_page = 100

        while true
            data = github_request(
                "/repos/$owner/$repo/issues?state=closed&per_page=$per_page&page=$page"
            )
            isnothing(data) && break
            isempty(data) && break

            append!(all_issues, data)

            length(data) < per_page && break
            page += 1
        end

        actual_issues = filter(item -> !haskey(item, :pull_request), all_issues)
        return length(actual_issues)
    catch e
        return 0
    end
end

"""
    get_closed_prs_count(owner, repo)

Get count of closed/merged PRs.
"""
function get_closed_prs_count(owner, repo)
    try
        all_prs = []
        page = 1
        per_page = 100

        while true
            data = github_request(
                "/repos/$owner/$repo/pulls?state=closed&per_page=$per_page&page=$page"
            )
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
    check_readme_quality(content)

Check if README has code blocks and count lines.
Returns (has_code_blocks, line_count).
"""
function check_readme_quality(content)
    isempty(content) && return false, 0
    lines = split(content, "\n")
    has_code = occursin("```", content) || occursin("    ", content)
    return has_code, length(lines)
end

"""
    has_code_coverage(owner, repo, tree_paths)

Check if repository has code coverage configuration.
Detects:
  - Standalone config files: .codecov, codecov.yml, .codacy
  - Codecov in workflow files
"""
function has_code_coverage(owner, repo, tree_paths)
    has_standalone = any(p -> startswith(p, ".codecov") || startswith(p, "codecov.yml") || startswith(p, ".codacy"), tree_paths)
    has_standalone && return true
    
    # Check for codecov in workflow files
    workflow_files = filter(p -> startswith(p, ".github/workflows/") && endswith(p, ".yml"), tree_paths)
    for workflow_file in workflow_files
        try
            data = github_request("/repos/$owner/$repo/contents/$workflow_file")
            isnothing(data) && continue
            
            content_encoded = get(data, :content, "")
            isempty(content_encoded) && continue
            
            content = String(base64decode(replace(content_encoded, "\n" => "")))
            
            # Check if codecov is mentioned in the workflow
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

Detect code style guide (reads actual style from .JuliaFormatter.toml).
Returns style name like "blue", "sciml" or "none".
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

