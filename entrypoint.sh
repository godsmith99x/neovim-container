#!/usr/bin/env bash

if [[ -z "$ENTRYPOINT" ]]; then
    echo "Error: ENTRYPOINT variable is empty" >&2
    exit 1
fi

if [[ ! -x "$ENTRYPOINT" ]]; then
    echo "Error: $ENTRYPOINT either does not exist or is not executable" >&2
    exit 1
fi

"$ENTRYPOINT" "$@"
exit $?
