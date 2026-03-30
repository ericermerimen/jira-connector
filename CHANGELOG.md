# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.10] - 2026-03-30

### Fixed
- Enforce commit body with bullet points via critical rules and heredoc template

## [0.3.7] - 2026-03-30

### Added
- Prerequisites section for curl, git, jq in README
- Windows SSL certificate revocation bypass for corporate networks (contributed by @sukytan)

## [0.3.6] - 2026-03-28

### Changed
- Restructure README for clarity and value-first hierarchy

### Fixed
- Update install instructions with working commands
- Replace project-specific examples with generic ones

## [0.3.5] - 2026-03-28

### Added
- Clickable Jira link in commit results
- Offer doc generation when no docs match changed files

## [0.3.4] - 2026-03-28

### Fixed
- Add Root Cause section for bugs in Jira comments
- Show commit details above options for readability
- Remove company-specific URLs from examples

## [0.3.3] - 2026-03-28

### Added
- Smart URL parsing -- extract base URL and project key from full board URLs

## [0.3.2] - 2026-03-28

### Added
- Remember workflow choices per issue type

## [0.3.1] - 2026-03-28

### Fixed
- Use HEAD request for URL check in setup
- Token security improvements and PLUGIN_ROOT detection
- Use plain text for free-text inputs in setup wizard
- Improve UX with AskUserQuestion, handle no-ticket flow gracefully
- Use bin/jira-cred validate instead of inline curl

## [0.1.2] - 2026-03-28

### Fixed
- Split auth into separate email and token prompts

## [0.1.1] - 2026-03-28

### Fixed
- Move skills and agents to plugin root for Claude Code discovery

### Added
- marketplace.json for plugin discovery

## [0.1.0] - 2026-03-28

Initial release.

### Added
- `jira-config`, `jira-cred`, `jira-api`, `jira-issues`, `docs-check` scripts
- `/jira:setup`, `/jira:commit`, `/jira:docs` skills
- `jira-reader` agent
- Shared reference documents
- Security and unit tests
