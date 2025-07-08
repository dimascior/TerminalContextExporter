#!/bin/sh
#
# scripts/verify_master_context.sh
# POSIX-compliant constitutional verification script
# Authority: GuardRails.md + MASTER-CONTEXT-FRAMEWORK.md

echo "🔍 Verifying master context framework integrity..."

echo "📋 Checking constitutional document presence..."

# Check each document individually (most reliable POSIX approach)
if [ ! -f "docs/integration loop/GuardRails.md" ]; then
  echo "❌ CRITICAL: Missing constitutional document: docs/integration loop/GuardRails.md"
  exit 1
fi
echo "✅ Found: docs/integration loop/GuardRails.md"

if [ ! -f "docs/integration loop/CLAUDE.md" ]; then
  echo "❌ CRITICAL: Missing constitutional document: docs/integration loop/CLAUDE.md"
  exit 1
fi
echo "✅ Found: docs/integration loop/CLAUDE.md"

if [ ! -f "docs/TaskLoop/Isolate-Trace-Verify-Loop.md" ]; then
  echo "❌ CRITICAL: Missing constitutional document: docs/TaskLoop/Isolate-Trace-Verify-Loop.md"
  exit 1
fi
echo "✅ Found: docs/TaskLoop/Isolate-Trace-Verify-Loop.md"

if [ ! -f "docs/MASTER-CONTEXT-FRAMEWORK.md" ]; then
  echo "❌ CRITICAL: Missing constitutional document: docs/MASTER-CONTEXT-FRAMEWORK.md"
  exit 1
fi
echo "✅ Found: docs/MASTER-CONTEXT-FRAMEWORK.md"

if [ ! -f "docs/ThreeTierWorkflow.md" ]; then
  echo "❌ CRITICAL: Missing constitutional document: docs/ThreeTierWorkflow.md"
  exit 1
fi
echo "✅ Found: docs/ThreeTierWorkflow.md"

if [ ! -f "docs/AI-Agent-Project-Navigation-Report.md" ]; then
  echo "❌ CRITICAL: Missing constitutional document: docs/AI-Agent-Project-Navigation-Report.md"
  exit 1
fi
echo "✅ Found: docs/AI-Agent-Project-Navigation-Report.md"

echo "🔗 Verifying cross-document constitutional references..."

# Verify MASTER-CONTEXT-FRAMEWORK.md references GuardRails.md
if ! grep -q "GuardRails\.md" "docs/MASTER-CONTEXT-FRAMEWORK.md"; then
  echo "❌ CRITICAL: Master context framework missing GuardRails.md reference"
  exit 1
fi

# Verify ThreeTierWorkflow has constitutional guardrail banner
if ! grep -q "CONSTITUTIONAL GUARDRAIL BANNER" "docs/ThreeTierWorkflow.md"; then
  echo "❌ CRITICAL: ThreeTierWorkflow.md missing constitutional guardrail banner"
  exit 1
fi

# Verify AI Agent Report has master context version stamp
if ! grep -q "MASTER CONTEXT VERSION" "docs/AI-Agent-Project-Navigation-Report.md"; then
  echo "❌ CRITICAL: AI Agent Report missing master context version stamp"
  exit 1
fi

# Verify proceed checklist in AI Agent Report
if ! grep -q "PROCEED CHECKLIST" "docs/AI-Agent-Project-Navigation-Report.md"; then
  echo "❌ CRITICAL: Navigation report missing proceed checklist"
  exit 1
fi

# Verify bailout triggers in ThreeTierWorkflow
if ! grep -q "BAILOUT_IF" "docs/ThreeTierWorkflow.md"; then
  echo "❌ CRITICAL: ThreeTierWorkflow.md missing bailout triggers"
  exit 1
fi

# Verify execution bridge paths in ThreeTierWorkflow
if ! grep -q "MyExporter/DevScripts/claude-" "docs/ThreeTierWorkflow.md"; then
  echo "❌ CRITICAL: ThreeTierWorkflow.md missing full execution bridge paths"
  exit 1
fi

# Verify TaskLoop documents have constitutional headers
if ! grep -q "CONSTITUTIONAL GUARDRAIL BANNER" "docs/TaskLoop/Isolate-Trace-Verify-Loop.md"; then
  echo "❌ CRITICAL: TaskLoop/Isolate-Trace-Verify-Loop.md missing constitutional banner"
  exit 1
fi

if ! grep -q "CONSTITUTIONAL GUARDRAIL BANNER" "docs/TaskLoop/build-suite-discipline.md"; then
  echo "❌ CRITICAL: TaskLoop/build-suite-discipline.md missing constitutional banner"
  exit 1
fi

echo "✅ Master context framework integrity verified"
echo "🎉 Constitutional validation PASSED"
