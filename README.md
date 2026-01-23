# JuliaHealth Ecosystem Audit

**Project**: Improving JuliaHealth Documentation Accessibility for Community Onboarding  
**Prepared by**: [@kosuri-indu](https://github.com/kosuri-indu)

## What This Is

A fully automated, reproducible audit of the **JuliaHealth ecosystem** that analyzes repositories across metrics including documentation, CI/testing, code coverage, code structure, project maturity, activity metrics and code quality. **Use case**: Identify ecosystem strengths/weaknesses, guide community contributions, and support grant-funded improvements.

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

**Status**: Check the workflow run for logs and progress. 

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

The audit evaluates each JuliaHealth repository across these categories:

- **Documentation & README**: Docs presence/quality, Documenter.jl usage, gh-pages, README completeness, CONTRIBUTING.md, CODE_OF_CONDUCT
- **CI/CD, Testing & Coverage**: GitHub Actions workflows, CI status/adoption, coverage configs/mentions
- **Structure, Licensing & Maturity**: Standard layout (src/test/Project.toml), General Registry status, maturity tiers, license presence/types
- **Activity, Releases & Engagement**: Recent pushes, release counts, stars, contributor counts/distribution
- **Issues & PR Health**: Open vs closed issues/PRs, review/triage signals
- **Contributors (Cross-Ecosystem)**: Top by total and repo count, contribution distribution, engagement tiers

See full metric definitions: [AUDIT_DIMENSIONS.md](AUDIT_DIMENSIONS.md)

## Repository Layout

```
scripts/
  ├── main.jl                         
  ├── utils.jl                        
  ├── audit/
  │   ├── 01_separate_packages.jl    
  │   ├── 02_discover_registry.jl        
  │   ├── 03_audit_packages.jl       
  │   ├── 04_audit_non_packages.jl    
  │   ├── 05_audit_contributors.jl    
  │   └── generate_audit_lists.jl     
  └── visualizations/
      ├── viz_packages.jl             
      ├── viz_nonpackages.jl
      ├── viz_contributors.jl         
      └── visualize.jl        

data/
  ├── results/
  │   ├── lists/ 
  │       └── *.txt                    
  │   ├── packages.csv                
  │   ├── non_packages.csv            
  │   ├── registry_packages.csv   
  │   ├── registry_mismatches.csv     
  │   ├── audit_packages.csv          
  │   ├── audit_non_packages.csv      
  │   └── audit_contributors.csv      
  └── visualizations/
      └── *.png                       
```

## Results

Browse all charts in [RESULTS.md](RESULTS.md). They are grouped by Packages, Non-Packages and Contributors.
