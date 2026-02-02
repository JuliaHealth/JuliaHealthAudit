# Package Checklist

Two comprehensive checklists for JuliaHealth packages: one for creating new packages, and one for upgrading existing packages to meet JuliaHealth standards.

## New Package Checklist

Use this when creating a package from scratch.

### Phase 1: Initial Setup

#### Package Structure
- [ ] Create package using PkgTemplates.jl or manually
- [ ] Initialize git repository
- [ ] Create `src/` directory
- [ ] Create main module file (`src/YourPackage.jl`)
- [ ] Create `Project.toml` with metadata
- [ ] Generate UUID for `Project.toml`:
  ```julia
  using UUIDs; uuid4()
  ```
- [ ] Add package description and version (0.1.0)
- [ ] Set Julia version in `[compat]`

#### Legal & Community
- [ ] Add `LICENSE` file (MIT recommended for JuliaHealth)
- [ ] Create `README.md` with:
  - [ ] Badges section (build, coverage, docs, license)
  - [ ] Installation instructions
  - [ ] Quick start example with code blocks
  - [ ] Features list
  - [ ] Links to documentation
  - [ ] Contributing guidelines
  - [ ] Section headers
- [ ] Add `CODE_OF_CONDUCT.md` (use template)
- [ ] Add `CONTRIBUTING.md` (use template)
- [ ] Create `.gitignore` for Julia projects

### Phase 2: Code Quality

#### Testing
- [ ] Create `test/` directory
- [ ] Create `test/runtests.jl`
- [ ] Add Test to `[extras]` in `Project.toml`
- [ ] Write tests for all exported functions
- [ ] Run tests locally: `using Pkg; Pkg.test()`
- [ ] Aim for >80% (mostly 100%) code coverage

#### Code Style
- [ ] Add `.JuliaFormatter.toml` with Blue style
- [ ] Format all code:
  ```julia
  using JuliaFormatter; format(".")
  ```
- [ ] Review code for type stability
- [ ] Add docstrings to all exported functions

### Phase 3: CI/CD

#### GitHub Actions
- [ ] Create `.github/workflows/` directory
- [ ] Add `CI.yml` workflow (tests on multiple Julia versions & OS)
- [ ] Add `Documentation.yml` workflow
- [ ] Add `Coverage.yml` workflow
- [ ] Add `FormatCheck.yml` workflow
- [ ] Additional workflows in case
- [ ] Push to GitHub and verify all workflows pass

#### Coverage
- [ ] Sign up for Codecov with GitHub account
- [ ] Add repository to Codecov
- [ ] Verify coverage reports upload
- [ ] Add coverage badge to README

### Phase 4: Documentation

#### Setup Documenter.jl
- [ ] Create `docs/` directory
- [ ] Create `docs/Project.toml` with dependencies
- [ ] Create `docs/make.jl` build script
- [ ] Create `docs/src/` directory
- [ ] Create `docs/src/index.md` (home page)
- [ ] Create `docs/src/getting-started.md`
- [ ] Create `docs/src/api.md` (API reference)
- [ ] Create `docs/src/examples.md`
- [ ] Build docs locally to verify:
  ```julia
  cd("docs/"); include("make.jl")
  ```

#### Deploy to GitHub Pages
- [ ] Generate Documenter key:
  ```julia
  using DocumenterTools
  DocumenterTools.genkeys(user="JuliaHealth", repo="YourPackage.jl")
  ```
- [ ] Add private key as `DOCUMENTER_KEY` secret in GitHub repo settings
- [ ] Configure `deploydocs()` in `docs/make.jl`
- [ ] Push and verify docs deploy to gh-pages branch
- [ ] Enable GitHub Pages in repo settings (source: gh-pages)
- [ ] Add docs badge to README
- [ ] Verify docs accessible at juliahealth.org/YourPackage.jl

### Phase 5: Registration

#### Prepare for Registration
- [ ] Ensure package name follows Julia conventions
- [ ] Verify all tests pass
- [ ] Verify documentation builds
- [ ] Tag version 0.1.0:
  ```bash
  git tag -a v0.1.0 -m "First release"
  git push origin v0.1.0
  ```
- [ ] Create release on GitHub
- [ ] Update in JuliaRegistries/General to make the package available in General Registry

### Phase 6: Community

#### Announce Package
- [ ] Post on Julia Discourse in JuliaHealth category
- [ ] Share in #health-and-medicine Slack channel
- [ ] Add to JuliaHealth website package list (if applicable)

#### Maintenance Setup
- [ ] Enable GitHub Discussions for community Q&A
- [ ] Add issue templates (.github/ISSUE_TEMPLATE/)
- [ ] Add PR template (.github/PULL_REQUEST_TEMPLATE.md)
- [ ] Set up milestone for v0.2.0
- [ ] Label issues (`good first issue`, `help wanted`, `bug`, `enhancement`)

## Existing Package Upgrade Checklist

Use this to bring an existing package up to JuliaHealth standards.

### Assessment Phase

#### Current State
- [ ] Review directory structure
- [ ] Check which standards are missing:
  - [ ] CI workflows
  - [ ] Documentation
  - [ ] Tests
  - [ ] Code coverage
  - [ ] Contributing guidelines
  - [ ] Code of conduct
- [ ] Review audit results for your package in `data/results/audit_packages.csv`
- [ ] Check maintenance status in `data/results/lists/maintenance_status.csv`

#### Documentation Improvements
- [ ] Improve README completeness (aim for 8/8 score):
  - [ ] Add installation section
  - [ ] Add usage examples with code blocks
  - [ ] Add features list
  - [ ] Add links (docs, issues, community)
  - [ ] Add badges (CI, coverage, docs, license)
  - [ ] Add contributing link
  - [ ] Ensure clear section headers
- [ ] Fix broken links in README
- [ ] Add missing badges

#### Community Files
- [ ] Add `CONTRIBUTING.md` if missing (use template)
- [ ] Add `CODE_OF_CONDUCT.md` if missing (use template)
- [ ] Add `.gitignore` for Julia artifacts

#### Code Formatting
- [ ] Add `.JuliaFormatter.toml` (Blue style)
- [ ] Format entire codebase:
  ```julia
  using JuliaFormatter; format(".")
  ```
- [ ] Commit formatting as separate PR

#### Testing
- [ ] Add `test/` directory if missing
- [ ] Create `test/runtests.jl`
- [ ] Add tests for exported functions
- [ ] Increase coverage to >80%
- [ ] Add Test to Project.toml `[extras]`

#### CI/CD
- [ ] Add `.github/workflows/` directory
- [ ] Add `CI.yml` (copy from templates)
- [ ] Add `Documentation.yml` (copy from templates)
- [ ] Add `Coverage.yml` (copy from templates)
- [ ] Add `FormatCheck.yml` (copy from templates)
- [ ] Fix any failing CI checks
- [ ] Sign up for Codecov and configure

#### Documentation
- [ ] Create `docs/` directory
- [ ] Set up Documenter.jl (`docs/make.jl`)
- [ ] Create documentation structure:
  - [ ] `docs/src/index.md`
  - [ ] `docs/src/getting-started.md`
  - [ ] `docs/src/api.md`
  - [ ] `docs/src/examples.md`
- [ ] Add docstrings to all exported functions
- [ ] Generate Documenter key and add to GitHub secrets
- [ ] Enable GitHub Pages
- [ ] Verify docs deploy successfully

#### Code Quality
- [ ] Review and refactor for type stability
- [ ] Add docstrings to internal functions
- [ ] Improve error messages
- [ ] Add input validation
- [ ] Fix deprecation warnings
- [ ] Update dependencies in `Project.toml`
- [ ] Add version `[compat]` bounds

### Registration (If Not Registered)

#### Check Eligibility
- [ ] Package name available in General Registry
- [ ] All tests pass
- [ ] Documentation exists
- [ ] License file present
- [ ] Has at least one tagged release

#### Register
- [ ] Tag a release (v0.1.0 or appropriate version)
- [ ] Register using Registrator or LocalRegistry
- [ ] Address registry review feedback
- [ ] Update README with registry badge

### Maintenance Status Update

#### If Currently Inactive
- [ ] Assess if you can return to active maintenance
- [ ] Consider finding co-maintainers
- [ ] Update README with current status
- [ ] Triage open issues
- [ ] Review and merge or close stale PRs
- [ ] Tag a maintenance release

#### If Considering Archival
- [ ] Announce on Discourse/Slack
- [ ] Add archive notice to README
- [ ] Suggest alternative packages
- [ ] Archive repository on GitHub
- [ ] Keep registry entry active (don't unregister)

## Resources

- **JuliaHealth Audit:** Review your package's metrics in `data/results/audit_packages.csv`
- **PkgTemplates.jl:**/**BestieTemplates.jl** Automated package generation
- **Documenter.jl:** Documentation framework
- **JuliaFormatter.jl:** Code formatting tool

## Getting Help

- **GitHub Discussions**: Ask questions in [Discussions](https://github.com/JuliaHealth/PackageName.jl/discussions)
- **Slack**: Join #health-and-medicine at julialang.slack.com
- **Julia Discourse**: Post in [JuliaHealth category](https://discourse.julialang.org/)


**Questions?** Ask in [#health-and-medicine](https://julialang.slack.com/archives/C6LDNV35T) on Julia Slack!
