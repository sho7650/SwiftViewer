# QA Phase Detailed Guide

## Parsing Output by QA Tool











### xcodebuild (Unit Tests)

**Command**:
```bash
xcodebuild -project SwiftViewer.xcodeproj -scheme SwiftViewer -sdk macosx test 2>&1
```

xcodebuild test output parsing:
- Test failures: lines containing "failed" after "Test Case"
- Compilation errors: lines with "error:" prefix
- Test summary: "** TEST FAILED **" or "** TEST SUCCEEDED **"
- Individual results: "Test Case '-[ClassName testMethod]' passed/failed (X.XXX seconds)"
- Build errors: "Build Failed" or lines with ❌
- Warning lines: lines with "warning:"

### Severity Classification

- CRITICAL: Security vulnerability (injection, SSRF, auth bypass, etc.)
- HIGH: Likely bug, lack of type safety, test failure, compilation error
- MEDIUM: Coding convention violation, readability issue
- LOW: Style improvement suggestion, performance hint

## Code Review Checklist

- [ ] No unjustified use of unsafe types (any, unknown casts, etc.)
- [ ] Error handling: async operations have proper error handling
- [ ] External input is validated
- [ ] No hardcoded magic numbers or strings
- [ ] Functions are within 50 lines
- [ ] Files are within 300 lines
- [ ] No circular imports/dependencies
- [ ] No force unwrapping (!) without justification
- [ ] Proper use of @MainActor for UI updates
- [ ] No retain cycles (weak/unowned references in closures)
- [ ] async/await used correctly for asynchronous operations
- [ ] Proper error handling with custom error types

## Issue Aggregation Template

```markdown
# Issues - Round N

**Date**: YYYY-MM-DD HH:MM
**Found**: X issues | **Severity**: CRITICAL=0, HIGH=0, MEDIUM=0, LOW=0
**Sources**: lint=a, typecheck=b, unit-test=c, e2e=d, review=e

## Issues

### [HIGH] Example issue title
- **File**: `path/to/file:line`
- **Source**: lint | typecheck | unit-test | e2e | review
- **Detail**: Description of the problem
- **Suggestion**: Proposed fix (if any)
- **Status**: open
```
