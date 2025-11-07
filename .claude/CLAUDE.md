# MicroTutor Agent - Claude Code Web Agent Repository

## Purpose

This repository serves as a dedicated Claude Code Web agent for developing and maintaining **microtutorcourses.org** - an open, interactive virtual light microscopy education platform built on Moodle.

## Project Overview

**MicroTutor** is a self-paced learning platform specializing in fluorescence microscopy education for early-career research scientists. The platform provides:

- Interactive course content with embedded H5P modules
- Community support through Microforum discussion boards
- Free, open access to educational resources (CC BY-NC-ND 4.0)
- Video-based learning materials

## Technology Stack

### Core Platform
- **Moodle LMS** (v5.0.1+) - Learning Management System
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

### Development Tools
- **Moodle MCP Server** - AI integration for course management
- **AWS MCP Servers** - AI-powered AWS service access and documentation
- **Git/GitHub** - Version control
- **Claude Code Web** - AI-assisted development

## Development Workflow

### Best Practices
1. **Explore, Plan, Code, Commit** - Always understand the codebase before coding
2. **Test-Driven Development** - Write tests first when applicable
3. **Document Changes** - Keep CLAUDE.md and documentation current
4. **Use Specialized Agents** - Leverage domain-specific agents for Moodle, database, and AWS tasks

### Key Commands
- Use `/permissions` to configure tool access
- Use custom slash commands in `.claude/commands/` for repeated tasks
- Leverage SessionStart hooks for automatic environment setup

## Moodle API Development

### Core APIs to Use
- **Access API** - User permissions and capabilities
- **Data Manipulation API** - Safe database operations
- **External Functions API** - Web services and external integrations
- **Forms API** - Creating and validating forms
- **Output API** - Rendering content
- **Navigation API** - Menu and navigation structure

### Web Services
Moodle exposes REST-like web services for:
- User management (create, update, delete, enroll)
- Course operations
- Assignment management
- Quiz handling
- Event creation

### Authentication
- Token-based authentication required
- Obtain tokens via Site Administration → Web Services
- Use minimal permission tokens for security

## MCP Server Integration

This repository is configured with multiple MCP servers for enhanced AI capabilities:

### Moodle MCP Server
Enables Claude to interact directly with the Moodle platform for:
- Listing enrolled students
- Managing assignments and submissions
- Providing feedback and grades
- Handling quizzes and attempts

**Required environment variables:** `MOODLE_API_URL`, `MOODLE_API_TOKEN`, `MOODLE_COURSE_ID`

### AWS MCP Servers

**AWS API MCP Server:**
- Programmatic access to AWS services (Lightsail, EC2, EBS, S3, etc.)
- Command validation and security controls
- Read-only by default (configurable with `ALLOW_WRITE`)
- Supports infrastructure management and deployment tasks

**AWS Knowledge MCP Server:**
- Fully managed by AWS (remote service)
- Real-time AWS documentation and API references
- Well-Architected Framework guidance
- AWS What's New posts and blog content
- No configuration required

**Required environment variables:** `AWS_PROFILE` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, `AWS_REGION`

See `ENV_SETUP.md` for detailed configuration instructions.

## Security Considerations

- Never commit API tokens or credentials
- Store sensitive data in environment variables
- Use `.gitignore` for `.env` files
- Implement proper access controls in Moodle
- Follow OWASP security guidelines
- Sanitize user inputs to prevent XSS and SQL injection

## Project Structure

```
.claude/
├── CLAUDE.md           # This file - project documentation
├── hooks/
│   └── SessionStart    # Environment setup script
├── agents/
│   ├── moodle-expert.md        # Moodle API specialist
│   ├── database-cms-lms.md     # Database & LMS specialist
│   └── aws-lightsail.md        # AWS Lightsail specialist
└── commands/           # Custom slash commands
.mcp.json               # MCP server configuration (project root)
```

## Common Tasks

### Course Development
- Creating new course content
- Updating H5P modules
- Managing course structure
- Configuring activities and resources

### Student Management
- Enrollment handling
- Progress tracking
- Grade management
- Communication tools

### Platform Maintenance
- Plugin updates
- Theme customization
- Performance optimization
- Backup and restore operations

### Infrastructure
- Lightsail instance management
- Database optimization
- SSL certificate configuration
- Scaling and resource allocation

## Resources

- [Moodle Developer Docs](https://moodledev.io/)
- [Moodle API Guides](https://moodledev.io/docs/5.0/apis)
- [AWS Lightsail Documentation](https://docs.aws.amazon.com/lightsail/)
- [AWS MCP Servers](https://github.com/awslabs/mcp)
- [AWS MCP Documentation](https://awslabs.github.io/mcp/)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Moodle MCP Server](https://github.com/peancor/moodle-mcp-server)

## Testing Strategy

- Unit tests for custom Moodle plugins
- Integration tests for API endpoints
- Manual testing in staging environment
- Accessibility testing (WCAG compliance)
- Cross-browser compatibility checks

## Deployment Process

1. Test changes in local/staging environment
2. Create pull request for review
3. Run automated tests
4. Deploy to production Lightsail instance
5. Monitor logs and performance
6. Create backups before major changes

## Support & Community

- Moodle Forums: https://moodle.org/forums
- Microforum: Community discussion boards on microtutorcourses.org
- GitHub Issues: For this repository's development
