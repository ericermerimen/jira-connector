# Jira Cloud REST API v3 Reference

## Authentication

All requests use Basic Auth: `email:api_token`
Token is piped via stdin to curl (never in command-line args).

## Endpoints

### Get Current User
```
GET /rest/api/3/myself
```
Returns: `{ accountId, emailAddress, displayName, active }`

### Get Issue
```
GET /rest/api/3/issue/{issueKey}?fields=summary,status,issuetype,assignee,reporter,priority,created,updated,description
```

### Search Issues (JQL)
```
GET /rest/api/3/search?jql={jql}&startAt={n}&maxResults={n}&fields={fields}
```
Pagination: loop while `startAt < total`.

### Get Transitions
```
GET /rest/api/3/issue/{issueKey}/transitions
```
Returns: `{ transitions: [{ id, name }] }`
Only includes transitions available to the current user.

### Transition Issue
```
POST /rest/api/3/issue/{issueKey}/transitions
Body: { "transition": { "id": "<transitionId>" } }
```

### Assign Issue
```
PUT /rest/api/3/issue/{issueKey}/assignee
Body: { "accountId": "<accountId>" }
```

### Add Comment
```
POST /rest/api/3/issue/{issueKey}/comment
Body: {
  "body": {
    "type": "doc",
    "version": 1,
    "content": [
      {
        "type": "paragraph",
        "content": [{ "type": "text", "text": "Comment text" }]
      }
    ]
  }
}
```
Note: Jira Cloud uses Atlassian Document Format (ADF), not plain text.

### Get Issue Types
```
GET /rest/api/3/issuetype
```
Returns: `[{ id, name, subtask }]`

### Get Project
```
GET /rest/api/3/project/{projectKey}
```

## Rate Limiting

Jira Cloud uses token-bucket rate limiting. No published hard numbers.
- Typical limit: ~100 requests/minute for API tokens
- Response: HTTP 429 with `Retry-After` header (seconds)
- Strategy: exponential backoff, max 3 retries (handled by bin/jira-api)

## Common JQL Queries

| Query | JQL |
|---|---|
| My open issues | `assignee=currentUser() AND statusCategory!=Done ORDER BY updated DESC` |
| Project issues | `project={KEY} ORDER BY updated DESC` |
| Current sprint | `project={KEY} AND sprint in openSprints()` |
| By status | `status="{status}" AND assignee=currentUser()` |
