# Package Maintenance Guide

This guide helps maintainers assess package health and make decisions about maintenance status based on the JuliaHealth ecosystem audit.

## Maintenance Status Definitions

Based on the audit's classification system:

| Status | Criteria | What It Means |
|--------|----------|---------------|
| **Active** | Has active maintainers (contributed in last 6 months) | Package is actively developed and maintained |
| **Inactive** | Has maintainers but no active ones, last activity < 540 days (~18 months) | Maintainers exist but not currently engaged |
| **Abandoned** | No maintainers OR last activity ≥ 540 days | No active maintenance, needs new ownership |
| **Concept** | Less than 1 release | Experimental or pre-release stage |

## Current JuliaHealth Landscape

From the latest audit:
- **Active packages:** Well-maintained with engaged teams
- **Inactive packages:** Maintainers could potentially return
- **Abandoned packages:** Need new maintainers or archival
- **Concept packages:** Decide on development or archival

## For Active Maintainers

### Regular Maintenance Tasks

**Monthly:**
- [ ] Review and triage new issues
- [ ] Review open pull requests
- [ ] Check for dependency updates
- [ ] Monitor CI status

**Quarterly:**
- [ ] Update dependencies in `Project.toml`
- [ ] Review and update documentation
- [ ] Check test coverage (aim for >80%)
- [ ] Review open issues for stale/resolved items

**Annually:**
- [ ] Major version bump if needed
- [ ] Review and update contributor guidelines
- [ ] Assess roadmap and priorities
- [ ] Consider package health assessment

### Keeping Package Active

**Communication:**
- Respond to issues within 1-2 weeks
- Label issues (`good first issue`, `help wanted`)
- Update contributors on long-term plans
- Post roadmap in README or Discussions

**Documentation:**
- Keep examples working with current version
- Update tutorials for new features
- Fix broken links in docs
- Add changelog for each release

**Community Building:**
- Welcome new contributors warmly
- Provide mentorship for first PRs
- Recognize contributions publicly
- Share package updates on Julia Discourse

## For Inactive Packages

### Assessing Viability

**Ask yourself:**
1. Is the package still useful to the community?
2. Are there active users (downloads, issues, stars)?
3. Do I have time to return to active maintenance?
4. Are there breaking changes in dependencies?
5. Is there a replacement package?

### Options for Revival

#### Option 1: Return to Active Maintenance

**Steps:**
1. Announce return in README and Discourse
2. Triage issues and PRs
3. Update dependencies
4. Fix CI failures
5. Tag a new maintenance release
6. Update status to "Active"

#### Option 2: Find Co-Maintainers

**Where to look:**
- Contributors with merged PRs
- Active issue participants
- Julia Slack #health-and-medicine channel
- JuliaHealth Discourse category

#### Option 3: Transfer Ownership

**Process:**
1. Identify interested party
2. Grant push access
3. Transfer knowledge (docs, design decisions)
4. Update README with new maintainer
5. Update AUTHORS file
6. Announce on Discourse

#### Option 4: Archive Package

**When to archive:**
- No users or minimal usage
- Functionality replaced by another package
- No interested maintainers found
- Underlying technology obsolete

**How to archive:**
1. Announce intention on Discourse
2. Add prominent notice to README:
   ```markdown
   ## ⚠️ ARCHIVED
   
   This package is no longer actively maintained. 
   
   **Alternative:** Consider using [ReplacementPackage.jl](link)
   
   If you're interested in maintaining this package, please open an issue.
   ```
3. Archive repository on GitHub (Settings → Archive)
4. Keep releases available (don't delete tags)
5. Update JuliaHealth package list

## For Abandoned Packages

### Assessment Questions

1. **Is anyone using it?**
   - Check GitHub stars, forks, downloads
   - Search Discourse/Slack for mentions
   - Look for dependent packages

2. **Is it unique?**
   - Does it fill a niche?
   - Are there alternatives?
   - Is the functionality needed?

3. **Is it salvageable?**
   - Does it still build?
   - Are tests passing?
   - Are dependencies available?

## For Concept Packages

### Path to v0.1.0 Release

1. **Minimum viable package:**
   - [ ] Core functionality works
   - [ ] Basic tests pass
   - [ ] README with installation & examples
   - [ ] LICENSE file

2. **Register in General Registry:**
   ```julia
   using LocalRegistry
   register(YourPackage, registry="https://github.com/JuliaRegistries/General")
   ```

3. **Announce release:**
   - Post on Julia Discourse
   - Share in JuliaHealth Slack
   - Tweet with #JuliaLang hashtag

## Maintainer Responsibilities

### What Maintainers Do

**Minimum (Inactive but responsive):**
- Respond to critical bugs
- Accept straightforward PRs
- Keep package buildable

**Standard (Active):**
- Regular triage (weekly/monthly)
- Review PRs within 1-2 weeks
- Cut releases for merged PRs
- Update dependencies quarterly
- Respond to issues

**Exemplary (Very Active):**
- Proactive development
- Add new features
- Comprehensive docs
- Help users on Slack/Discourse
- Mentor new contributors

## Succession Planning

### When to Start

- You're consistently too busy
- Interest is waning
- Life circumstances changing
- Package is mature and stable

### How to Find Successors

1. **Look at contributors:**
   - Check `data/results/lists/maintainers_list.csv` from audit
   - Review PR authors
   - Identify frequent issue participants

2. **Announce opening:**
   ```markdown
   # Seeking Co-Maintainer for [Package]
   
   I'm looking for someone to help maintain [Package]. 
   
   **What you'll do:**
   - Review pull requests
   - Triage issues
   - Cut releases
   - Update dependencies
   
   **Ideal candidate:**
   - Familiar with Julia and [domain]
   - Has contributed to open source before
   - Can commit 2-4 hours/month
   
   Interested? Reply here or DM me on Slack!
   ```

3. **Cross-post to:**
   - JuliaHealth Discourse
   - Julia Slack #health-and-medicine
   - Twitter/X with #JuliaLang
   - Package README

## Resources

### JuliaHealth Audit Data

Use these CSV files to assess package health:
- `data/results/audit_packages.csv` - Full package metrics
- `data/results/lists/maintainers_list.csv` - All maintainers
- `data/results/lists/active_maintainers_list.csv` - Active maintainers
- `data/results/lists/maintenance_status.csv` - Status by category

## Getting Help

- **GitHub Discussions**: Ask questions in [Discussions](https://github.com/JuliaHealth/PackageName.jl/discussions)
- **Slack**: Join #health-and-medicine at julialang.slack.com
- **Julia Discourse**: Post in [JuliaHealth category](https://discourse.julialang.org/)

**Remember:** It's okay to step back from maintenance. The most important thing is clear communication with users and contributors.
