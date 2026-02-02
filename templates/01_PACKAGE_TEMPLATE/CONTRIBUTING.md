# Contributing to PackageName.jl

Thank you for considering contributing to PackageName.jl! This document provides guidelines and instructions for contributing.

## Code of Conduct

This project adheres to the [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the [issue tracker](https://github.com/JuliaHealth/PackageName.jl/issues) to avoid duplicates.

When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the problem
- **Expected behavior** vs. actual behavior
- **Julia version** (`julia --version`)
- **Package version** (`Pkg.status("PackageName")`)
- **Minimal reproducible example** (MRE)
- **Error messages** and stack traces

### Suggesting Features

Feature requests are welcome! Please:

- **Check existing issues** to avoid duplicates
- **Describe the feature** clearly and provide use cases
- **Explain why** this feature would be useful to users
- **Provide examples** of how it would be used

### Pull Requests

1. **Fork the repository** and create your branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following our code style guidelines

3. **Add tests** for any new functionality

4. **Update documentation** if you've changed APIs

5. **Run tests locally**:
   ```julia
   using Pkg
   Pkg.test("PackageName")
   ```

6. **Commit with clear messages**:
   ```bash
   git commit -m "Add feature: brief description"
   ```

7. **Push to your fork** and submit a pull request

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/JuliaHealth/PackageName.jl.git
cd PackageName.jl
```

### 2. Install Dependencies

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### 3. Run Tests

```julia
Pkg.test()
```

### 4. Build Documentation Locally

```julia
cd docs/
julia --project=. make.jl
```

Then open `docs/build/index.html` in your browser.

## Code Style Guidelines

This project uses [Blue Style](https://github.com/invenia/BlueStyle) for Julia code formatting.

### Formatting Your Code

Install JuliaFormatter:

```julia
using Pkg
Pkg.add("JuliaFormatter")
```

Format your code before committing:

```julia
using JuliaFormatter
format(".")
```

### Style Guidelines

- Use **descriptive variable names** (`data_matrix` not `dm`)
- Add **docstrings** for all exported functions
- Write **type-stable code** when possible
- Follow Julia naming conventions:
  - Functions and variables: `snake_case`
  - Types and modules: `PascalCase`
  - Constants: `UPPER_CASE`

### Documentation

All exported functions should have docstrings:

```julia
"""
    process_data(
        x::Vector,
        method::String = "standard";
        normalize::Bool = true,
        scale_factor::Float64 = 1.0
    )

Process the input data using the specified method.

# Arguments
- `x::Vector`: Input data vector
- `method::String`: Processing method (`"standard"` or `"advanced"`)

# Keyword Arguments
- `normalize::Bool = true`: Whether to normalize the data before processing
- `scale_factor::Float64 = 1.0`: Scaling factor applied to the processed data

# Returns
- `Vector`: Processed data

# Examples
x = [1, 2, 3, 4, 5]
result = process_data(x; normalize=false, scale_factor=2.0)
"""
function process_data(x::Vector, method::String="standard", normalize::Bool = true,scale_factor::Float64 = 1.0)
    # implementation
end
```

## Testing Guidelines

### Writing Tests

- Add tests in `test/runtests.jl` or separate test files
- Use `@testset` to organize related tests
- Aim for high code coverage (>80%)
- Test edge cases and error conditions

Example test structure:

```julia
using Test
using PackageName

@testset "PackageName.jl" begin
    @testset "Basic functionality" begin
        @test process_data([1,2,3]) == [2,4,6]
        @test length(process_data([1])) == 1
    end
    
    @testset "Error handling" begin
        @test_throws ArgumentError process_data([])
        @test_throws DomainError process_data([-1])
    end
end
```

### Running Specific Tests

```julia
# Run all tests
using Pkg; Pkg.test()

# Run with coverage
using Pkg; Pkg.test(coverage=true)
```

## Documentation Guidelines

### Writing Documentation

- Documentation lives in `docs/src/`
- Use Markdown format
- Include code examples that work
- Add figures/diagrams when helpful
- Cross-reference related functions

### Building Docs Locally

```bash
cd docs/
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. make.jl
```

## Commit Message Guidelines

Good commit messages help maintain project history:

```
Short summary (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain the problem this commit solves and why you chose
this solution.

- Bullet points are okay
- Use present tense: "Add feature" not "Added feature"
- Reference issues: "Fixes #123" or "Relates to #456"
```

**Examples:**

```
Add support for custom preprocessing methods

Implement three new preprocessing methods (normalize, standardize,
robust_scale) to handle different data distributions.

Fixes #42
```

```
Fix memory leak in data loading

The previous implementation kept references to loaded data
in a global cache. This commit clears the cache after processing.

Relates to #89
```

## Issue and PR Labels

We use labels to organize issues and pull requests:

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `question` - Further information requested

## Getting Help

- **GitHub Discussions**: Ask questions in [Discussions](https://github.com/JuliaHealth/PackageName.jl/discussions)
- **Julia Slack**: Join **#health-and-medicine**
- **Julia Discourse**: Post in [JuliaHealth category](https://discourse.julialang.org/)

## Recognition

All contributors will be recognized in:
- Repository contributors list
- Release notes
- CITATION.bib (for significant contributions)

Thank you for contributing to PackageName.jl! 🎉
