# Headless Ubuntu Agent Server — Design

**Date:** 2026-07-23
**Status:** Approved (pending spec review)
**Scope:** Provisioning only. Getting Claude Code to self-loop unattended (systemd/tmux/cron harness) is a deliberate follow-on spec.

## Goal

Provision a remote **Ubuntu Server** box, managed by this repo's home-manager setup, to run Claude Code agents (self-looping) with a full interactive shell and a working Rails toolchain. Everything reproducible from a cloned copy of these dotfiles plus a small bootstrap script.

Installed / working on the box:
- **mise, git, claude-code** and the full CLI toolchain via home-manager (nix)
- **Ruby & Rails** via mise (per-project pinned)
- **Headless chromium** via Playwright (self-managed binary)
- Full **zsh** environment (oh-my-zsh, plugins, powerlevel10k) identical to the laptop
- **Non-interactive git auth + commit signing** and **Claude auth**, all sourced from 1Password with no GUI

## Key decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Provisioning model | Ubuntu + **home-manager standalone** (Determinate Nix) | Keep Ubuntu; least disruptive; matches existing home-manager setup |
| Git auth | **1Password Service Account + `op read`** over HTTPS | Non-interactive, centralized/rotatable, portable to colleagues |
| Commit signing | **Key file** (`gpg.format=ssh`), NOT the desktop `op-ssh-sign` agent | Desktop SSH agent is GUI-only; unavailable headless |
| Ruby/Rails | **mise** (system apt toolchain for compilation) | Per-project version pinning; avoids nix/native-gem linking pain |
| Headless browser | **Playwright-managed chromium** (`--with-deps`) | Most reliable on non-NixOS; tool owns the binary |
| Claude auth | **Anthropic API key** via 1Password | Fully non-interactive; survives reboots; ideal for unattended loops |
| Account | **root** (for now; iterate later) | User's choice to start simple |
| Host label | `agent-box` (cosmetic; rename anytime) | Flake `hosts` key + drives `hosts/<label>.ini` config files |

## The profile-coupling constraint

`mkHomeConfig system hostname username cfg` uses `username` **both** as `home.username` **and** to select the profile `home/users/${username}.nix`. So the Linux account name *is* the profile name. Running as **root** → profile file is `home/users/root.nix`, build target `root@agent-box`.

**Root home-directory wrinkle:** `home/default.nix` computes `home.homeDirectory = "/home/${username}"`, which is wrong for root (`/root`). Fix locally in `home/users/root.nix`:
```nix
home.homeDirectory = lib.mkForce "/root";
```
(Chosen over generalizing `default.nix` to avoid touching shared code for a one-off.)

## Architecture / components

### 1. Flake wiring — `flake.nix` (3 additions)

- **`hosts.agent-box`**:
  ```nix
  agent-box = {
    system = "x86_64-linux";
    users = [ "root" ];
    # NO nixos/darwin flag -> only a homeConfiguration is generated
    # (skipped by nixosConfigurations/darwinConfigurations filters)
  };
  ```
- **`users.root`**:
  ```nix
  root = {
    name = "Pedro Ribeiro";
    overlays = [
      claude-code.overlays.default   # REQUIRED: claude module uses pkgs.claude-code
      (final: prev: { unstable = import nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system; config.allowUnfree = true; }; })
    ];
    extraSpecialArgs = { };
  };
  ```
- No change to `mkHomeConfig` — it already fans out over `hosts`. Result: `homeConfigurations."root@agent-box"`.

> **Testing note:** the flake `checks` builds each homeConfig's `activationPackage` per system. `root@agent-box` is `x86_64-linux`, so it can be built on the thinkpad or the server itself, **not** on the Mac (no cross-build).

### 2. Server profile — `home/users/root.nix` (new, minimal, headless)

Enables **only** headless-relevant modules; every GUI module is simply omitted (they already gate on `["thinkpad"]`). Follows the existing `pedro.nix` / `pedroribeiro.nix` shape (`enableFor`/`disableFor` helpers available but mostly unconditional here).

Enabled:
- **Shell (full "goodies"):** `zsh` — self-contained module clones oh-my-zsh, fetches plugins (autosuggestions, syntax-highlighting, autopair, vi-mode, fzf-tab) and powerlevel10k, reads `zshrc`. p10k glyphs render from the SSH **client's** font, so nothing extra server-side.
- **Editor:** `nvim`
- **Languages/runtime:** `mise`, `nodejs` (provides `npx` for Playwright)
- **Agent:** `claude`
- **CLI tools the zshrc references + daily use:** `git`, `ssh`, `ripgrep`, `fd`, `fzf`, `bat`, `eza`, `jq`, `direnv`, `zoxide`, `zellij`
- `home.homeDirectory = lib.mkForce "/root";`
- `_1password-cli` (CLI only — via profile `home.packages`, NOT the `onepassword` module which pulls `_1password-gui`)

Explicitly **off/omitted:** gnome + all extensions, vivaldi, ghostty, espanso, gimp, calibre, thunderbird, vscode, cursor, docker-desktop-ish GUIs, `onepassword` (GUI) module, etc.

Optional: `dotfiles.packages.enable` left **off** to stay lean (that bundle pulls ffmpeg/mpv/imagemagick/etc.). Revisit if an agent task needs one.

### 3. Headless auth

**Secret store:** a 1Password **Service Account** with read access to an `Automation` vault. The only secret at rest on the box is the SA token.

- `OP_SERVICE_ACCOUNT_TOKEN` → written once to `/root/.config/op.env` (mode 0600), sourced by zsh (`envExtra`) and by the bootstrap script.
- **Vault item convention** (you create these):
  - `op://Automation/github/pat` — GitHub fine-grained PAT, Contents read/write on target repos
  - `op://Automation/git-signing/private-key` — ed25519 private key for commit signing (+ its public key)
  - `op://Automation/anthropic/api-key` — Anthropic API key

**git — `home/programs/git/hosts/agent-box.ini`** (new; server-specific, parallels `thinkpad.ini`):
```ini
[include]
  path = ~/.config/git/common.ini
  path = ~/.config/git/profiles/personal.ini
[includeIf "gitdir:~/Code/healthium/nutrium/"]
  path = ~/.config/git/profiles/nutrium.ini

; --- HTTPS auth via 1Password (on-demand, no token at rest) ---
[credential "https://github.com"]
  helper = "!f() { test \"$1\" = get && \
    echo username=x-access-token && \
    echo password=$(op read op://Automation/github/pat); }; f"

; --- File-based SSH signing (NOT op-ssh-sign) ---
[gpg]
  format = ssh
[gpg "ssh"]
  ; program intentionally left default (ssh-keygen), NOT op-ssh-sign
[user]
  signingkey = /root/.ssh/git_sign.pub
[commit]
  gpgsign = true
```
> The credential helper needs `OP_SERVICE_ACCOUNT_TOKEN` in the environment (provided by `op.env`). Because git symlinks `git/config` → `hosts/${hostname}.ini`, this file is the server's whole git config surface.

**Signing key material** is placed by the bootstrap script (not committed): `op read` the private key → `/root/.ssh/git_sign` (0600) and public key → `/root/.ssh/git_sign.pub`, then append the pubkey to `~/.config/git/allowed_signers`.

**SSH module note:** the `ssh` module's linux `platform.ini` sets `IdentityAgent ~/.1password/agent.sock` (the GUI socket), which does not exist on the server. This is **inert** because all git traffic is HTTPS. Left as-is for now; not used.

### 4. System dependencies (apt, one-time, in bootstrap)

Toolchain for mise/ruby-build to compile Ruby + native gems, using the **system compiler** (kept separate from nix on purpose):
```
build-essential libssl-dev libyaml-dev zlib1g-dev libffi-dev libreadline-dev libgmp-dev libpq-dev curl git
```
(`libpq-dev` for the `pg` gem; `curl`/`git` bootstrap the installer + clone before nix's own git is on PATH.)

### 5. Headless browser

- Node/`npx` from the nix `nodejs` module.
- `npx playwright install --with-deps chromium` — installs a self-managed chromium under `~/.cache/ms-playwright` and (as root) apt-installs its runtime libs automatically.
- Agents drive it via a Playwright/Puppeteer MCP pointed at the managed binary.

### 6. Claude auth

- `op read op://Automation/anthropic/api-key` → `export ANTHROPIC_API_KEY` (via `op.env`/zsh env). Fully non-interactive; no login prompts, no expiry.

### 7. Bootstrap script — `bin/bootstrap-agent`

Ordered, re-runnable, executed **as root on the fresh box**. Follows the repo's existing `bin/` script conventions.

1. `apt-get update && apt-get install -y <system deps>` (section 4).
2. Install **Determinate Nix**: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm`; source the profile.
3. Install **op CLI** (`nix profile install nixpkgs#_1password-cli`); prompt once for the SA token → write `/root/.config/op.env` (0600); source it.
4. `op read op://Automation/github/pat` → clone dotfiles over HTTPS into `/root/.dotfiles`.
5. `nix run home-manager/release-26.05 -- switch -b backup --flake /root/.dotfiles#root@agent-box`.
6. Place signing key: `op read … > /root/.ssh/git_sign` (0600) + `.pub`; append pubkey to `allowed_signers`.
7. Ensure zsh is the login shell: append `[ -x "$HOME/.nix-profile/bin/zsh" ] && exec "$HOME/.nix-profile/bin/zsh" -l` to `/root/.profile` (nix zsh isn't in `/etc/shells`, so `chsh` is avoided).
8. `mise use -g ruby@<version>` + `mise install` (or per-project `.mise.toml`).
9. `npx playwright install --with-deps chromium`.
10. Print acceptance-test checklist.

## Data flow (auth at agent runtime)

```
Claude Code agent
  ├─ git clone/push  ──> git credential helper ──> op read (SA token) ──> GitHub PAT ──> HTTPS
  ├─ git commit -S   ──> ssh-keygen sign ──> /root/.ssh/git_sign ──> verified vs allowed_signers
  ├─ claude API      ──> ANTHROPIC_API_KEY (from op.env) ──> Anthropic
  └─ browser task    ──> Playwright MCP ──> ~/.cache/ms-playwright/chromium (headless)
```

## Error handling / edge cases

- **Private-dotfiles chicken-and-egg:** cloning the repo needs auth, so the PAT is fetched via `op read` in bootstrap step 4 *before* the clone; nothing depends on the repo being public.
- **Signing without desktop agent:** file-based key + `gpg.format=ssh`; `op-ssh-sign` explicitly not used.
- **Root home dir:** `lib.mkForce "/root"` in `home/users/root.nix`.
- **nix vs system toolchain:** Ruby and native gems compile with the apt toolchain; nix supplies CLI tools only. Do not force nix's `cc` onto ruby-build.
- **Inert IdentityAgent:** linux `platform.ini` points at a non-existent GUI socket; harmless because git is HTTPS-only.
- **No cross-build on Mac:** `root@agent-box` (x86_64-linux) builds on the thinkpad or the server, not the MacBook.
- **SA token exposure:** `op.env` is 0600, root-only, never committed. Rotate via 1Password if leaked.

## Testing / acceptance criteria

Run on the box after bootstrap:
1. `nix build /root/.dotfiles#homeConfigurations."root@agent-box".activationPackage` succeeds.
2. New `zsh` login shows powerlevel10k prompt; autosuggestions/syntax-highlighting/fzf-tab active.
3. `git clone https://github.com/<private-repo>` succeeds with no prompt (PAT via helper).
4. `git commit --allow-empty -S -m "signing test"` then `git log --show-signature` shows a good signature against `allowed_signers`.
5. `mise install` in a Rails repo → `ruby -v` / `bin/rails -v` report the pinned versions.
6. `claude -p "say hi"` returns a completion (API key path).
7. `npx playwright screenshot https://example.com /tmp/out.png` produces a PNG (headless chromium works).

## Prerequisites (your one-time actions, at bootstrap — not blocking implementation)

- Create a 1Password **Service Account** with read access to an `Automation` vault.
- Populate items: `github/pat` (fine-grained PAT), `git-signing/private-key` (+public), `anthropic/api-key`.
- Have the SA token ready to paste once during bootstrap.

## Out of scope (future specs)

- The **self-loop harness**: how Claude Code runs unattended (systemd service vs tmux vs scheduled/cron agents), restart policy, log rotation, concurrency.
- Multi-user / colleague onboarding generalization (parametrize account/vault names) — the design keeps this portable but doesn't build it yet.
