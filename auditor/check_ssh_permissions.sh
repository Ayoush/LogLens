#!/usr/bin/env bash

SSH_DIR="$HOME/.ssh"
status=0

# Check ~/.ssh directory
if [[ ! -d "$SSH_DIR" ]]; then
    echo "WARNING: $SSH_DIR does not exist."
    exit 1
fi

ssh_mode=$(stat -c '%a' "$SSH_DIR")
echo "$SSH_DIR permissions: $ssh_mode"

# Check authorized_keys
AUTHORIZED_KEYS="$SSH_DIR/authorized_keys"

if [[ -f "$AUTHORIZED_KEYS" ]]; then
    authorized_mode=$(stat -c '%a' "$AUTHORIZED_KEYS")
    echo "$AUTHORIZED_KEYS permissions: $authorized_mode"
else
    echo "WARNING: $AUTHORIZED_KEYS does not exist."
fi

# Check private SSH keys
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
    echo "WARNING: No private SSH keys found."
fi

exit "$status"
