# JuliaHealth Ecosystem Audit

**Project**: Improving JuliaHealth Documentation Accessibility for Community Onboarding  
**Prepared by**: [@kosuri-indu](https://github.com/kosuri-indu)

## What This Is

A fully automated, reproducible audit of the **JuliaHealth ecosystem** that analyzes repositories across metrics including documentation, CI/testing, code coverage, code structure, project maturity, activity metrics and code quality.

**Use case**: Identify ecosystem strengths/weaknesses, guide community contributions, and support grant-funded improvements.

## Run the Audit

### GitHub Actions

The audit runs automatically via **GitHub Actions** with a manual trigger:

1. Go to the **Actions** tab in the GitHub repository
2. Select the **"JuliaHealth Audit"** workflow
3. Click **"Run workflow"** button
4. Select your branch (default: `main`)
5. Click **"Run workflow"**

The workflow will:
- Run the full audit pipeline
- Generate all visualizations
- Commit results back to the repository
- Update `RESULTS.md` with latest findings

**Status**: Check the workflow run for logs and progress. Typical runtime: 3~5 minutes.

### Local Development

For developers running the audit on their machine:

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

6 categories across **37 package metrics** and **14 non-package metrics**:

- **Documentation**: README, docs/, Documenter.jl, CONTRIBUTING.md, CODE_OF_CONDUCT
- **CI/Testing**: GitHub Actions, code coverage (codecov), test suite
- **Structure**: src/, test/, Project.toml, standard layout
- **Maturity**: Release history, first/latest release dates, commit activity
- **Activity**: Stars, contributors, open/closed issues, PR resolution rates
- **Quality**: Code style, README examples

**Full metric definitions**: [AUDIT_DIMENSIONS.md](AUDIT_DIMENSIONS.md)

## Repository Layout

```
scripts/
  ├── main.jl                         ← Run this
  ├── utils.jl                        ← Shared utilities
  ├── discovery/
  │   ├── discover_org.jl
  │   └── discover_registry.jl
  ├── audit/
  │   ├── 01_separate_packages.jl
  │   ├── 02_audit_packages.jl        
  │   └── 03_audit_non_packages.jl    
  └── visualizations/
      ├── viz_packages.jl             
      ├── viz_nonpackages.jl          
      └── visualize.jl        

data/
  ├── baselines/
  │   ├── org_repositories.csv
  │   ├── registry_packages.csv
  │   └── registry_mismatches.csv
  ├── results/
  │   ├── packages.csv                ← Intermediate 
  │   ├── non_packages.csv            ← Intermediate 
  │   ├── audit_packages.csv          ← Final audit output
  │   └── audit_non_packages.csv      ← Final audit output
  └── visualizations/
      └── *.png                       
```

## Maintainer Notes

### General Registry Data

The **General Registry** baseline data (`data/baselines/registry_packages.csv`) is **pre-discovered** from the [Julia General Registry](https://github.com/JuliaRegistries/General). This data identifies which JuliaHealth packages are officially registered.

**Important**: The registry data should be **updated periodically** (recommended: quarterly or after major ecosystem changes) to:
- Capture newly registered packages
- Track registry status changes
- Ensure accurate maturity classifications

**To update registry data**:
```bash
julia scripts/discovery/discover_registry.jl
```

This regenerates `data/baselines/registry_packages.csv` with current registry information.

### Registry Mismatches

Some packages may be registered under different names than their repository names. These are tracked in `data/baselines/registry_mismatches.csv` and manually curated as needed. Update this file when discovering new name mismatches during audit runs.
