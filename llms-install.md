# Installing moonbase (for AI agents)

moonbase is a hosted, remote MCP server. There is nothing to download, build or run, and no API key. This repository holds the moonbase Skill and the plugin manifests; it does not hold the server's source code.

## Cline

Open Cline's MCP settings file (`cline_mcp_settings.json`, through MCP Servers > Configure) and add this entry under `mcpServers`, keeping the entries already there:

```json
{
  "mcpServers": {
    "moonbase": {
      "type": "streamableHttp",
      "url": "https://app.moonbase.cloud/mcp"
    }
  }
}
```

Keep `"type": "streamableHttp"`. Without it Cline uses the older SSE transport.

Then ask the user to authorize the server: Cline opens the browser, the user signs in to moonbase (or signs up) and approves the access. Do not ask the user for a password, a token or an API key, and do not add headers.

## Check it worked

Call `list_missions`. It returns the account's projects; an empty list is a valid answer on a new account. If the call says the user is not signed in, run the authorization step again.

## Other tools

Setup steps for each tool: https://moonbase.cloud/docs/deploy-from-ai-chat
