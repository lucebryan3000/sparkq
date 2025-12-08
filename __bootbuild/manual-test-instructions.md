# Manual Test Instructions for Interactive Config Editor

## Overview
Testing Sprint 3 Task 3.2: Interactive Config Editor

## Test Scenario 1: Launch Config Editor from Menu

**Steps:**
1. Run: `cd __bootbuild && ./scripts/bootstrap-menu.sh`
2. When menu appears, press: `e`
3. Verify you see the config editor menu with 8 options
4. Press `q` to exit back to main menu

**Expected Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Interactive Config Editor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configuration Sections:
  1. Project settings (name, phase, owner)
  2. Git settings (user, email, branch)
  3. Docker settings (ports, database)
  4. Package settings (node, package manager)
  5. Claude settings (codex, model)
  6. Testing settings (coverage, framework)
  7. Show all config
  8. Show config file path
  q. Quit editor

Select section (1-8, q):
```

## Test Scenario 2: Edit Project Settings

**Steps:**
1. From config editor menu, press: `1`
2. Verify you see current project values:
   - name = sparkq
   - description = (empty)
   - phase = POC
   - owner = Bryan Luce
   - owner_email = bryan@appmelia.com
3. Press `1` to edit name
4. Enter new value: `sparkq-test`
5. Verify success message: `✓ Updated project.name = sparkq-test`
6. Press `b` to go back
7. Press `1` again to verify change persisted
8. Change it back to `sparkq`

**Expected:** All edits save correctly and persist

## Test Scenario 3: Test Validation

**Steps:**
1. From config editor menu, press: `4` (Package settings)
2. Press `1` to edit package_manager
3. Try entering invalid value: `invalid-pm`
4. Verify error message: `Error: Package manager must be npm, yarn, or pnpm`
5. Verify value not changed
6. Try entering valid value: `yarn`
7. Verify success message
8. Change back to `pnpm`

**Expected:** Validation prevents invalid values

## Test Scenario 4: View All Config

**Steps:**
1. From config editor menu, press: `7`
2. Verify you see formatted config display with all sections
3. Verify it shows both 20% and 80% sections

**Expected:** Clean display of entire config

## Test Scenario 5: Show Config File Path

**Steps:**
1. From config editor menu, press: `8`
2. Verify it shows: `Config file: __bootbuild/config/bootstrap.config`

**Expected:** Correct path displayed

## Test Scenario 6: Edit Multiple Values

**Steps:**
1. From config editor menu, press: `2` (Git settings)
2. Press `a` to edit all values
3. It should prompt for each value in sequence
4. Press Enter to keep current for each
5. Verify all values remain unchanged

**Expected:** Can navigate through all fields

## Test Scenario 7: Navigation Flow

**Steps:**
1. Launch config editor (`e` from main menu)
2. Enter a section (any number 1-6)
3. Press `b` to go back
4. Verify you're back at section selection menu
5. Press `q` to quit
6. Verify you're back at main bootstrap menu

**Expected:** Navigation works smoothly

## Test Scenario 8: Help Text Display

**Steps:**
1. From main menu, press: `h`
2. Verify help text includes: `e         Edit config interactively`
3. Verify menu display includes the 'e' command

**Expected:** Command documented everywhere

## Automated Test Results

Run: `cd __bootbuild && ./test-config-editor.sh`

**Expected output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Config Editor Test
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test 1: Reading current config values
--------------------------------------
✓ project.name = sparkq
✓ packages.package_manager = pnpm
✓ docker.app_port = unknown

Test 2: Testing validation
--------------------------------------
Testing valid port (3001)...
✓ Port validation works (3001 accepted)
Testing valid package manager (yarn)...
✓ Package manager validation works (yarn accepted)

Test 3: Simulating section display
--------------------------------------
[Shows project and docker sections]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  All Tests Passed!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Verification Checklist

After testing, verify:

- [ ] Config editor launches from menu with `e` command
- [ ] All 6 sections display correctly
- [ ] Can edit individual values
- [ ] Can edit all values in a section
- [ ] Validation works (rejects invalid input)
- [ ] Changes persist after navigating away
- [ ] Can view all config
- [ ] Can see config file path
- [ ] Navigation (back/quit) works
- [ ] Help text shows `e` command
- [ ] Menu displays `e` command
- [ ] No errors in console

## Files Modified

1. `/home/luce/apps/sparkq/__bootbuild/lib/config-manager.sh`
   - Added: `config_edit_interactive()`
   - Added: `edit_section()`
   - Added: `edit_config_key()`

2. `/home/luce/apps/sparkq/__bootbuild/scripts/bootstrap-menu.sh`
   - Added: 'e' command in menu display (line ~661)
   - Added: 'e' command handler (line ~791)
   - Added: 'e' in help text (line ~772)
   - Added: 'e' in --help output (line ~127)

## Notes

- Config editor validates input based on field type
- Some fields like docker.app_port are in [docker_defaults] section, not [docker]
- Editor shows only sections that exist in the config file
- Empty values are allowed (like description)
- Press Enter to keep current value
- Press 'b' to go back, 'q' to quit
