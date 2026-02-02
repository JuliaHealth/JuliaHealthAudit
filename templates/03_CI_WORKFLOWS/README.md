# CI Workflows for JuliaHealth Packages

This directory contains GitHub Actions workflow templates for common CI/CD tasks.

## Available Workflows

### 1. CI.yml - Basic Testing
**Purpose**: Run package tests across multiple Julia versions and operating systems

**What it does:**
- Tests on Ubuntu, Windows, and macOS
- Tests Julia versions: 1.6, 1, nightly
- Caches dependencies for faster builds
- Runs on every push to `main` and all pull requests

**Setup:**
1. Copy to `.github/workflows/CI.yml` in your repo
2. Commit and push
3. Tests will run automatically

### 2. Documentation.yml - Build & Deploy Docs
**Purpose**: Build documentation with Documenter.jl and deploy to GitHub Pages

**What it does:**
- Builds docs on every push to `main`
- Deploys to `gh-pages` branch
- Runs on tags for versioned docs
- Preview docs on pull requests (if configured)

**Setup:**
1. Copy to `.github/workflows/Documentation.yml`
2. Set up Documenter key:
   ```julia
   using DocumenterTools
   DocumenterTools.genkeys(user="JuliaHealth", repo="YourPackage.jl")
   ```
3. Add the **public key** to `docs/make.jl`
4. Add the **private key** as `DOCUMENTER_KEY` secret in GitHub repo settings
5. Enable GitHub Pages in repo settings (source: `gh-pages` branch)

**Requirements:**
- `docs/` directory with `make.jl` and `Project.toml`
- Documenter.jl configured

### 3. Coverage.yml - Code Coverage Tracking
**Purpose**: Measure test coverage and report to Codecov

**What it does:**
- Runs tests with coverage enabled
- Uploads coverage report to Codecov
- Generates `lcov.info` file

**Setup:**
1. Copy to `.github/workflows/Coverage.yml`
2. Sign up at [codecov.io](https://codecov.io) with your GitHub account
3. Add your repository to Codecov
4. Add coverage badge to README:
   ```markdown
   [![Coverage](https://codecov.io/gh/JuliaHealth/YourPackage.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaHealth/YourPackage.jl)
   ```

**No secrets needed** - Codecov GitHub Action works automatically for public repos

### 4. FormatCheck.yml - Code Style Verification
**Purpose**: Ensure code follows JuliaFormatter style guidelines

**What it does:**
- Checks if code is properly formatted
- Runs on pull requests only
- Fails if formatting is needed

**Setup:**
1. Copy to `.github/workflows/FormatCheck.yml`
2. Add `.JuliaFormatter.toml` to your repo root (see `01_PACKAGE_TEMPLATE/`)
3. Contributors will be notified if their PR needs formatting

**To fix formatting locally:**
```julia
using JuliaFormatter
format(".")
```

All these can be customized as per the package usecase! 
