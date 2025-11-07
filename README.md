# MicroTutor Agent

A specialized Claude Code Web agent repository for developing and maintaining **[microtutorcourses.org](https://microtutorcourses.org)** - an open, interactive virtual light microscopy education platform.

## Overview

This repository provides Claude Code with specialized knowledge and tools to work effectively with:
- **Moodle LMS** (Learning Management System)
- **AWS Lightsail** infrastructure
- **Database systems** (MySQL/MariaDB)
- **Educational content management**

## Quick Start

### 1. Environment Setup

Set up required environment variables for the MCP servers. See [ENV_SETUP.md](ENV_SETUP.md) for detailed instructions.

**Required for Moodle MCP:**
```bash
MOODLE_API_URL=https://microtutorcourses.org/webservice/rest/server.php
MOODLE_API_TOKEN=<your-token>
MOODLE_COURSE_ID=<course-id>
```

**Optional for AWS operations:**
```bash
# For AWS CLI
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
AWS_DEFAULT_REGION=us-east-1

# For AWS MCP Server
AWS_PROFILE=default
AWS_REGION=us-east-1
ALLOW_WRITE=false
```

### 2. Using with Claude Code Web

1. Visit [claude.ai/code](https://claude.ai/code)
2. Connect this repository
3. Configure environment variables in session settings
4. Claude will automatically load project context from `.claude/CLAUDE.md`
5. Use specialized agents as needed

## Project Structure

```
.
├── .claude/
│   ├── CLAUDE.md                    # Project documentation and guidelines
│   ├── hooks/
│   │   └── SessionStart             # Automatic session setup script
│   └── agents/
│       ├── moodle-expert.md         # Moodle API and development specialist
│       ├── database-cms-lms.md      # Database and LMS operations expert
│       └── aws-lightsail.md         # AWS Lightsail deployment specialist
├── .mcp.json                        # MCP servers configuration (Moodle + AWS)
├── ENV_SETUP.md                     # Environment variables guide
├── README.md                        # This file
└── .gitignore                       # Ignore sensitive files
```

## Specialized Agents

### Moodle Expert Agent
**File:** `.claude/agents/moodle-expert.md`

Expert in:
- Moodle architecture and plugin development
- Web Services API (REST endpoints)
- Database operations and optimization
- H5P interactive content integration
- Theme customization (Boost Union)
- Security best practices

Use for: Course management, plugin development, API integration

### Database & CMS/LMS Expert Agent
**File:** `.claude/agents/database-cms-lms.md`

Expert in:
- MySQL/MariaDB optimization
- Database schema design and migrations
- Learning Management System patterns
- Content delivery strategies
- Learning analytics
- Data privacy and compliance (GDPR, FERPA)

Use for: Database queries, performance tuning, content strategy

### AWS Lightsail Expert Agent
**File:** `.claude/agents/aws-lightsail.md`

Expert in:
- Lightsail instance deployment and management
- LAMP stack configuration
- SSL/TLS setup with Let's Encrypt
- Backup and disaster recovery
- Performance optimization
- Cost optimization
- Scaling strategies

Use for: Infrastructure deployment, server configuration, DevOps tasks

## Features

### SessionStart Hook

Automatically runs at the beginning of each Claude Code Web session to:
- Verify environment variables are set
- Install Node.js dependencies (if `package.json` exists)
- Install Python dependencies (if `requirements.txt` exists)
- Display helpful reminders and quick reference

### Moodle MCP Server Integration

The `.mcp.json` configuration enables Claude to interact directly with your Moodle instance through the Model Context Protocol:

**Available tools:**
- `list_students` - Get enrolled students
- `get_assignments` - Retrieve course assignments
- `get_student_submissions` - View student work
- `provide_assignment_feedback` - Grade and comment on submissions
- `get_quizzes` - List available quizzes
- `get_quiz_attempts` - View quiz performance
- `provide_quiz_feedback` - Comment on quiz attempts

### AWS MCP Servers Integration

Two AWS MCP servers are configured to provide AI-powered AWS capabilities:

**AWS API MCP Server:**
- Programmatic access to AWS services (Lightsail, EC2, EBS, S3, RDS, etc.)
- Command validation and security controls
- Read-only by default (set `ALLOW_WRITE=true` for write operations)
- Supports infrastructure management, deployments, and monitoring

**AWS Knowledge MCP Server:**
- Fully managed by AWS (remote service)
- Real-time AWS documentation and API references
- Well-Architected Framework guidance
- AWS What's New posts and best practices
- No local installation or credentials required

**Supported AWS Services for Lightsail deployment:**
- Lightsail instance management, snapshots, networking
- EC2 virtual machines and security groups
- EBS volumes and snapshots
- RDS managed databases
- Route 53 DNS management
- CloudWatch monitoring
- S3 object storage
- IAM permissions and users

## Common Tasks

### Course Development
- Creating/updating course content
- Managing H5P interactive modules
- Configuring activities and resources
- Setting up completion tracking

### Student Management
- Enrolling users programmatically
- Tracking progress and performance
- Managing grades and feedback
- Analyzing learning analytics

### Infrastructure Management
- Deploying Moodle to AWS Lightsail
- Configuring LAMP stack
- Setting up SSL certificates
- Creating backups and snapshots
- Performance monitoring and optimization

### Database Operations
- Optimizing slow queries
- Managing user data
- Migrating content between versions
- Generating custom reports

## Technology Stack

### Platform
- **Moodle LMS** (v5.0.1+)
- **PHP** 8.2+
- **MySQL/MariaDB** 8.0+
- **Apache** 2.4+

### Infrastructure
- **AWS Lightsail** - Virtual private servers
- **Ubuntu** 24.04 LTS
- **Let's Encrypt** - SSL/TLS certificates

### Tools & Integrations
- **H5P** - Interactive content
- **Video.js** - Media playback
- **MathJax** - Mathematical notation
- **Moodle MCP Server** - AI integration for course management
- **AWS MCP Servers** - AI-powered AWS service access and documentation

## Best Practices

### Development Workflow
1. **Explore** - Understand the codebase before coding
2. **Plan** - Create detailed implementation plans
3. **Code** - Write clean, secure, documented code
4. **Test** - Verify functionality across scenarios
5. **Commit** - Use descriptive commit messages
6. **Deploy** - Test in staging before production

### Security
- Never commit credentials or API tokens
- Validate and sanitize all user inputs
- Use parameterized queries (prevent SQL injection)
- Check capabilities before sensitive operations
- Keep Moodle and plugins updated
- Enable two-factor authentication

### Performance
- Implement efficient caching strategies
- Optimize database queries and indexes
- Use CDN for static assets
- Enable browser caching
- Monitor resource usage

## Resources

### Documentation
- [Moodle Developer Docs](https://moodledev.io/)
- [Moodle API Guides](https://moodledev.io/docs/5.0/apis)
- [AWS Lightsail Documentation](https://docs.aws.amazon.com/lightsail/)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

### Tools
- [Moodle MCP Server](https://github.com/peancor/moodle-mcp-server)
- [AWS MCP Servers](https://github.com/awslabs/mcp)
- [AWS MCP Documentation](https://awslabs.github.io/mcp/)
- [H5P Documentation](https://h5p.org/documentation)
- [Bitnami Moodle Stack](https://bitnami.com/stack/moodle)

### Community
- [Moodle Forums](https://moodle.org/forums)
- [Microforum](https://microtutorcourses.org) - MicroTutor community

## Troubleshooting

### Environment Variable Issues
See [ENV_SETUP.md](ENV_SETUP.md) for detailed troubleshooting steps.

### Common Issues

**Issue:** SessionStart hook not running
- **Solution:** Ensure the hook is executable: `chmod +x .claude/hooks/SessionStart`

**Issue:** Moodle MCP server not connecting
- **Solution:** Verify `MOODLE_API_URL`, `MOODLE_API_TOKEN`, and `MOODLE_COURSE_ID` are set correctly

**Issue:** AWS CLI commands failing
- **Solution:** Check AWS credentials and region are configured properly

**Issue:** AWS MCP Server not working
- **Solution:** Ensure `uv` is installed (`pip install uv`), verify AWS credentials with `aws configure list`, and check `AWS_PROFILE` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` are set

## Contributing

This repository is maintained for the MicroTutor project. When making changes:

1. Test thoroughly in development environment
2. Follow Moodle coding standards
3. Document new features or changes
4. Create clear commit messages
5. Review security implications

## Support

For questions or issues:
- **Moodle-specific:** [Moodle Forums](https://moodle.org/forums)
- **Infrastructure:** [AWS Lightsail Documentation](https://docs.aws.amazon.com/lightsail/)
- **Claude Code:** [Claude Code Docs](https://code.claude.com/docs)

## License

This agent repository configuration is provided as-is for use with the MicroTutor project.

MicroTutor course content is licensed under Creative Commons BY-NC-ND 4.0.

---

**Built with Claude Code Web** | [Learn more about Claude Code](https://claude.ai/code)
