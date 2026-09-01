# Contributing

Thanks for helping improve this Godot 3D multiplayer template. Keep
changes focused, easy to review, and aligned with the existing project style.

Please use a recent version of Godot Engine to avoid introducing compatibility issues.

## Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) when
opening an issue. Include:

- A short description of what happened.
- Steps to reproduce the issue.
- What you expected to happen.
- Your Godot version and operating system.
- Screenshots, videos, or logs when they help explain the problem.

For multiplayer bugs, mention whether you tested as host, client, or dedicated
server, and how many players were connected.

## Contributing pull requests

Direct pushes to `main` are not allowed. All changes go through a pull request,
which must pass the CI check before merging.

Before opening a pull request:

1. Create a descriptive branch, such as `fix/chat-freeze-bug` or
   `feat/player-skin-selection`.
2. Keep the pull request focused on one fix, feature, or documentation update.
3. Follow the existing GDScript style used in the project.
4. Test the behavior affected by your change.
5. Fill in the [PR template](.github/pull_request_template.md) checklist.

## Commit style

Use the following prefixes:

- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code changes that neither fix a bug nor add a feature
- `chore:` for maintenance tasks

Examples: `fix: chat freeze when player disconnects`, `feat: add player skin selection`.

## Coding style

- Use tabs for GDScript indentation.
- Use `snake_case` for files, variables, functions, and input actions.
- Use `PascalCase` for class names.
- Prefer typed variables and return types when adding code.
- Keep multiplayer gameplay state server-authoritative when possible.
- Treat client-provided values, such as nicknames, item IDs, and skin choices,
  as untrusted.

## Testing

There is no automated test suite in this repository. Validate changes manually
before opening a pull request.

For local multiplayer testing, use **Debug > Customize Run Instances** in the
Godot editor, enable multiple instances, and run at least two players.

For dedicated-server checks on Linux, run:

```bash
./run_headless_server.sh
```

Inventory, chat, connection, disconnection, and spawning changes should
be tested with at least two connected players.
