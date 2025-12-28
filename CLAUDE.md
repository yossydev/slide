# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a slide presentation repository using Marp (Markdown Presentation Ecosystem) to generate HTML and PDF slides from Markdown files. The repository contains technical presentations by yossydev for various conferences and meetups.

## Development Commands

### Building Slides
```bash
make slide        # Generate HTML and PDF slides from all Markdown files in slides/ directory
```

### Local Development
```bash
make server       # Start development server with live reload on port 8080
make stop         # Stop Docker containers
make clean        # Remove build/ directory
```

### Creating New Slides
```bash
./generate.sh     # Interactive script to create new slide from template
```

## Architecture

The repository uses Docker containers for consistent slide generation across environments. All slide content is written in Markdown with Marp-specific frontmatter and directives.

Key directories:
- `slides/` - Source Markdown files for presentations
- `theme/` - Custom Marp themes (gaia.css)
- `build/` - Generated HTML/PDF output (git-ignored)

## Slide Format

Each slide Markdown file should include:
- Marp frontmatter configuration
- Theme specification (typically `gaia`)
- Paginate setting for slide numbers
- Standard header/footer format

Example structure from template:
```markdown
---
marp: true
theme: gaia
paginate: true
header: "**Conference Name** title"
footer: "by **yossydev**"
---
```

## Deployment

GitHub Actions automatically builds and deploys slides to GitHub Pages when changes are pushed to the main branch. The workflow:
1. Builds slides using Docker
2. Deploys to GitHub Pages using peaceiris/actions-gh-pages@v4

## Working with Docker

All Marp operations run in Docker containers using `marpteam/marp-cli:latest`. The docker-compose.yml handles user permissions via `MARP_USER` environment variable to ensure proper file ownership.