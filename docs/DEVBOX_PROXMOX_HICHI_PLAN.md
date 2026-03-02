# Devbox on Proxmox (Target: hichi)

This branch introduces a practical migration plan to evolve the current single-file NixOS setup into a reusable devbox profile with PR-first workflow.

## Goals

- Keep current desktop/dev behavior working
- Prepare profile-based structure for Proxmox VM usage
- Make changes via GitHub pull requests (no direct pushes to `main`)
- Target host profile: `hichi` (and future proxmox devbox hosts)

## Immediate changes in this branch

1. Define GitHub PR workflow as default for this repository
2. Add PR template to enforce review quality
3. Add implementation roadmap for modular Nix layout

## Proposed next implementation steps

1. Add flake-based structure:
   - `flake.nix`
   - `hosts/hichi/default.nix`
   - `modules/common/*.nix`
   - `modules/dev/*.nix`
2. Split current monolithic config into:
   - base system
   - desktop profile
   - dev tooling profile
3. Add Proxmox VM guest defaults:
   - qemu-guest-agent
   - virtio-friendly defaults
   - safe firewall and SSH defaults
4. Add optional "full dev" module for broad tool enablement.

## Branch/PR policy

- Open a branch per change set
- Push branch to `origin` (GitHub)
- Merge to `main` only via reviewed PR
