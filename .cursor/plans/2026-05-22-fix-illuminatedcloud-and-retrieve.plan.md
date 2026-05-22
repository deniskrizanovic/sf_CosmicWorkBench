# Fix IlluminatedCloud + Retrieve-from-Org

## Context

Two symptoms:
1. IC showing ~106 errors in Apex files (screenshot) — symbol resolution broken
2. "Retrieve from org" UI controls non-functional

Root causes identified from codebase inspection:

**Critical:** `sfdx-project.json` only declares `force-app` as a package directory, but all working metadata lives in `src/main/default/`. IlluminatedCloud and SF CLI derive source roots from `packageDirectories` — anything outside that list is invisible to tooling.

**Secondary:** OAuth token for `home-denispoc` may have expired; IC can't retrieve metadata or resolve symbols without a live connection.

---

## Steps

### 1. Verify org auth status
```bash
sf org list
```
Look for `home-denispoc` with status `Connected`. If `Expired` or missing → step 2.

### 2. Re-authenticate (if needed)
```bash
sf org login web --alias home-denispoc --instance-url https://nsw06--denispoc.sandbox.my.salesforce.com/
```
Complete OAuth flow in browser.

### 3. Add `src` to sfdx-project.json package directories

**File:** `sfdx-project.json`

Change:
```json
"packageDirectories": [
  { "path": "force-app", "default": true }
]
```
To:
```json
"packageDirectories": [
  { "path": "force-app", "default": true },
  { "path": "src" }
]
```

Makes IC and SF CLI aware of `src/main/default/` metadata tree.

### 4. Regenerate IlluminatedCloud Offline Symbol Table

In IntelliJ: **Tools → IlluminatedCloud → Synchronize Project**

Rebuilds `IlluminatedCloud/home_denispoc/OfflineSymbolTable.zip` from live org → resolves the 106 symbol errors.

If greyed out or fails, clear stale cache first:
```bash
rm -rf "IlluminatedCloud/home_denispoc"
```
Then retry Synchronize Project.

### 5. Verify IC connection settings

**Settings → IlluminatedCloud → Connections**
- Connection name: `home-denispoc`
- Type: OAuth
- Module: `sf_CosmicWorkBench`
- Symbol table path: `$PROJECT_DIR$/IlluminatedCloud/home_denispoc/OfflineSymbolTable.zip`

### 6. Test retrieve from org

After symbol table regenerates: right-click file → **IlluminatedCloud → Retrieve from Server** (or toolbar button).

---

## Expected outcome

- IC error count drops to 0 after symbol table rebuild
- Retrieve controls become active (require live auth + IC knowing project files)
- `src/` metadata visible to SF CLI (`sf project retrieve start`)

---

## Files to modify

- `sfdx-project.json` — add `src` package directory entry
