# Cleanup Folder - Files Needing Review & Decision

This folder contains documentation files that need review, consolidation, archival, or deletion. Each file below has an assessment and recommended action.

---

## FILE ASSESSMENTS

### ❌ DELETE (No longer needed)

#### 1. **_BACKUP_CHECKLIST_20251207.md** (17KB)
- **What it is**: Backup of SCRIPT_STANDARDIZATION_CHECKLIST.md
- **Status**: Redundant
- **Action**: DELETE
- **Reason**: Backup file from Dec 7; original still exists
- **Risk**: None

#### 2. **SCRIPT_STANDARDIZATION_CHECKLIST.md** (17KB)
- **What it is**: Old standardization guide (567 lines)
- **Status**: Superseded
- **Action**: DELETE
- **Reason**: All content migrated to `playbooks/standardize-bootstrap-script.md` with enhancements
- **Verification**: ✅ Content verified as fully migrated (new version is 836 lines, 127% larger with examples)
- **Risk**: None

#### 3. **Bootstrap Playbooks - Script Implementation Guide.md** (21KB)
- **What it is**: Old comprehensive playbook guide (707 lines)
- **Status**: Superseded
- **Action**: DELETE
- **Reason**: Content split into 3 new playbooks (2,893 lines total)
  - `playbooks/create-bootstrap-script.md` (how to write new scripts)
  - `playbooks/run-bootstrap-scripts.md` (how to execute)
  - `playbooks/standardize-bootstrap-script.md` (how to fix existing)
- **Verification**: ✅ Content verified as fully migrated with improvements
- **Risk**: None

---

### 🏛️ ARCHIVE (Historical reference, work complete)

#### 4. **PHASE1_IMPROVEMENTS_IMPLEMENTED.md** (13KB)
- **What it is**: Documentation of Phase 1 work completed
- **Status**: Historical
- **Action**: ARCHIVE to `archived/` or DELETE
- **Purpose**: Records what was improved in Phase 1 (error handling, validation, etc.)
- **Decision needed**: Keep for historical reference? Or delete?
- **Recommendation**: ARCHIVE (gives context for future developers)

---

### ⏳ DECISION NEEDED (Unclear purpose or implementation status)

#### 5. **INTERACTIVE_VALIDATION_PLAN.md** (25KB - LARGEST FILE IN THIS FOLDER)
- **What it is**: Comprehensive plan for interactive validation system
- **Status**: UNKNOWN - Was this implemented?
- **Action**: INVESTIGATE + DECIDE
- **Decision options**:
  - **A) If implemented**: DELETE this (reference real implementation instead)
  - **B) If not implemented**: ARCHIVE + document decision in DECISION_LOG.md
  - **C) If partially done**: Extract completed parts, archive rest
- **Questions to answer**:
  - Does `lib/validation-common.sh` implement these ideas?
  - Are there bootstrap scripts using interactive validation?
  - Is this feature documented elsewhere?

#### 6. **ENHANCEMENTS.md** (6.1KB)
- **What it is**: List of enhancements made to bootstrap system
- **Status**: UNCLEAR - Is this documenting completed work or ideas for future?
- **Current content**: Enhanced error handling, validation, file creation, etc.
- **Action**: INVESTIGATE + DECIDE
- **Decision options**:
  - **A) If describing completed work**: Merge content into IMPLEMENTATION_SUMMARY.md, DELETE this
  - **B) If ideas for future work**: ARCHIVE + add to project roadmap
  - **C) If overlapping PHASE1_IMPROVEMENTS**: Consolidate, DELETE duplicate
- **Questions to answer**:
  - Is "Enhanced Bootstrap Menu" already implemented in `bootstrap-menu.sh`?
  - Are these features documented elsewhere?
  - Are these completed (Phase 1) or planned (backlog)?

#### 7. **SLASH_COMMAND_USAGE.md** (5.8KB)
- **What it is**: Guide for using bootstrap slash commands (specifically `/bootstrap-standardize`)
- **Status**: UNCLEAR - Still relevant?
- **Current content**: Usage examples, command reference for slash commands
- **Action**: INVESTIGATE + DECIDE
- **Decision options**:
  - **A) If still relevant**: Move to `docs/` as reference (not cleanup)
  - **B) If outdated**: DELETE (covered in slash command files themselves)
  - **C) If needs consolidation**: Merge with PLAYBOOK_INDEX.md, DELETE this
- **Questions to answer**:
  - Is this still accurate? (slash command location moved to `.claude/commands/`)
  - Does PLAYBOOK_INDEX.md already cover this?
  - Do developers refer to this doc?

---

## SUMMARY TABLE

| File | Size | Type | Action | Priority |
|------|------|------|--------|----------|
| `_BACKUP_CHECKLIST_20251207.md` | 17KB | Backup | DELETE | High |
| `SCRIPT_STANDARDIZATION_CHECKLIST.md` | 17KB | Superseded | DELETE | High |
| `Bootstrap Playbooks - Script Implementation Guide.md` | 21KB | Superseded | DELETE | High |
| `PHASE1_IMPROVEMENTS_IMPLEMENTED.md` | 13KB | Historical | ARCHIVE | Medium |
| `INTERACTIVE_VALIDATION_PLAN.md` | 25KB | Unknown | INVESTIGATE | Medium |
| `ENHANCEMENTS.md` | 6.1KB | Unknown | INVESTIGATE | Medium |
| `SLASH_COMMAND_USAGE.md` | 5.8KB | Unknown | INVESTIGATE | Low |

---

## CLEANUP ROADMAP

### Immediate (Delete - 5 min)
```bash
# Run this when ready:
cd __bootbuild/docs/cleanup
rm _BACKUP_CHECKLIST_20251207.md
rm SCRIPT_STANDARDIZATION_CHECKLIST.md
rm "Bootstrap Playbooks - Script Implementation Guide.md"
```

### Investigate (15-30 min)
1. Check if INTERACTIVE_VALIDATION_PLAN was implemented
2. Check if ENHANCEMENTS describes completed or future work
3. Verify SLASH_COMMAND_USAGE is still accurate

### Then Decide
Based on investigation, either:
- Archive files to `docs/archived/`
- Delete files
- Move back to main docs/ if still relevant
- Merge content into other docs

---

## How to Proceed

**Option A: Quick Cleanup** (10 min)
1. Delete 3 clearly superseded files (CHECKLIST, BACKUP, PLAYBOOKS)
2. Leave rest for investigation later

**Option B: Full Cleanup** (30-40 min)
1. Delete 3 files
2. Investigate 3 unclear files
3. Archive or consolidate based on findings

**Which would you prefer?**

---

## Notes

- All files are in UTF-8 and backed up in git history
- Nothing is truly lost; git can recover any file
- Move to `archived/` for "maybe later" items
- Delete for "definitely don't need" items
