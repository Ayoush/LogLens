#!/usr/bin/env bash

SSH_DIR="$HOME/.ssh"
status=0

# Check SSH directory
if [[ ! -d "$SSH_DIR" ]]; then
    echo "WARNING: $SSH_DIR does not exist."
    exit 1
fi

ssh_mode=$(stat -c '%a' "$SSH_DIR")
echo "$SSH_DIR permissions: $ssh_mode"

if [[ "$ssh_mode" != "700" ]]; then
    echo "WARNING: $SSH_DIR has insecure permissions: $ssh_mode"
    status=1
fi

# Check authorized_keys
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

if [[ -f "$AUTHORIZED_KEYS" ]]; then
    authorized_mode=$(stat -c '%a' "$AUTHORIZED_KEYS")
    echo "$AUTHORIZED_KEYS permissions: $authorized_mode"

    if [[ "$authorized_mode" != "600" && "$authorized_mode" != "644" ]]; then
        echo "WARNING: $AUTHORIZED_KEYS has insecure permissions: $authorized_mode"
        status=1
    fi
else
    echo "WARNING: $AUTHORIZED_KEYS does not exist."
fi

# Check private keys
private_key_found=false

for key in "$SSH_DIR"/id_*; do
    [[ -f "$key" ]] || continue
    [[ "$key" == *.pub ]] && continue

    private_key_found=true
    key_mode=$(stat -c '%a' "$key")

    echo "$key permissions: $key_mode"

    if ((8#$key_mode > 8#600)); then
        echo "WARNING: Private key $key has permissions $key_mode, which are looser than 0600."
        status=1
    fi
done

if [[ "$private_key_found" == false ]]; then
    echo "WARNING: No private keys found."
fi

exit "$status"
