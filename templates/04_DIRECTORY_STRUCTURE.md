# Standard Package Directory Structure

This document defines the recommended directory structure for JuliaHealth packages based on Julia best practices and ecosystem audit findings.

## Standard Structure (Recommended)

For packages that follow **JuliaHealth standards**:

```
YourPackage.jl/
├── .github/
│   └── workflows/
│       ├── CI.yml
│       ├── Documentation.yml
│       ├── Coverage.yml
│       └── FormatCheck.yml
├── docs/
│   ├── make.jl
│   ├── Project.toml
│   └── src/
│       ├── index.md
│       ├── getting-started.md
│       ├── api.md
│       ├── examples.md
│       └── assets/
│           └── logo.png (optional)
├── src/
│   ├── YourPackage.jl
│   ├── module1.jl
│   ├── module2.jl
│   └── utils.jl
├── test/
│   ├── runtests.jl
│   ├── test_module1.jl
│   └── test_module2.jl
├── .gitignore
├── .JuliaFormatter.toml
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── Project.toml
└── README.md
```

## Compliance Checklist

Based on the JuliaHealth audit, a package is considered **standard compliant** if it has:

### Recommended (Should Have)
- [ ] `src/` directory with main module file
- [ ] `Project.toml` with package metadata
- [ ] `LICENSE` file
- [ ] `test/` directory with tests
- [ ] `docs/` directory with documentation
- [ ] CI workflows (`.github/workflows/`)
- [ ] Documenter.jl setup (`docs/make.jl`) + gh-pages
- [ ] Code coverage configuration
- [ ] `README.md` with completeness 
- [ ] `CONTRIBUTING.md`
- [ ] `CODE_OF_CONDUCT.md`
- [ ] `.JuliaFormatter.toml`

## Resources

- [PkgTemplates.jl](https://github.com/JuliaCI/PkgTemplates.jl) - Package generator
- [BestieTemplate.jl](https://github.com/JuliaBesties/BestieTemplate.jl) - Modern template
- [Julia Package Documentation](https://pkgdocs.julialang.org/)
- [JuliaHealth Audit Results](../RESULTS.md)
