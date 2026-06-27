#!/usr/bin/env bash
# SSR ITIL v5 OneDrive Control
# Version: 2026.06.26-v8
# Co-authored by Microsoft 365 Copilot - Derek's Subscription

set -Eeuo pipefail

VERSION="2026.06.26-v8"
EMAIL_TO="eph61820@gmail.com"
OD="$HOME/OneDrive"
REPORT_DIR="$OD/_System/IntegrityReports"
NOW="$(date +%Y%m%d-%H%M%S)"
REPORT="$REPORT_DIR/itil-v5-onedrive-verify-$NOW.txt"

mkdir -p "$REPORT_DIR"

verify() {
  PASS=0
  WARN=0
  FAIL=0
  FAIL_CODES=()

  pass(){ echo "[PASS] $1"; PASS=$((PASS+1)); }
  warn(){ echo "[WARN] $1"; WARN=$((WARN+1)); }
  fail(){ echo "[FAIL] $1"; FAIL=$((FAIL+1)); FAIL_CODES+=("$2"); }

  {
    echo "============================================================"
    echo "SSR ITIL v5 ONEDRIVE VERIFY"
    echo "Version: $VERSION"
    echo "Started: $(date)"
    echo "Co-authored by Microsoft 365 Copilot - Derek's Subscription"
    echo "============================================================"
    echo

    echo "== 1. Monitoring and Event Management =="
    systemctl --user is-active --quiet onedrive \
      && pass "OneDrive service active" \
      || fail "OneDrive service not active" "SERVICE_DOWN"

    pgrep -x onedrive >/dev/null 2>&1 \
      && pass "OneDrive process present" \
      || fail "OneDrive process missing" "PROCESS_MISSING"

    echo
    echo "== 2. Configuration Management: OneDrive Client =="
    if [[ -x /usr/bin/onedrive ]]; then
      pass "Supported OneDrive binary present"
      /usr/bin/onedrive --version || true
    else
      fail "/usr/bin/onedrive missing" "BINARY_MISSING"
    fi

    echo
    echo "== 3. Configuration Management: 4-Pillar Structure =="
    for p in Family Truth Health Simplicity; do
      [[ -d "$OD/$p" ]] && pass "$p exists" || fail "$p missing" "PILLAR_MISSING_$p"
    done

    echo
    echo "== 4. Configuration Compliance: Top-Level Drift =="
    EXTRA="$(find "$OD" -mindepth 1 -maxdepth 1 -type d \
      ! -name Family \
      ! -name Truth \
      ! -name Health \
      ! -name Simplicity \
      ! -name _System \
      ! -name _LocalMintArchives \
      -printf '%f\n' 2>/dev/null | sort || true)"

    if [[ -z "$EXTRA" ]]; then
      pass "No unauthorized top-level folders"
    else
      warn "Top-level drift detected"
      echo "$EXTRA"
    fi

    echo
    echo "== 5. Service Validation: Default Folder Redirection =="
    check_link() {
      local name="$1"
      local expected="$2"
      local target
      target="$(readlink -f "$HOME/$name" 2>/dev/null || true)"

      [[ "$target" == "$expected" ]] \
        && pass "$name redirects correctly -> $target" \
        || fail "$name redirect differs -> ${target:-missing}" "REDIRECT_FAIL_$name"
    }

    check_link Desktop "$OD/Family/Desktop"
    check_link Documents "$OD/Truth/Documents"
    check_link Downloads "$OD/Simplicity/Downloads"
    check_link Pictures "$OD/Health/Pictures"
    check_link Videos "$OD/Family/Videos"
    check_link Music "$OD/Truth/Music"

    echo
    echo "== 6. Service Continuity: Safety Archive =="
    ARCHIVE="$(ls -d "$HOME"/OneDrive_LOCAL_SAFETY_ARCHIVE_* 2>/dev/null | tail -n 1 || true)"

    if [[ -n "$ARCHIVE" ]]; then
      COUNT="$(find "$ARCHIVE" -type f 2>/dev/null | wc -l | tr -d ' ')"
      pass "Safety archive present: $ARCHIVE ($COUNT files)"
    else
      warn "No safety archive found"
    fi

    echo
    echo "== 7. Release Validation: Non-Intrusive Sync Health =="
    JOURNAL="$(journalctl --user -u onedrive -n 120 --no-pager 2>/dev/null || true)"

    if echo "$JOURNAL" | grep -qi "ERROR:"; then
      warn "Recent OneDrive journal contains ERROR entries"
      echo "$JOURNAL" | grep -i "ERROR:" | tail -10
    else
      pass "No recent OneDrive ERROR entries detected"
    fi

    if echo "$JOURNAL" | grep -qi "Sync with Microsoft OneDrive is complete"; then
      pass "Recent journal confirms completed sync cycle"
    else
      warn "No recent completed sync confirmation found in journal"
    fi

    echo
    echo "== 8. Reporting Channel =="
    if command -v mail >/dev/null 2>&1 || command -v mailx >/dev/null 2>&1 || command -v msmtp >/dev/null 2>&1; then
      pass "Local report mail command present"
    else
      warn "No local mail command available"
    fi

    echo
    echo "== 9. ITIL Final Classification =="
    echo "PASS=$PASS"
    echo "WARN=$WARN"
    echo "FAIL=$FAIL"

    if [[ "$FAIL" -eq 0 && "$WARN" -eq 0 ]]; then
      echo "STATUS=HEALTHY"
    elif [[ "$FAIL" -eq 0 ]]; then
      echo "STATUS=STABLE_WITH_WARNINGS"
    else
      echo "STATUS=DEGRADED"
    fi

    echo
    echo "== 10. ITIL v5 Recovery Steps If FAIL > 0 =="
    if [[ "$FAIL" -eq 0 ]]; then
      echo "No fail-code remediation required."
    else
      echo "FAIL codes detected:"
      printf '%s\n' "${FAIL_CODES[@]}" | sort -u
      echo
      echo "AUTHORIZED REMEDIATION RUNBOOK:"
      echo

      for code in "${FAIL_CODES[@]}"; do
        case "$code" in
          SERVICE_DOWN|PROCESS_MISSING)
            echo "- $code:"
            echo "  1. Restart service: systemctl --user restart onedrive"
            echo "  2. Re-run verify: ~/.local/bin/ssr-itil-v5-onedrive-control.sh --verify"
            echo "  3. If still failing: inspect journalctl --user -u onedrive -n 120 --no-pager -l"
            ;;
          BINARY_MISSING)
            echo "- $code:"
            echo "  1. Restore OBS OneDrive package."
            echo "  2. Confirm /usr/bin/onedrive exists."
            echo "  3. Re-run verify."
            ;;
          PILLAR_MISSING_*)
            echo "- $code:"
            echo "  1. Recreate missing pillar under ~/OneDrive."
            echo "  2. Do not delete or move existing archive data."
            echo "  3. Re-run verify."
            ;;
          REDIRECT_FAIL_*)
            echo "- $code:"
            echo "  1. Repoint affected Linux default folder to approved OneDrive pillar path."
            echo "  2. Re-run verify."
            ;;
          *)
            echo "- $code:"
            echo "  1. Review report."
            echo "  2. Do not run broad rebuild."
            echo "  3. Escalate as controlled remediation only."
            ;;
        esac
        echo
      done

      echo "ITIL rule: no broad rebuild, no resync storm, no filesystem restructure unless explicitly authorized by FAIL-code remediation."
    fi

    echo
    echo "Report: $REPORT"
    echo "Co-authored by Microsoft 365 Copilot - Derek's Subscription"
  } | tee "$REPORT"

  MAIL_SENT=0

  if command -v mail >/dev/null 2>&1; then
    mail -s "SSR ITIL v5 OneDrive Verify PASS=$PASS WARN=$WARN FAIL=$FAIL" "$EMAIL_TO" < "$REPORT" && MAIL_SENT=1 || true
  elif command -v mailx >/dev/null 2>&1; then
    mailx -s "SSR ITIL v5 OneDrive Verify PASS=$PASS WARN=$WARN FAIL=$FAIL" "$EMAIL_TO" < "$REPORT" && MAIL_SENT=1 || true
  elif command -v msmtp >/dev/null 2>&1; then
    {
      echo "To: $EMAIL_TO"
      echo "Subject: SSR ITIL v5 OneDrive Verify PASS=$PASS WARN=$WARN FAIL=$FAIL"
      echo
      cat "$REPORT"
    } | msmtp "$EMAIL_TO" && MAIL_SENT=1 || true
  fi

  if [[ "$MAIL_SENT" -eq 1 ]]; then
    echo "[PASS] Email report sent to $EMAIL_TO" | tee -a "$REPORT"
  else
    echo "[WARN] Email report not sent; local report saved" | tee -a "$REPORT"
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "SSR ITIL v5 OneDrive Verify" "PASS=$PASS WARN=$WARN FAIL=$FAIL" || true
  fi
}

control() {
  systemctl --user restart onedrive || true
  verify
  systemctl --user status onedrive --no-pager -l || true
}

case "${1:-}" in
  --verify) verify ;;
  --control) control ;;
  *) verify ;;
esac
