# SpeakEasy profile template

Set up your own **deployment profile** for [SpeakEasy](https://github.com/Xellos1010/speakeasy-public):
the per-installation settings (server URL, other hosts on your network, file paths, and the *names* of
your secrets) that must never live in the application repository.

Use this repo as a GitHub template ("Use this template"), or just clone it.

## Quick start

```bash
git clone <your copy of this repo> speakeasy-profile && cd speakeasy-profile
SPEAKEASY_PUBLIC_URL=https://my-computer.my-network.example:8445 scripts/setup.sh
```

`scripts/setup.sh` has no prompts and is safe to re-run. It:

1. validates `profile.example.json` against `profile.schema.json` (stdlib Python 3, no installs);
2. writes `~/.config/speakeasy/profile/profile.json` (mode 0600) if it does not exist yet
   (`--force` overwrites, `--dest DIR` chooses another directory);
3. validates the result and prints the `export SPEAKEASY_PROFILE=...` line if you need one.

SpeakEasy then finds the profile on its own (`$SPEAKEASY_PROFILE`, else the default location above).
Confirm with:

```bash
speakeasy deployment-profile check
```

## What goes in a profile

See `profile.example.json` (placeholders only) and the schema `profile.schema.json`. The full field
reference is `docs/PROFILE.md` in the SpeakEasy repository.

**Never put a secret value in a profile.** Secrets are referenced by *name*: an environment variable
name such as `SPK_KS_PW`, or a keychain item name. The schema rejects unknown keys (so a stray
`password` field fails validation) and requires env-var names to look like env-var names.

## Keeping your profile private

Your real `profile.json` is listed in `.gitignore`. If you want your profile under version control,
keep it in a **separate private repository** and point `$SPEAKEASY_PROFILE` at it; do not commit it
to a public fork of this template.

## Schema pin

`profile.schema.json` is a copy of `speakeasy/profile.schema.json` from SpeakEasy (`schema_version` 1).
If SpeakEasy publishes `schema_version` 2, pull the new schema and example from this template's updates.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).

The SpeakEasy application itself is licensed under FSL-1.1-ALv2 (Functional Source License 1.1, Apache 2.0 Future License).
