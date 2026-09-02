#!/usr/bin/env bash

find_godot() {
	if [[ -n "${GODOT_BIN:-}" && -x "$GODOT_BIN" ]]; then
		printf '%s\n' "$GODOT_BIN"
		return 0
	fi

	if command -v godot >/dev/null 2>&1; then
		command -v godot
		return 0
	fi

	return 1
}

stop_server() {
	local server_pid="$1"

	if kill -0 "$server_pid" 2>/dev/null; then
		echo
		echo "Stopping Dedicated Server..."
		kill "$server_pid" 2>/dev/null || true

		for _ in {1..20}; do
			if ! kill -0 "$server_pid" 2>/dev/null; then
				return
			fi
			sleep 0.1
		done

		kill -KILL "$server_pid" 2>/dev/null || true
	fi
}

main() {
	local godot_bin
	if ! godot_bin="$(find_godot)"; then
		echo "Error: Godot 4 was not found." >&2
		echo "Install Godot 4, add it to PATH, or set GODOT_BIN to its executable path." >&2
		return 127
	fi

	local project_dir
	project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

	echo "Starting Dedicated Server (Headless Mode) with: $godot_bin"

	"$godot_bin" --headless --path "$project_dir" &
	local server_pid=$!
	local stopping=false

	trap 'stopping=true; stop_server "$server_pid"' INT TERM EXIT

	local exit_code=0
	wait "$server_pid" 2>/dev/null || exit_code=$?
	trap - INT TERM EXIT

	if [[ "$stopping" == true ]]; then
		return 0
	fi
	return "$exit_code"
}

main "$@"
