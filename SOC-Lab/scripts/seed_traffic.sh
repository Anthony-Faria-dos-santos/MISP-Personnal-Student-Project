#!/usr/bin/env bash
set -euo pipefail
host login-secure-banque.fr || true
curl -m 3 -v http://login-secure-banque.fr/auth || true
