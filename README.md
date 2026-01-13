# JuliaHealth Ecosystem Audit

**Project**: Improving JuliaHealth Documentation Accessibility for Community Onboarding  
**Prepared by**: [@kosuri-indu](https://github.com/kosuri-indu)

## What This Is

A fully automated, reproducible audit of the **JuliaHealth ecosystem** that analyzes **60 repositories** (48 packages + 12 non-packages) across **36-21 metrics** including documentation, CI/testing, code structure, project maturity, activity metrics, and code quality.

**Use case**: Identify ecosystem strengths/weaknesses, guide community contributions, and support grant-funded improvements.

## Quick Start

1. **Instantiate Julia environment**:

   ```bash
   julia --project=. -e 'using Pkg; Pkg.instantiate()'
   ```

2. **Add GitHub API token** to `.env`:

   ```
   GITHUB_TOKEN=github_pat_11A4J...
   ```

   Get one at [github.com/settings/tokens](https://github.com/settings/tokens)

3. **Run audit**:
   ```bash
   julia --project=. scripts/main.jl
   ```

## What Gets Audited

6 categories across **36 package metrics** and **21 non-package metrics**:

- **Documentation**: README, docs/, Documenter.jl, CONTRIBUTING.md, CODE_OF_CONDUCT
- **CI/Testing**: GitHub Actions, code coverage, test suite
- **Structure**: src/, test/, Project.toml, standard layout
- **Maturity**: Release history, first/latest release dates, commit activity
- **Activity**: Stars, contributors, open/closed issues, PR resolution rates
- **Quality**: Code style, README examples

**Full metric definitions**: [AUDIT_DIMENSIONS.md](AUDIT_DIMENSIONS.md)

## Repository Layout

```
scripts/
  ├── main.jl                      ← Run this
  ├── shared.jl                    ← Common utilities
  ├── discovery/
  │   ├── discover_org.jl
  │   └── discover_registry.jl
  └── audit/
      ├── 01_filter_targets.jl
      ├── 02_audit_packages.jl     ← 36 metrics
      └── 03_audit_non_packages.jl ← 21 metrics

data/
  ├── baselines/
  │   ├── org_repositories.csv
  │   ├── registry_packages.csv
  │   └── registry_mismatches.csv
  └── results/
      ├── audit_packages.csv       ← Output
      └── audit_non_packages.csv   ← Output
```

