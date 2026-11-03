#!/bin/sh
echo "Validating module-04" >> /tmp/progress.log

. /home/rhel/.bashrc 2>/dev/null || true

# --authfile keeps skopeo off its unreadable default path under runuser -l (no
# XDG_RUNTIME_DIR); the registry is anonymous so a missing file is harmless.
AUTHFILE=/home/rhel/.config/containers/auth.json

# Module 5 signs rhhi-demo@<image.digest> and verifies rhhi-demo:hardened by tag, so the
# registry tag must resolve to the digest recorded in ~/image.digest.
if [ ! -f /home/rhel/image.digest ]; then
    fail_validation - <<'EOF'
**Validation incomplete:** `~/image.digest` was not found.

Review **“Push Your Application Image”** in Module 4, then validate again.
EOF
fi
IMAGE_DIGEST=$(cat /home/rhel/image.digest)
REG_IMAGE_DIGEST=$(runuser -l rhel -c "skopeo inspect --authfile ${AUTHFILE} docker://${REGISTRY}/rhhi-demo:hardened | jq -r .Digest" 2>/dev/null)
if [ "$REG_IMAGE_DIGEST" != "$IMAGE_DIGEST" ]; then
    fail_validation - <<'EOF'
**Validation incomplete:** The registry digest for `rhhi-demo:hardened` does not match `~/image.digest`.

Review **“Push Your Application Image”** in Module 4, then validate again.
EOF
fi

# Module 5 signs python@<python.digest> and verifies python:3.12 by tag, so the registry
# tag must resolve to the digest recorded in ~/python.digest.
if [ ! -f /home/rhel/python.digest ]; then
    fail_validation - <<'EOF'
**Validation incomplete:** `~/python.digest` was not found.

Review **“Copy With a Preserved Digest”** in Module 4, then validate again.
EOF
fi
PYTHON_DIGEST=$(cat /home/rhel/python.digest)
REG_PYTHON_DIGEST=$(runuser -l rhel -c "skopeo inspect --authfile ${AUTHFILE} docker://${REGISTRY}/python:3.12 | jq -r .Digest" 2>/dev/null)
if [ "$REG_PYTHON_DIGEST" != "$PYTHON_DIGEST" ]; then
    fail_validation - <<'EOF'
**Validation incomplete:** The registry digest for `python:3.12` does not match `~/python.digest`.

Review **“Copy With a Preserved Digest”** in Module 4, then validate again.
EOF
fi

echo "PASS: rhhi-demo and python mirror digests match what Module 5 will sign" >> /tmp/progress.log
exit 0
