# Upstream PR Plan

The fork contains SGI-specific packaging and Linux work. Not every change should
go upstream, but these slices are small enough to consider.

## Candidate PRs

1. Linux `steam_appid.txt` isolation
   - Scope: per-process temp working directory for idlers.
   - Value: avoids project-file churn and watcher-triggered rebuilds.
   - Risk: low if kept independent from SGI's sibling `SteamUtility.Cli` path.

2. Safer process tracking and cleanup
   - Scope: stale `SteamUtility` process detection and cleanup.
   - Value: improves shutdown and manual stop behavior.
   - Risk: medium because Windows process enumeration differs.

3. WebKitGTK zoom fallback
   - Scope: non-Windows zoom via WebView JavaScript.
   - Value: makes zoom controls functional outside WebView2.
   - Risk: low.

4. Linux dependency documentation
   - Scope: distro package docs.
   - Value: helps Linux builders and users.
   - Risk: low, but upstream may not want Linux support surfaced yet.

5. JSON stdout hardening around utility commands
   - Scope: parse command output as JSON instead of substring matching.
   - Value: fewer broken frontend/backend states when logs leak into stdout.
   - Risk: medium because it tightens previously loose behavior.

## Not Good Upstream PRs

- Parent SGI release orchestration.
- AUR publishing tied to `bernardopg/SGI`.
- Sibling `steam-utility-multiplataform` workspace assumptions.
- SGI-specific versioning and submodule policy.

## PR Order

Start with documentation or WebKitGTK zoom, then idler isolation. Process
management should wait until Windows regression testing is stronger.
