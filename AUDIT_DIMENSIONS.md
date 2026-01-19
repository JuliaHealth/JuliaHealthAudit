# JuliaHealth Audit Dimensions

## Overview

This document defines the audit metrics for both **Packages** (`.jl` repositories) and **Non-Packages** (other JuliaHealth repositories such as websites, tools, and documentation). The audit is **fully automated, reproducible, and GitHub-API driven**.

## Packages Audit (`02_audit_packages.jl`)

**Target:** Julia packages with `.jl` suffix  
**Metrics:** 31 dimensions  
**Output:** `data/results/audit_packages.csv`

### Package Audit Metrics

| #   | Metric Name              | Type    | Category      | Description                                  |
| --- | ------------------------ | ------- | ------------- | -------------------------------------------- |
| 1   | package_name             | String  | Identity      | Package name (includes `.jl`)                |
| 2   | github_repo_url          | String  | Identity      | Full GitHub repository URL                   |
| 3   | in_general_registry      | Boolean | Identity      | Registered in General Registry               |
| 4   | is_fork                  | Boolean | Identity      | Repository is a fork                         |
| 5   | is_archived              | Boolean | Identity      | Repository archived                          |
| 6   | has_src_dir              | Boolean | Structure     | `src/` directory exists                      |
| 7   | has_test_dir             | Boolean | Structure     | `test/` directory exists                     |
| 8   | has_project_toml         | Boolean | Structure     | `Project.toml` exists                        |
| 9   | has_license              | Boolean | Structure     | LICENSE file exists                          |
| 10  | follows_standard_layout  | Boolean | Structure     | Has `src/`, `test/`, `docs/`, `Project.toml`, ci, documenter, codecov |
| 11  | has_docs_dir             | Boolean | Documentation | `docs/` directory exists                     |
| 12  | has_gh_pages             | Boolean | Documentation | `gh-pages` branch exists                     |
| 13  | uses_documenter          | Boolean | Documentation | `docs/make.jl` exists                        |
| 14  | has_contributing_md      | Boolean | Documentation | `CONTRIBUTING.md` exists                     |
| 15  | has_code_of_conduct      | Boolean | Documentation | `CODE_OF_CONDUCT.md` exists                  |
| 16  | has_ci_workflow          | Boolean | CI/Testing    | `.github/workflows/` exists                  |
| 17  | has_code_coverage        | Boolean | CI/Testing    | Code coverage (codecov/codacy) configured    |
| 18  | releases_count           | Integer | Maturity      | Total number of releases                     |
| 19  | latest_release_date      | Date    | Maturity      | Date of latest release                       |
| 20  | pushed_at                | Date    | Activity      | Last push date                               |
| 21  | stars                    | Integer | Activity      | GitHub stars                                 |
| 22  | contributors_count       | Integer | Activity      | Number of contributors                       |
| 23  | open_issues_count        | Integer | Activity      | Open issues (excluding PRs)                  |
| 24  | closed_issues_count      | Integer | Activity      | Closed issues                                |
| 25  | issue_resolution_rate    | Float   | Activity      | % issues resolved                            |
| 26  | open_prs_count           | Integer | Activity      | Open pull requests                           |
| 27  | closed_prs_count         | Integer | Activity      | Closed / merged PRs                          |
| 28  | pr_resolution_rate       | Float   | Activity      | % PRs resolved                               |
| 29  | readme_has_code_blocks   | Boolean | Quality       | README contains code blocks                  |
| 30  | readme_line_count        | Integer | Quality       | Number of lines in README                    |
| 31  | style_guide_type         | String  | Quality       | Code style (blue, sciml, default, Runic, or none) |

### Package Metrics by Category

| Category      | Count  | Metrics                                                                                                                       |
| ------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------- |
| Identity      | 5      | package_name, github_repo_url, in_general_registry, is_fork, is_archived                                                     |
| Structure     | 5      | has_src_dir, has_test_dir, has_project_toml, has_license, follows_standard_layout                                            |
| Documentation | 5      | has_docs_dir, has_gh_pages, uses_documenter, has_contributing_md, has_code_of_conduct                                        |
| CI/Testing    | 2      | has_ci_workflow, has_code_coverage                                                                                            |
| Maturity      | 2      | releases_count, latest_release_date                                                                                           |
| Activity      | 9      | pushed_at, stars, contributors_count, open_issues_count, closed_issues_count, issue_resolution_rate, open_prs_count, closed_prs_count, pr_resolution_rate |
| Quality       | 3      | readme_has_code_blocks, readme_line_count, style_guide_type                                                                   |
| **Total**     | **32** | —                                                                                                                                                         |

## Non-Packages Audit (`03_audit_non_packages.jl`)

**Target:** Non-Julia repositories (websites, tools, docs)  
**Metrics:** 14 dimensions  
**Output:** `data/results/audit_non_packages.csv`

### Non-Packages Audit Metrics

| #   | Metric Name           | Type    | Category      | Description                |
| --- | --------------------- | ------- | ------------- | -------------------------- |
| 1   | repo_name             | String  | Identity      | Repository name            |
| 2   | github_repo_url       | String  | Identity      | Full GitHub repository URL |
| 3   | is_archived           | Boolean | Identity      | Repository archived        |
| 4   | has_license           | Boolean | Structure     | LICENSE file exists        |
| 5   | pushed_at             | Date    | Activity      | Last push date             |
| 6   | stars                 | Integer | Activity      | GitHub stars               |
| 7   | contributors_count    | Integer | Activity      | Contributors count         |
| 8   | open_issues_count     | Integer | Activity      | Open issues                |
| 9   | closed_issues_count   | Integer | Activity      | Closed issues              |
| 10  | issue_resolution_rate | Float   | Activity      | % issues resolved          |
| 11  | open_prs_count        | Integer | Activity      | Open PRs                   |
| 12  | closed_prs_count      | Integer | Activity      | Closed PRs                 |
| 13  | pr_resolution_rate    | Float   | Activity      | % PRs resolved             |
| 14  | has_ci_workflow       | Boolean | CI/CD         | CI workflow exists         |

### Non-Package Metrics by Category

| Category      | Count  | Metrics                                                                                                                       |
| ------------- | ------ | ----------------------------------------------------------------------------------------------------------------------------- |
| Identity      | 3      | repo_name, github_repo_url, is_archived                                                                                     |
| Structure     | 1      | has_license                                                                                                                   |
| Activity      | 9      | pushed_at, stars, contributors_count, open_issues_count, closed_issues_count, issue_resolution_rate, open_prs_count, closed_prs_count, pr_resolution_rate |
| CI/CD         | 1      | has_ci_workflow                                                                                                               |
| **Total**     | **14** | —                                                                                                                                                         |
