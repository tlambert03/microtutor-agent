# MicroTutor Agent - Claude Code Web Agent Repository

## Purpose

This repository serves as a dedicated Claude Code Web agent for developing and maintaining **microtutorcourses.org** - an open, interactive virtual light microscopy education platform built on Moodle.

## Project Overview

**MicroTutor** is a self-paced learning platform specializing in fluorescence microscopy education for early-career research scientists. The platform provides:

- Interactive course content with embedded H5P modules
- Community support through Microforum discussion boards
- Free, open access to educational resources (CC BY-NC-ND 4.0)
- Video-based learning materials

## Your tools

- use curl for making HTTP requests
- use jq for parsing JSON
- use uv if you need python

## Technology Stack

### Core Platform

- **Moodle LMS** (v4.3.3) - Learning Management System
- **Boost Union Theme** - Moodle theme
- **PHP** - Server-side language
- **MySQL/MariaDB** - Database
- **YUI & RequireJS** - Frontend frameworks
- **H5P** - Interactive content creation

### Infrastructure

- **AWS Lightsail** - Cloud hosting (VPS)
  - Recommended: 4-8 GB RAM minimum
  - 20-40 GB disk space
  - Linux-based instances

## Development Workflow

### Best Practices

1. **SAFETY FIRST** - Never make destructive changes on the production instance without explicit approval.
1. **Explore, Plan, Code, Commit** - Always understand the codebase before coding
1. **Document Changes** - Keep CLAUDE.md and documentation current
1. **Use Specialized Agents** - Leverage domain-specific agents for Moodle, database, and AWS tasks

## Moodle API Development

### Core APIs to Use

- **Access API** - User permissions and capabilities
- **Data Manipulation API** - Safe database operations
- **External Functions API** - Web services and external integrations
- **Forms API** - Creating and validating forms
- **Output API** - Rendering content
- **Navigation API** - Menu and navigation structure

### Skills

Use the moodle-api-user skill for interacting with Moodle's web services via REST.
Use the moodle-php-direct for direct PHP code snippets executed on the server when necessary.

### Authentication

- Token-based authentication required
- Obtain tokens via Site Administration → Web Services
- Use minimal permission tokens for security

## Security Considerations

- Never commit API tokens or credentials
- Store sensitive data in environment variables
- Use `.gitignore` for `.env` files
- Implement proper access controls in Moodle
- Follow OWASP security guidelines
- Sanitize user inputs to prevent XSS and SQL injection
