# JuliaHealth Audit Dimensions

## Packages Audit (`03_audit_packages.jl`)

**Target:** Julia packages with `.jl` suffix  
**Output:** `data/results/audit_packages.csv`

### Package Audit Metrics (selected)

| Metric Name               | Type    | Description                                  |
| ------------------------- | ------- | -------------------------------------------- |
| package_name              | String  | Package name (includes `.jl`)                |
| github_repo_url           | String  | Full GitHub repository URL                   |
| in_general_registry       | Boolean | Registered in General Registry               |
| is_fork                   | Boolean | Repository is a fork                         |
| is_archived               | Boolean | Repository archived                          |
| license_type              | String  | License SPDX ID (e.g., MIT, Apache-2.0)      |
| has_src_dir               | Boolean | `src/` directory exists                      |
| has_test_dir              | Boolean | `test/` directory exists                     |
| has_project_toml          | Boolean | `Project.toml` exists                        |
| has_license               | Boolean | LICENSE file exists                          |
| follows_standard_layout   | Boolean | Standard layout checks aggregated            |
| has_docs_dir              | Boolean | `docs/` directory exists                     |
| has_gh_pages              | Boolean | `gh-pages` branch exists                     |
| uses_documenter           | Boolean | `docs/make.jl` exists                        |
| has_contributing_md       | Boolean | `CONTRIBUTING.md` exists                     |
| has_code_of_conduct       | Boolean | `CODE_OF_CONDUCT.md` exists                  |
| has_ci_workflow           | Boolean | `.github/workflows/` exists                  |
| has_code_coverage         | Boolean | Code coverage configured (codecov/codacy)    |
| releases_count            | Integer | Total number of releases                     |
| latest_release_date       | Date    | Date of latest release                       |
| pushed_at                 | Date    | Last push date                               |
| stars                     | Integer | GitHub stars                                 |
| contributors_count        | Integer | Human contributors only                      |
| bot_contributors_count    | Integer | Bot contributors only                        |
| open_issues_count         | Integer | Open issues (excluding PRs)                  |
| closed_issues_count       | Integer | Closed issues                                |
| issue_resolution_rate     | Float   | % issues resolved                            |
| open_prs_count            | Integer | Open pull requests                           |
| closed_prs_count          | Integer | Closed / merged PRs                          |
| pr_resolution_rate        | Float   | % PRs resolved                               |
| style_guide_type          | String  | Code style (blue, sciml, default, or none)   |
| readme_has_install        | Boolean | README has installation section              |
| readme_has_usage          | Boolean | README has usage/examples section            |
| readme_has_contributing   | Boolean | README has contributing section              |
| readme_lists_count        | Integer | Number of lists                              |
| readme_links_count        | Integer | Number of external links                     |
| readme_code_blocks_count  | Integer | Number of code blocks                        |
| readme_badges_count       | Integer | Number of badges                             |
| readme_sections_count     | Integer | Number of section headers (##)               |
| readme_size               | Integer | Total lines in README                        |
| readme_completeness_score | Integer | Completeness score (0–8)                     |
| avg_pr_merge_days         | Float   | Average PR merge time (days)                 |
| days_since_last_activity  | Float   | Days since last repo activity                |

## Non-Packages Audit (`04_audit_non_packages.jl`)

**Target:** Non-Julia repositories (websites, tools, docs)  
**Output:** `data/results/audit_non_packages.csv`

### Non-Packages Audit Metrics (selected)

| Metric Name               | Type    | Description                |
| ------------------------- | ------- | -------------------------- |
| repo_name                 | String  | Repository name            |
| github_repo_url           | String  | Full GitHub repository URL |
| is_archived               | Boolean | Repository archived        |
| license_type              | String  | License SPDX ID            |
| has_license               | Boolean | LICENSE file exists        |
| pushed_at                 | Date    | Last push date             |
| stars                     | Integer | GitHub stars               |
| contributors_count        | Integer | Human contributors only    |
| bot_contributors_count    | Integer | Bot contributors only      |
| open_issues_count         | Integer | Open issues                |
| closed_issues_count       | Integer | Closed issues              |
| issue_resolution_rate     | Float   | % issues resolved          |
| open_prs_count            | Integer | Open PRs                   |
| closed_prs_count          | Integer | Closed PRs                 |
| pr_resolution_rate        | Float   | % PRs resolved             |
| has_ci_workflow           | Boolean | CI workflow exists         |
| readme_has_install        | Boolean | README has installation    |
| readme_has_usage          | Boolean | README has usage/examples  |
| readme_has_contributing   | Boolean | README has contributing    |
| readme_lists_count        | Integer | Number of lists            |
| readme_links_count        | Integer | Number of links            |
| readme_code_blocks_count  | Integer | Number of code blocks      |
| readme_badges_count       | Integer | Number of badges           |
| readme_sections_count     | Integer | Number of sections         |
| readme_size               | Integer | Total lines                |
| readme_completeness_score | Integer | Completeness score (0–8)   |
| avg_pr_merge_days         | Float   | Average PR merge time (days) |
| days_since_last_activity  | Float   | Days since last repo activity |

## Contributors Summary (`05_audit_contributors.jl`)

**Target:** Cross-ecosystem contributors 
**Output:** `data/results/audit_contributors.csv`

### Contributor Fields

| Metric Name             | Type    | Description                                 |
| ----------------------- | ------- | ------------------------------------------- |
| login                   | String  | GitHub username                             |
| name                    | String  | Display name (if available)                 |
| num_repos_contributed   | Integer | Number of JuliaHealth repos contributed to  |
| total_contributions     | Integer | Total contributions across those repos      |
| repos_list              | String  | Semicolon-separated list of repos           |
| profile_url             | String  | GitHub profile URL                          |
