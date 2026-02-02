# JuliaHealth Package Standards & Templates

Templates and guides for creating high-quality JuliaHealth packages based on ecosystem audit findings.

## Quick Links

| Resource | Purpose |
|----------|---------|
| [Package Checklist](06_PACKAGE_CHECKLIST.md) | ✅ Track package development progress |
| [Package Template](01_PACKAGE_TEMPLATE/) | 📦 Copy-paste files for new packages |
| [Documentation Guide](02_DOCUMENTATION_GUIDE.md) | 📚 Set up Documenter.jl & GitHub Pages |
| [CI Workflows](03_CI_WORKFLOWS/) | ⚙️ GitHub Actions for testing & deployment |
| [Directory Structure](04_DIRECTORY_STRUCTURE.md) | 📁 Standard package layout |
| [Maintenance Guide](05_MAINTENANCE_GUIDE.md) | 🔧 Package health & handoffs |

## Quick Start

### New Package

1. Check [Package Checklist](06_PACKAGE_CHECKLIST.md)
2. Copy files from [01_PACKAGE_TEMPLATE/](01_PACKAGE_TEMPLATE/)
3. Set up [CI Workflows](03_CI_WORKFLOWS/)
4. Build [Documentation](02_DOCUMENTATION_GUIDE.md)

### Existing Package

1. Review [Package Checklist](06_PACKAGE_CHECKLIST.md) - Existing Package section
2. Check [Directory Structure](04_DIRECTORY_STRUCTURE.md) compliance
3. Add missing files from templates
4. Use [Maintenance Guide](05_MAINTENANCE_GUIDE.md) for health assessment

## Template Contents

### [01_PACKAGE_TEMPLATE/](01_PACKAGE_TEMPLATE/)
Copy-paste files for new packages:
- `README_TEMPLATE.md` - 8/8 completeness score
- `CONTRIBUTING.md` - Contributor guidelines
- `CODE_OF_CONDUCT.md` - Community standards
- `Project.toml` - Package metadata
- `.JuliaFormatter.toml` - Blue style config

### [02_DOCUMENTATION_GUIDE.md](02_DOCUMENTATION_GUIDE.md)
Quick Documenter.jl/DocumenterVitepress setup with GitHub Pages deployment

### [03_CI_WORKFLOWS/](03_CI_WORKFLOWS/)
GitHub Actions workflows:
- `CI.yml` - Multi-platform testing
- `Documentation.yml` - Build & deploy docs
- `Coverage.yml` - Codecov integration
- `FormatCheck.yml` - Style verification

### [04_DIRECTORY_STRUCTURE.md](04_DIRECTORY_STRUCTURE.md)
Standard layout with monorepo examples

### [05_MAINTENANCE_GUIDE.md](05_MAINTENANCE_GUIDE.md)
Package health, revival, and succession planning

### [06_PACKAGE_CHECKLIST.md](06_PACKAGE_CHECKLIST.md)
Comprehensive checklists for new and existing packages

## Examples

**JuliaHealth packages following best practices:**
- [KomaMRI.jl](https://github.com/JuliaHealth/KomaMRI.jl) - Monorepo with Blue style