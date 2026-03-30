# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.10] - 2026-03-30

### Fixed
- Enforce commit body via critical rules and heredoc template in /jira:commit

## [0.3.9] - 2026-03-30

### Fixed
- Update commit template to show bullet-point body in example

## [0.3.8] - 2026-03-30

### Added
- Enforce detailed commit messages with bullet-point body requirement

## [0.3.7] - 2026-03-30

### Added
- Prerequisites section for curl, git, jq in README
- Windows SSL certificate revocation bypass for corporate networks (contributed by @sukytan)

## [0.3.6] - 2026-03-28

### Changed
- Restructure README for value-first hierarchy
- Rewrite README for clarity and better UX

### Fixed
- Update install instructions with actual working commands
- Replace all project-specific examples with generic ones

## [0.3.5] - 2026-03-28

### Added
- Clickable Jira link in commit results
- Offer doc generation when no docs match changed files

## [0.3.4] - 2026-03-28

### Fixed
- Add Root Cause section for bugs in Jira comments
- Show commit details above options for better readability
- Remove company-specific URLs from examples

## [0.3.3] - 2026-03-28

### Added
- Smart URL parsing -- extract base URL and project key from full board URLs

## [0.3.2] - 2026-03-28

### Added
- Remember workflow choices -- ask once per issue type, save for future use

## [0.3.1] - 2026-03-28

### Fixed
- Step 2 URL check uses HEAD request instead of API endpoint
- Token security improvements and PLUGIN_ROOT detection
- Use plain text for free-text inputs in setup wizard
- Improve UX with AskUserQuestion, handle no-ticket flow gracefully
- Use bin/jira-cred validate instead of inline curl, prevent token leakage

## [0.1.2] - 2026-03-28

### Fixed
- Split auth into separate email and token prompts

## [0.1.1] - 2026-03-28

### Fixed
- Move skills and agents to plugin root for Claude Code discovery

### Added
- marketplace.json for plugin discovery
- Repository URL to plugin.json

## [0.1.0] - 2026-03-28

Initial release.

### Added
- `jira-config` script for config CRUD and validation
- `jira-cred` script for cross-platform credential management (Keychain, secret-tool, env vars)
- `jira-api` script with retry logic and exponential backoff
- `jira-issues` query helper with pagination
- `docs-check` scanner with quick and full modes
- `/jira:setup` skill -- guided setup wizard
- `/jira:commit` skill -- 4-checkpoint commit flow with Jira integration
- `/jira:docs` skill -- documentation sync before PRs
- `jira-reader` agent -- automatic ticket lookup from conversation
- Shared reference documents (preamble, credential-helper, Jira API reference)
- Security tests for injection and path traversal
- Unit tests for config, credentials, API, and docs-check
