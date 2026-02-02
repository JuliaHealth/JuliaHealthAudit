# Documentation Guide

## What is Documentation?

Documentation provides user guides, API references, and tutorials that help others understand and use your package. Good documentation includes:

- **Installation instructions** - How to add and set up the package
- **Usage examples** - Working code showing common tasks
- **API reference** - Complete function/type documentation from docstrings
- **Tutorials** - Step-by-step guides for specific workflows

Julia packages typically use **Documenter.jl** or **DocumenterVitepress.jl** to generate documentation websites hosted on **GitHub Pages**.

## Why It Matters


Without deployed documentation, users must read source code to understand your package. Accessible docs increase adoption and reduce support burden.

## Documentation Tools

### Documenter.jl (Standard)

Classic documentation generator for Julia packages.

**Resources:**
- [Official Documentation](https://documenter.juliadocs.org/stable/)
- [GitHub Repository](https://github.com/JuliaDocs/Documenter.jl)
- [First-Time User Help](https://discourse.julialang.org/t/documenter-jl-help-for-first-time-user/124966)

### DocumenterVitepress.jl (Modern)

Modern alternative with enhanced UI powered by Vitepress.

**Resources:**
- [GitHub Repository](https://github.com/LuxDL/DocumenterVitepress.jl)
- [Getting Started Guide](https://luxdl.github.io/DocumenterVitepress.jl/dev/manual/get_started)

## Quick Start

1. Choose your documentation tool (Documenter.jl or DocumenterVitepress.jl)
2. Follow the getting started guide from the resources above
3. Copy [03_CI_WORKFLOWS/Documentation.yml](03_CI_WORKFLOWS/Documentation.yml) to `.github/workflows/`
4. Enable GitHub Pages in repository settings (Settings → Pages → Source: `gh-pages`)

Your documentation will be available at the provided link in the docs files

## Docstring Format

Use Julia's standard docstring format:

```julia
"""
    function_name(arg1, arg2; kwarg1="default")

Brief description of what the function does.

# Arguments
- `arg1` - Description of first argument
- `arg2` - Description of second argument

# Keyword Arguments
- `kwarg1` - Description of keyword argument. Default: `"default"`

# Returns
- `Type` - Description of return value

# Examples
# Basic usage
result = function_name(1, 2)

# With keyword argument
result = function_name(1, 2; kwarg1="custom")

"""
function function_name(arg1, arg2; kwarg1="default")
    # Implementation
end
```

See [01_PACKAGE_TEMPLATE/README_TEMPLATE.md](01_PACKAGE_TEMPLATE/README_TEMPLATE.md) for README structure guidelines.
