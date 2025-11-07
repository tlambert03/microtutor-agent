# Environment Variables Setup Guide

This document explains the required environment variables for the MicroTutor Agent repository.

## Required Environment Variables

### Moodle MCP Server

The Moodle MCP server requires three environment variables to connect to your Moodle instance:

#### 1. MOODLE_API_URL

**Description:** The full URL to your Moodle web service endpoint.

**Format:**
```
https://microtutorcourses.org/webservice/rest/server.php
```

**How to find it:**
- Your Moodle installation URL + `/webservice/rest/server.php`
- For microtutorcourses.org: `https://microtutorcourses.org/webservice/rest/server.php`

---

#### 2. MOODLE_API_TOKEN

**Description:** Authentication token for accessing Moodle web services.

**How to obtain:**

1. Log in to Moodle as an administrator
2. Navigate to: **Site Administration → Server → Web Services**
3. Enable web services:
   - Go to **Overview** and click "Enable web services"
   - Check the "Enable web services" checkbox
   - Save changes

4. Enable REST protocol:
   - Go to **Manage protocols**
   - Enable "REST protocol"

5. Create a web service:
   - Go to **External services**
   - Click "Add" to create a new service
   - Name: "MicroTutor MCP Service"
   - Short name: `microtutor_mcp`
   - Enable "Can download files"
   - Save changes
   - Click "Add functions" and add required functions:
     - `core_user_get_users`
     - `core_enrol_get_enrolled_users`
     - `mod_assign_get_assignments`
     - `mod_assign_get_submissions`
     - `mod_assign_save_grade`
     - `mod_quiz_get_quizzes_by_courses`
     - `mod_quiz_get_user_attempts`

6. Create a user for the service (or use existing):
   - Go to **Site Administration → Users → Accounts → Add a new user**
   - Create user: `mcp_service_user` (or use your admin account)

7. Generate token:
   - Go to **Site Administration → Server → Web Services → Manage tokens**
   - Click "Create token"
   - Select the user and the service you created
   - Save changes
   - **Copy the token** (it's a long alphanumeric string)

**Format:**
```
a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
```

**Security Notes:**
- Never commit this token to version control
- Use a dedicated service user with minimal permissions
- Rotate tokens periodically
- Restrict token to specific IP addresses if possible

---

#### 3. MOODLE_COURSE_ID

**Description:** The numeric ID of the Moodle course you want to work with.

**How to find it:**

1. Log in to Moodle
2. Navigate to the course (e.g., Fluorescence Microscopy course)
3. Look at the URL in your browser:
   ```
   https://microtutorcourses.org/course/view.php?id=123
   ```
4. The number after `id=` is your course ID (in this example: `123`)

**Alternative method:**
- Go to **Site Administration → Courses → Manage courses and categories**
- Hover over a course name to see its ID in the URL

**Format:**
```
123
```

---

### AWS Credentials (Optional)

Required only if deploying to or managing AWS Lightsail infrastructure:

#### 4. AWS_ACCESS_KEY_ID

**Description:** AWS access key for programmatic access.

**How to obtain:**
1. Log in to AWS Console
2. Navigate to **IAM → Users**
3. Select your user (or create a new one)
4. Go to **Security credentials** tab
5. Click **Create access key**
6. Choose "Command Line Interface (CLI)"
7. Copy the **Access key ID**

**Format:**
```
AKIAIOSFODNN7EXAMPLE
```

---

#### 5. AWS_SECRET_ACCESS_KEY

**Description:** AWS secret key paired with the access key.

**How to obtain:**
- Generated at the same time as the Access Key ID
- **Important:** Only shown once during creation - save it immediately!

**Format:**
```
wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

---

#### 6. AWS_DEFAULT_REGION

**Description:** AWS region where your Lightsail instance is located.

**Common values:**
- `us-east-1` (N. Virginia)
- `us-west-2` (Oregon)
- `eu-west-1` (Ireland)
- `ap-southeast-1` (Singapore)

**Format:**
```
us-east-1
```

---

## Setting Environment Variables

### For Claude Code Web

Add environment variables to your session environment:

1. Go to [claude.ai/code](https://claude.ai/code)
2. Select your repository
3. Click on **Settings** (gear icon)
4. Navigate to **Environment Variables**
5. Add each variable with its value
6. Save changes

**Variables to add:**
```
MOODLE_API_URL=https://microtutorcourses.org/webservice/rest/server.php
MOODLE_API_TOKEN=your_actual_token_here
MOODLE_COURSE_ID=123
AWS_ACCESS_KEY_ID=your_aws_key_here (optional)
AWS_SECRET_ACCESS_KEY=your_aws_secret_here (optional)
AWS_DEFAULT_REGION=us-east-1 (optional)
```

### For Local Development

Create a `.env` file in the repository root (already in `.gitignore`):

```bash
# .env file - NEVER commit this to git!

# Moodle MCP Server
MOODLE_API_URL=https://microtutorcourses.org/webservice/rest/server.php
MOODLE_API_TOKEN=your_actual_token_here
MOODLE_COURSE_ID=123

# AWS Credentials (optional)
AWS_ACCESS_KEY_ID=your_aws_key_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_here
AWS_DEFAULT_REGION=us-east-1
```

Then load them in your shell:
```bash
export $(cat .env | xargs)
```

Or use a tool like `direnv` for automatic loading.

---

## Verifying Configuration

### Test Moodle MCP Connection

Once environment variables are set, the SessionStart hook will check for their presence.

You can also manually test the connection:

```bash
# Test if variables are set
echo $MOODLE_API_URL
echo $MOODLE_API_TOKEN
echo $MOODLE_COURSE_ID

# Test Moodle API connection
curl "${MOODLE_API_URL}?wstoken=${MOODLE_API_TOKEN}&wsfunction=core_webservice_get_site_info&moodlewsrestformat=json"
```

If successful, you'll receive JSON with site information.

### Test AWS CLI Access

```bash
# Test AWS credentials
aws sts get-caller-identity

# List Lightsail instances
aws lightsail get-instances
```

---

## Troubleshooting

### "MOODLE_API_TOKEN not set" warning

**Solution:** Add the `MOODLE_API_TOKEN` environment variable to your Claude Code Web session or local `.env` file.

### "Invalid token" error when accessing Moodle

**Possible causes:**
1. Token is incorrect or expired
2. Web services not enabled in Moodle
3. REST protocol not enabled
4. Service doesn't have required functions

**Solution:** Re-check the token generation steps above.

### "Access denied" errors

**Possible causes:**
1. Service user doesn't have required permissions
2. Required web service functions not added to service
3. Token doesn't have access to specified course

**Solution:**
- Verify user has Teacher or Manager role in the course
- Add missing functions to the web service
- Check course ID is correct

### AWS credential errors

**Possible causes:**
1. Credentials are incorrect or expired
2. IAM user doesn't have Lightsail permissions
3. Wrong region specified

**Solution:**
- Regenerate AWS access keys
- Attach `AmazonLightsailFullAccess` policy to IAM user
- Verify correct region in `AWS_DEFAULT_REGION`

---

## Security Best Practices

1. **Never commit `.env` files** - They're in `.gitignore` for a reason
2. **Use minimal permissions** - Create dedicated service accounts
3. **Rotate credentials regularly** - Change tokens/keys every 90 days
4. **Monitor access logs** - Review Moodle and AWS logs for suspicious activity
5. **Use IP restrictions** - Limit Moodle tokens to specific IP ranges if possible
6. **Enable MFA** - For AWS accounts and Moodle admin accounts
7. **Separate staging/production** - Use different tokens for different environments

---

## Quick Reference

**Minimum required for MCP:**
```bash
MOODLE_API_URL=https://microtutorcourses.org/webservice/rest/server.php
MOODLE_API_TOKEN=<your-token>
MOODLE_COURSE_ID=<course-id>
```

**Full set for AWS deployment:**
```bash
MOODLE_API_URL=https://microtutorcourses.org/webservice/rest/server.php
MOODLE_API_TOKEN=<your-token>
MOODLE_COURSE_ID=<course-id>
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
AWS_DEFAULT_REGION=us-east-1
```

---

## Additional Resources

- [Moodle Web Services Documentation](https://docs.moodle.org/dev/Web_services)
- [Moodle MCP Server GitHub](https://github.com/peancor/moodle-mcp-server)
- [AWS Lightsail Documentation](https://docs.aws.amazon.com/lightsail/)
- [Claude Code Web Docs](https://code.claude.com/docs/en/claude-code-on-the-web)
