# guard-rm.ps1 — Destructive-command PreToolUse guard for Claude Code (Windows)
#
# Invoked by .claude/settings.json hooks.PreToolUse before every Bash tool call.
# Reads the tool input as JSON on stdin; exits 0 to allow the command, non-zero
# (exit 2) to BLOCK with a stderr message Claude Code shows in the transcript.
#
# Blocks when ANY destructive verb (rm / rmdir / unlink / Remove-Item / del /
# erase / Clear-RecycleBin / shred / srm / find -delete) targets a path that
# resolves OUTSIDE the nearest .git/ ancestor of cwd.
#
# The rule is evaluated at EVERY command position in the command line — not just
# the first token of each top-level pipe segment. Positions reached through `;`,
# `&&`, `||`, `&`, a newline, a subshell/brace group, a command or process
# substitution, an argv-carrier (`xargs`, `env`, `timeout`, `find -exec`, …) or
# a nested interpreter (`bash -c`, `pwsh -c`, …) are all judged.
#
# Override: prepend `HARNESS_ALLOW_OUTSIDE_RM=1 ` to the command, or set
# `$env:HARNESS_ALLOW_OUTSIDE_RM=1` in PowerShell, for a single call.
#
# See `.harness/rules/75-safety-hook.md` for full contract and disable path.
#
# CROSS-SHELL NOTE — this file is the byte-symmetric twin of guard-rm.sh and is
# NOT executable by the agents that maintain it. Three constraints are therefore
# load-bearing and must not be relaxed:
#   1. PowerShell parses the WHOLE file before executing, so a syntax error in a
#      never-taken branch is fatal to the entire script.
#   2. .NET string indexing / Substring THROW on out-of-range where bash
#      `${s:$i:1}` yields ''. Every lookahead goes through Get-Slice, and the
#      scanner is wrapped in try/catch, because an escaping terminating error
#      exits 1 — which Claude Code treats as NON-blocking, i.e. the guard would
#      silently DISARM. That is a security requirement, not hygiene.
#   3. Never name a variable $isWindows / $input / $args / $error / $matches /
#      $host / $home / $pwd / $this / $profile — automatic variables collide
#      case-insensitively and throw on first use.

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# A literal backtick, built without backtick-quoting so no parse ambiguity can
# reach the rest of the file.
$BackTick = [string][char]0x60

# 1. Read tool input JSON from stdin
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }
try {
    $payload = $raw | ConvertFrom-Json
} catch {
    # Unparseable payload — nothing to guard.
    exit 0
}
$cmd = $payload.tool_input.command
if (-not $cmd) { exit 0 }

# 2. Override env var: bail out cheaply.
if ($env:HARNESS_ALLOW_OUTSIDE_RM -eq '1') {
    [Console]::Error.WriteLine('harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.')
    exit 0
}

# 2b. Command-text override prefix. Evaluated EXACTLY ONCE, on the top-level
# command, before the .git/ walk and before any parsing — never per position.
# Re-applying it per position would make
# `echo x && HARNESS_ALLOW_OUTSIDE_RM=1 rm -rf C:\x` self-authorizing.
# StartsWith(..., Ordinal) is deliberate: PS `-eq` / `-match` are
# case-INSENSITIVE and would accept `harness_allow_outside_rm=1`, a widening.
$ovrTrim = $cmd.TrimStart([char[]]@([char]32, [char]9))
if ($ovrTrim.StartsWith('HARNESS_ALLOW_OUTSIDE_RM=1 ', [StringComparison]::Ordinal) -or
    $ovrTrim.StartsWith(('HARNESS_ALLOW_OUTSIDE_RM=1' + [string][char]9), [StringComparison]::Ordinal)) {
    [Console]::Error.WriteLine('harness-kit guard-rm: override active (HARNESS_ALLOW_OUTSIDE_RM=1) — allowing destructive command.')
    exit 0
}

# 3. Walk up to nearest .git/ ancestor of cwd.
$dir = (Get-Location).Path
$repoRoot = $null
while ($dir) {
    if (Test-Path (Join-Path $dir '.git')) { $repoRoot = $dir; break }
    $parent = Split-Path $dir -Parent
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
}
if (-not $repoRoot) {
    [Console]::Error.WriteLine('harness-kit guard-rm: WARN no .git/ ancestor — guard inactive.')
    exit 0
}

# 4. Truncate (boundary B11).
if ($cmd.Length -gt 8192) { $cmd = $cmd.Substring(0, 8192) }

# Destructive verb set.
# LEDGER: $destructiveVerbs is the human-readable declaration of the verb set
# and the diff target for "the verb set is unchanged". Test-DestructiveVerb
# below is its mechanical twin — both lists have exactly 9 members and MUST be
# edited together.
$destructiveVerbs = @(
    'rm', 'rmdir', 'unlink', 'Remove-Item', 'del', 'erase',
    'Clear-RecycleBin', 'shred', 'srm'
)
# Find-predicate flags whose following arg is non-path. Deliberately UNUSED —
# kept as historical documentation of the D-1/D-2 fix (v0.15.1): the skip these
# names once drove is disabled for every verb, see the NOTE in
# Get-OffendingFromWalk. Do not re-wire without a driver row.
$findPredicates = @('-name', '-type', '-regex', '-iname', '-perm', '-mtime', '-size', '-path', '-ipath', '-newer')

# Argv-carrier verbs (IS-1 row 9). These are NOT destructive verbs: they never
# cause a block by themselves, they only expose further command positions.
# Exact, case-sensitive POSIX command names.
$carrierVerbs = @('xargs', 'env', 'nohup', 'nice', 'time', 'timeout', 'command', 'exec', 'find')
# Nested interpreters whose argument is itself a command string.
$shellVerbs = @('bash', 'sh', 'dash', 'zsh', 'ksh')

# The characters at least one scanner dispatch row reacts to. Every other byte
# behaves identically in the NORMAL / single-quoted / double-quoted states, so
# it takes the hoisted append fast path.
$specialScanChars = @(
    '\', "'", '"', $BackTick, '$', '<', '>', '&', '|', ';',
    '(', ')', '{', '}', '#', [string][char]10, [string][char]13
)

function Test-DestructiveVerb([string]$v) {
    foreach ($d in $destructiveVerbs) { if ($v -ieq $d) { return $true } }
    return $false
}

function Test-CarrierVerb([string]$v) {
    foreach ($c in $carrierVerbs) { if ($v -ceq $c) { return $true } }
    return $false
}

function Test-PwshVerb([string]$v) {
    return ($v -ieq 'pwsh' -or $v -ieq 'powershell')
}

function Test-ShellVerb([string]$v) {
    foreach ($sv in $shellVerbs) { if ($v -ieq $sv) { return $true } }
    return $false
}

# Length-guarded slice. Mirrors bash `${s:$i:n}` EXACTLY, including the
# near-the-end short read; .NET Substring would throw instead (see note 2).
function Get-Slice([string]$s, [int]$start, [int]$count) {
    if ($null -eq $s) { return '' }
    if ($start -lt 0 -or $start -ge $s.Length) { return '' }
    $avail = $s.Length - $start
    if ($count -gt $avail) { $count = $avail }
    if ($count -le 0) { return '' }
    return $s.Substring($start, $count)
}

# 5. Whitespace-aware quote tokenizer. Returns $null on parse failure.
function Get-Tokens([string]$s) {
    $tokens = [System.Collections.Generic.List[string]]::new()
    $cur = New-Object System.Text.StringBuilder
    $inSingle = $false
    $inDouble = $false
    $hasContent = $false
    for ($i = 0; $i -lt $s.Length; $i++) {
        $ch = $s[$i]
        if (-not $inSingle -and -not $inDouble -and ($ch -eq ' ' -or $ch -eq "`t")) {
            if ($hasContent) {
                $tokens.Add($cur.ToString())
                [void]$cur.Clear()
                $hasContent = $false
            }
            continue
        }
        if (-not $inDouble -and $ch -eq "'") {
            $inSingle = -not $inSingle
            $hasContent = $true
            continue
        }
        if (-not $inSingle -and $ch -eq '"') {
            $inDouble = -not $inDouble
            $hasContent = $true
            continue
        }
        [void]$cur.Append($ch)
        $hasContent = $true
    }
    if ($inSingle -or $inDouble) { return $null }
    if ($hasContent) { $tokens.Add($cur.ToString()) }
    # Return as string array (not List) to prevent caller's array-coercion bugs.
    return ,$tokens.ToArray()
}

# 6. Split top-level pipes (not inside quotes).
function Split-Pipes([string]$s) {
    $segments = [System.Collections.Generic.List[string]]::new()
    $cur = New-Object System.Text.StringBuilder
    $inSingle = $false; $inDouble = $false
    for ($i = 0; $i -lt $s.Length; $i++) {
        $ch = $s[$i]
        if (-not $inDouble -and $ch -eq "'") { $inSingle = -not $inSingle }
        elseif (-not $inSingle -and $ch -eq '"') { $inDouble = -not $inDouble }
        if ($ch -eq '|' -and -not $inSingle -and -not $inDouble) {
            $segments.Add($cur.ToString().Trim())
            [void]$cur.Clear()
            continue
        }
        [void]$cur.Append($ch)
    }
    $segments.Add($cur.ToString().Trim())
    return ,$segments.ToArray()
}

# 6b. Fast-path trigger test. The scanner can only emit a boundary Split-Pipes
# does not when one of these bytes is present. Written as twelve separate
# ordinal Contains() tests, never one character class, because a mis-parsed
# class member would be a SILENT false negative.
function Test-ScannerTrigger([string]$s) {
    if ($s.Contains(';')) { return $true }
    if ($s.Contains('&')) { return $true }
    if ($s.Contains('(')) { return $true }
    if ($s.Contains(')')) { return $true }
    if ($s.Contains('{')) { return $true }
    if ($s.Contains('}')) { return $true }
    if ($s.Contains($BackTick)) { return $true }
    if ($s.Contains('<')) { return $true }
    if ($s.Contains('>')) { return $true }
    if ($s.Contains('\')) { return $true }
    if ($s.Contains([string][char]10)) { return $true }
    if ($s.Contains([string][char]13)) { return $true }
    return $false
}

# Emit the current buffer as a position and clear it. Both parameters are .NET
# reference types, so the caller's objects really are mutated.
function Add-ScannerPosition {
    param(
        [System.Collections.Generic.List[string]]$list,
        [System.Text.StringBuilder]$sb
    )
    $t = $sb.ToString().Trim()
    if ($t -ne '') { [void]$list.Add($t) }
    [void]$sb.Clear()
}

function Get-NestTop([System.Collections.Generic.List[string]]$kinds) {
    if ($kinds.Count -gt 0) { return $kinds[$kinds.Count - 1] }
    return ''
}

function Pop-NestFrame {
    param(
        [System.Collections.Generic.List[string]]$kinds,
        [System.Collections.Generic.List[string]]$bufs,
        [System.Collections.Generic.List[string]]$sts
    )
    if ($kinds.Count -gt 0) {
        $n = $kinds.Count - 1
        $kinds.RemoveAt($n)
        $bufs.RemoveAt($n)
        $sts.RemoveAt($n)
    }
}

# 6c. Position scanner — a single-pass character lexer with an explicit nesting
# stack that emits the substrings at which a shell would begin parsing a simple
# command. Returns $null on unresolvable structure (the caller then blocks,
# fail-closed) — the SAME failure contract as Get-Tokens.
#
# States: N (normal) · SQ (single-quoted) · DQ (double-quoted) · C (comment) ·
#         H (here-document body)
# Frames: CMDSUB `$(` · BQ backtick · PROCSUB `<(`/`>(` · GROUP_PAREN `(` ·
#         GROUP_BRACE `{` · PARAM `${` · ARITH `$((` · VPAREN/VBRACE (balance
#         frames inside PARAM/ARITH).
# CMDSUB/BQ/PROCSUB/GROUP_PAREN/GROUP_BRACE count toward the depth bound (2);
# PARAM/ARITH/VPAREN/VBRACE do not — they exist only so their closer is matched
# instead of being read as a separator.
function Split-CommandPositions([string]$s) {
    try {
        $posList = [System.Collections.Generic.List[string]]::new()
        $buf = New-Object System.Text.StringBuilder
        $stIn = 'N'
        # $sqAnsi is meaningful ONLY while $stIn -eq 'SQ'; it is re-set on every
        # SQ entry (SQ is enterable only from the NORMAL `'` cell) and never
        # read otherwise.
        $sqAnsi = $false
        $nestKind = [System.Collections.Generic.List[string]]::new()
        $nestBuf = [System.Collections.Generic.List[string]]::new()
        $nestSt = [System.Collections.Generic.List[string]]::new()
        $nestTop = ''
        $nestDepth = 0
        $hdQueue = [System.Collections.Generic.List[string]]::new()
        $hdStrip = [System.Collections.Generic.List[bool]]::new()
        $hdHead = 0
        $hdLine = New-Object System.Text.StringBuilder
        $lf = [string][char]10
        $cr = [string][char]13
        $tabStr = [string][char]9
        # Index at which row 12 last appended a redirection operator (`>` / `<`)
        # at NORMAL. Row 15 uses it instead of the raw character at i-1 — see
        # row 12.
        # The "none recorded yet" sentinel MUST stay -2, NOT -1: row 15 compares
        # it against ($i - 1), whose domain over this loop is {-1, 0, … len-2},
        # so -1 COLLIDES at $i -eq 0 and appends a leading '&' instead of
        # flushing it — fail-OPEN, and '&' is PowerShell's call operator, which
        # the guard reaches by recursing into `pwsh -c` strings. Pinned by
        # driver rows R4 / R5.
        $redirIdx = -2
        $len = $s.Length
        $i = 0

        while ($i -lt $len) {
            $ch = [string]$s[$i]

            # ---- verbatim frames: copy bytes until the matching closer ----
            if ($nestTop -eq 'PARAM' -or $nestTop -eq 'ARITH' -or $nestTop -eq 'VPAREN' -or $nestTop -eq 'VBRACE') {
                if ($ch -eq '\') {
                    [void]$buf.Append((Get-Slice $s $i 2)); $i += 2; continue
                }
                if ($ch -eq '$') {
                    if ((Get-Slice $s $i 3) -eq '$((') {
                        [void]$buf.Append('$(('); $i += 3
                        [void]$nestKind.Add('ARITH'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                        $nestTop = 'ARITH'; continue
                    }
                    if ((Get-Slice $s $i 2) -eq '${') {
                        [void]$buf.Append('${'); $i += 2
                        [void]$nestKind.Add('PARAM'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                        $nestTop = 'PARAM'; continue
                    }
                }
                if ($ch -eq ')' -and $nestTop -eq 'ARITH' -and (Get-Slice $s $i 2) -eq '))') {
                    [void]$buf.Append('))'); $i += 2
                    Pop-NestFrame $nestKind $nestBuf $nestSt
                    $nestTop = Get-NestTop $nestKind; continue
                }
                if ($ch -eq '(') {
                    [void]$buf.Append('('); $i += 1
                    [void]$nestKind.Add('VPAREN'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                    $nestTop = 'VPAREN'; continue
                }
                if ($ch -eq '{') {
                    [void]$buf.Append('{'); $i += 1
                    [void]$nestKind.Add('VBRACE'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                    $nestTop = 'VBRACE'; continue
                }
                if ($ch -eq ')' -and $nestTop -eq 'VPAREN') {
                    [void]$buf.Append(')'); $i += 1
                    Pop-NestFrame $nestKind $nestBuf $nestSt
                    $nestTop = Get-NestTop $nestKind; continue
                }
                if ($ch -eq '}' -and ($nestTop -eq 'PARAM' -or $nestTop -eq 'VBRACE')) {
                    [void]$buf.Append('}'); $i += 1
                    Pop-NestFrame $nestKind $nestBuf $nestSt
                    $nestTop = Get-NestTop $nestKind; continue
                }
                [void]$buf.Append($ch); $i += 1; continue
            }

            # ---- comment: discard bytes to end of line ----
            if ($stIn -eq 'C') {
                if ($ch -eq $lf -or $ch -eq $cr) {
                    Add-ScannerPosition $posList $buf
                    if ($hdHead -lt $hdQueue.Count) { $stIn = 'H'; [void]$hdLine.Clear() }
                    else { $stIn = 'N' }
                }
                $i += 1; continue
            }

            # ---- here-document body: data, never a command position ----
            if ($stIn -eq 'H') {
                if ($ch -eq $lf -or $ch -eq $cr) {
                    $cmpLine = $hdLine.ToString()
                    if ($hdStrip[$hdHead]) { $cmpLine = $cmpLine.TrimStart([char[]]@([char]9)) }
                    if ($cmpLine -ceq $hdQueue[$hdHead]) {
                        $hdHead += 1
                        if ($hdHead -ge $hdQueue.Count) { $stIn = 'N' }
                    }
                    [void]$hdLine.Clear()
                } else {
                    [void]$hdLine.Append($ch)
                }
                $i += 1; continue
            }

            # ---- hoisted catch-all row ----
            # Every byte that NO dispatch row keys on behaves identically in N,
            # SQ and DQ: append. Nothing in the scanner's state depends on an
            # ordinary byte beyond appending it.
            if ($specialScanChars -notcontains $ch) {
                [void]$buf.Append($ch); $i += 1; continue
            }

            # ---- row 1: backslash ----
            if ($ch -eq '\') {
                if ($stIn -eq 'SQ' -and -not $sqAnsi) {
                    [void]$buf.Append('\'); $i += 1
                } else {
                    [void]$buf.Append((Get-Slice $s $i 2)); $i += 2
                }
                continue
            }

            # ---- row 2: single quote ----
            if ($ch -eq "'") {
                if ($stIn -eq 'N') {
                    $prevCh = ''
                    if ($i -gt 0) { $prevCh = [string]$s[$i - 1] }
                    [void]$buf.Append("'")
                    $stIn = 'SQ'
                    $sqAnsi = ($prevCh -eq '$')
                } elseif ($stIn -eq 'SQ') {
                    [void]$buf.Append("'"); $stIn = 'N'
                } else {
                    [void]$buf.Append("'")
                }
                $i += 1; continue
            }

            # ---- row 3: double quote ----
            if ($ch -eq '"') {
                if ($stIn -eq 'N') {
                    [void]$buf.Append('"'); $stIn = 'DQ'
                } elseif ($stIn -eq 'DQ') {
                    [void]$buf.Append('"'); $stIn = 'N'
                } else {
                    [void]$buf.Append('"')
                }
                $i += 1; continue
            }

            # ---- SQ: every remaining row is "append" ----
            if ($stIn -eq 'SQ') {
                [void]$buf.Append($ch); $i += 1; continue
            }

            # ---- row 4: backtick (self-toggling frame; pushes at N and at DQ) ----
            if ($ch -eq $BackTick) {
                if ($nestTop -eq 'BQ') {
                    Add-ScannerPosition $posList $buf
                    $n = $nestKind.Count - 1
                    $savedBuf = $nestBuf[$n]
                    $savedSt = $nestSt[$n]
                    Pop-NestFrame $nestKind $nestBuf $nestSt
                    $nestTop = Get-NestTop $nestKind
                    $nestDepth -= 1
                    [void]$buf.Clear(); [void]$buf.Append($savedBuf); $stIn = $savedSt
                } else {
                    $nestDepth += 1
                    if ($nestDepth -gt 2) { return $null }
                    [void]$nestKind.Add('BQ'); [void]$nestBuf.Add($buf.ToString()); [void]$nestSt.Add($stIn)
                    $nestTop = 'BQ'
                    [void]$buf.Clear(); $stIn = 'N'
                }
                $i += 1; continue
            }

            # Multi-character lookahead is only needed for these lead bytes.
            $two = ''
            $three = ''
            if ($ch -eq '$' -or $ch -eq '<' -or $ch -eq '>' -or $ch -eq '&') {
                $two = Get-Slice $s $i 2
                $three = Get-Slice $s $i 3
            }

            # ---- row 5: $((  (append + verbatim ARITH frame, N and DQ alike) ----
            if ($three -eq '$((') {
                [void]$buf.Append('$(('); $i += 3
                [void]$nestKind.Add('ARITH'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                $nestTop = 'ARITH'; continue
            }
            # ---- row 6: $(  ----
            if ($two -eq '$(') {
                $nestDepth += 1
                if ($nestDepth -gt 2) { return $null }
                [void]$nestKind.Add('CMDSUB'); [void]$nestBuf.Add($buf.ToString()); [void]$nestSt.Add($stIn)
                $nestTop = 'CMDSUB'
                [void]$buf.Clear(); $stIn = 'N'; $i += 2; continue
            }
            # ---- row 7: ${  ----
            if ($two -eq '${') {
                [void]$buf.Append('${'); $i += 2
                [void]$nestKind.Add('PARAM'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                $nestTop = 'PARAM'; continue
            }
            # ---- row 9: <<<  ----
            if ($three -eq '<<<') {
                [void]$buf.Append('<<<'); $i += 3; continue
            }
            # ---- row 10: <<  (here-document; NORMAL only) ----
            if ($two -eq '<<' -and $stIn -eq 'N') {
                [void]$buf.Append('<<'); $i += 2
                $strip = $false
                if ((Get-Slice $s $i 1) -eq '-') {
                    $strip = $true; [void]$buf.Append('-'); $i += 1
                }
                while ($i -lt $len) {
                    $c2 = [string]$s[$i]
                    if ($c2 -eq ' ' -or $c2 -eq $tabStr) { [void]$buf.Append($c2); $i += 1 }
                    else { break }
                }
                $w = New-Object System.Text.StringBuilder
                $c2 = Get-Slice $s $i 1
                if ($c2 -eq "'" -or $c2 -eq '"') {
                    $qch = $c2
                    [void]$buf.Append($qch); $i += 1
                    while ($i -lt $len -and ([string]$s[$i]) -ne $qch) {
                        [void]$w.Append([string]$s[$i]); [void]$buf.Append([string]$s[$i]); $i += 1
                    }
                    if ($i -ge $len) { return $null }
                    [void]$buf.Append($qch); $i += 1
                } else {
                    while ($i -lt $len) {
                        $c2 = [string]$s[$i]
                        if ($c2 -eq ' ' -or $c2 -eq $tabStr -or $c2 -eq $lf -or $c2 -eq $cr) { break }
                        if ($c2 -eq ';' -or $c2 -eq '&' -or $c2 -eq '|') { break }
                        if ($c2 -eq '(' -or $c2 -eq ')' -or $c2 -eq '<' -or $c2 -eq '>') { break }
                        if ($c2 -eq '\') {
                            [void]$buf.Append('\'); $i += 1
                            if ($i -ge $len) { break }
                            $c2 = [string]$s[$i]
                        }
                        [void]$w.Append($c2); [void]$buf.Append($c2); $i += 1
                    }
                }
                if ($w.Length -gt 0) {
                    [void]$hdQueue.Add($w.ToString())
                    [void]$hdStrip.Add($strip)
                }
                continue
            }
            # ---- row 11: <( / >(  (process substitution; NORMAL only) ----
            if ($stIn -eq 'N' -and ($two -eq '<(' -or $two -eq '>(')) {
                $nestDepth += 1
                if ($nestDepth -gt 2) { return $null }
                [void]$nestKind.Add('PROCSUB'); [void]$nestBuf.Add($buf.ToString()); [void]$nestSt.Add($stIn)
                $nestTop = 'PROCSUB'
                [void]$buf.Clear(); $stIn = 'N'; $i += 2; continue
            }

            # ---- rows 12-23: NORMAL-only redirections, separators and frames ----
            if ($stIn -eq 'N') {
                # ---- row 12: plain redirection operator ----
                # Recording WHERE it was appended is what lets row 15 tell an
                # OPERATOR '>' from a literal one. Reading the raw character at
                # i-1 instead (design 3.1 row 15) is a false negative: in
                # `echo a\>& rm -rf /etc/x` bash treats the escaped '>' as text,
                # so the '&' IS a separator, but the raw character says
                # "redirect" and the position is never flushed. Because the
                # "none yet" sentinel (-2) is OUTSIDE the domain of ($i - 1), a
                # stale or never-set index can only ever compare unequal, i.e.
                # cause a flush, i.e. MORE positions — fail-closed. That
                # property is what makes a single scanner-wide index sound
                # without per-frame save/restore, and it holds only while the
                # sentinel stays unreachable (see its declaration).
                if ($ch -eq '>' -or $ch -eq '<') {
                    [void]$buf.Append($ch); $redirIdx = $i; $i += 1; continue
                }
                if ($two -eq '&&') {
                    Add-ScannerPosition $posList $buf; $i += 2; continue
                }
                if ($two -eq '&>') {
                    [void]$buf.Append('&>'); $i += 2; continue
                }
                if ($ch -eq '&') {
                    if ($redirIdx -eq ($i - 1)) { [void]$buf.Append('&') }
                    else { Add-ScannerPosition $posList $buf }
                    $i += 1; continue
                }
                if ($ch -eq '|') { Add-ScannerPosition $posList $buf; $i += 1; continue }
                if ($ch -eq ';') { Add-ScannerPosition $posList $buf; $i += 1; continue }
                if ($ch -eq '(') {
                    Add-ScannerPosition $posList $buf
                    $nestDepth += 1
                    if ($nestDepth -gt 2) { return $null }
                    [void]$nestKind.Add('GROUP_PAREN'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                    $nestTop = 'GROUP_PAREN'
                    $i += 1; continue
                }
                if ($ch -eq ')') {
                    if ($nestTop -eq 'CMDSUB' -or $nestTop -eq 'PROCSUB') {
                        Add-ScannerPosition $posList $buf
                        $n = $nestKind.Count - 1
                        $savedBuf = $nestBuf[$n]
                        $savedSt = $nestSt[$n]
                        Pop-NestFrame $nestKind $nestBuf $nestSt
                        $nestTop = Get-NestTop $nestKind
                        $nestDepth -= 1
                        [void]$buf.Clear(); [void]$buf.Append($savedBuf); $stIn = $savedSt
                    } elseif ($nestTop -eq 'GROUP_PAREN') {
                        Add-ScannerPosition $posList $buf
                        Pop-NestFrame $nestKind $nestBuf $nestSt
                        $nestTop = Get-NestTop $nestKind
                        $nestDepth -= 1
                    } else {
                        # `case` arm terminator and friends: flush, no pop.
                        Add-ScannerPosition $posList $buf
                    }
                    $i += 1; continue
                }
                if ($ch -eq '{') {
                    if ($buf.ToString().Trim() -eq '') {
                        Add-ScannerPosition $posList $buf
                        $nestDepth += 1
                        if ($nestDepth -gt 2) { return $null }
                        [void]$nestKind.Add('GROUP_BRACE'); [void]$nestBuf.Add(''); [void]$nestSt.Add('')
                        $nestTop = 'GROUP_BRACE'
                    } else {
                        [void]$buf.Append('{')
                    }
                    $i += 1; continue
                }
                if ($ch -eq '}') {
                    if ($nestTop -eq 'GROUP_BRACE') {
                        Add-ScannerPosition $posList $buf
                        Pop-NestFrame $nestKind $nestBuf $nestSt
                        $nestTop = Get-NestTop $nestKind
                        $nestDepth -= 1
                    } else {
                        [void]$buf.Append('}')
                    }
                    $i += 1; continue
                }
                if ($ch -eq $lf -or $ch -eq $cr) {
                    Add-ScannerPosition $posList $buf
                    if ($hdHead -lt $hdQueue.Count) { $stIn = 'H'; [void]$hdLine.Clear() }
                    $i += 1; continue
                }
                if ($ch -eq '#') {
                    $bufStr = $buf.ToString()
                    if ($bufStr -eq '' -or $bufStr.EndsWith(' ') -or $bufStr.EndsWith($tabStr)) {
                        $stIn = 'C'
                    } else {
                        [void]$buf.Append('#')
                    }
                    $i += 1; continue
                }
            }

            # ---- catch-all for a special byte that no row above claimed ----
            [void]$buf.Append($ch); $i += 1
        }

        # ---- end of input (total) ----
        if ($stIn -eq 'SQ' -or $stIn -eq 'DQ') { return $null }
        if ($stIn -eq 'H') {
            # A terminator on the final line with no trailing newline still ends
            # the body (bash accepts it); anything else is genuinely unterminated.
            $cmpLine = $hdLine.ToString()
            if ($hdStrip[$hdHead]) { $cmpLine = $cmpLine.TrimStart([char[]]@([char]9)) }
            if ($cmpLine -ceq $hdQueue[$hdHead]) { $hdHead += 1 }
        }
        if ($hdHead -lt $hdQueue.Count) { return $null }
        if ($nestKind.Count -gt 0) { return $null }
        Add-ScannerPosition $posList $buf
        return ,$posList.ToArray()
    } catch {
        # An escaping terminating error would exit 1, which Claude Code treats
        # as NON-blocking — i.e. the guard would silently disarm. Map every
        # exception onto the parse-failure path instead (exit 2).
        return $null
    }
}

# 7. Path normalize (leaf-only; no realpath / symlink chase).
function Resolve-AbsoluteLeaf([string]$p, [string]$cwd) {
    $abs = $p
    # Strip surrounding quotes if any left over (defense-in-depth).
    if ($abs.StartsWith('"') -and $abs.EndsWith('"')) { $abs = $abs.Substring(1, $abs.Length - 2) }
    if ($abs.StartsWith("'") -and $abs.EndsWith("'")) { $abs = $abs.Substring(1, $abs.Length - 2) }
    # Expand ~ (home dir). Note: $home is a built-in pwsh auto-variable; use a different name.
    if ($abs -eq '~' -or $abs.StartsWith('~/') -or $abs.StartsWith('~\')) {
        $homePath = if ($env:HOME) { $env:HOME } else { $env:USERPROFILE }
        if ($abs -eq '~') { $abs = $homePath } else { $abs = Join-Path $homePath $abs.Substring(2) }
    }
    $isAbs = $false
    if ($abs.Length -ge 1 -and ($abs[0] -eq '/' -or $abs[0] -eq '\')) { $isAbs = $true }
    if ($abs.Length -ge 2 -and $abs[1] -eq ':') { $isAbs = $true }  # Windows drive
    if (-not $isAbs) { $abs = Join-Path $cwd $abs }
    # Normalize: collapse .. and . segments without touching the filesystem.
    $sep = [IO.Path]::DirectorySeparatorChar
    $sepStr = "$sep"
    $normalized = $abs -replace '/', $sepStr
    $parts = $normalized.Split($sep)
    $stack = [System.Collections.Generic.List[string]]::new()
    for ($si = 0; $si -lt $parts.Length; $si++) {
        $part = $parts[$si]
        if ($part -eq '' -or $part -eq '.') {
            if ($stack.Count -eq 0 -and $part -eq '') { $stack.Add('') }
            continue
        }
        if ($part -eq '..') {
            if ($stack.Count -gt 1) { $stack.RemoveAt($stack.Count - 1) }
            continue
        }
        $stack.Add($part)
    }
    $arr = $stack.ToArray()
    $result = [string]::Join($sepStr, $arr)
    if ($result -eq '') { $result = $sepStr }
    return $result
}

function Test-IsDescendant([string]$child, [string]$parent) {
    $c = $child.TrimEnd('\','/')
    $p = $parent.TrimEnd('\','/')
    if ([string]::Equals($c, $p, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    $sep = [IO.Path]::DirectorySeparatorChar
    return $c.StartsWith($p + $sep, [StringComparison]::OrdinalIgnoreCase) -or `
           $c.StartsWith($p + '/', [StringComparison]::OrdinalIgnoreCase) -or `
           $c.StartsWith($p + '\', [StringComparison]::OrdinalIgnoreCase)
}

# 8a. Prefix strip — assignment prefixes, `sudo` (with its -E / -H / -u USER
# logic, byte-for-byte the pre-change block) and shell reserved words.
$reservedWords = @(
    'if', 'then', 'elif', 'else', 'fi', 'while', 'until', 'do', 'done',
    'for', 'select', 'case', 'esac', 'in', 'function', 'coproc', '!', '{', '}'
)

function Get-PrefixIndex($tokens) {
    $idx = 0
    while ($idx -lt $tokens.Count) {
        $t = $tokens[$idx]
        # 1. Assignment prefix: NAME=value or NAME+=value.
        if ($t -cmatch '^[A-Za-z_][A-Za-z0-9_]*\+?=') {
            $idx++
            continue
        }
        # 2. sudo [-E|-H|-u USER]
        if ($t -ceq 'sudo') {
            $idx++
            while ($idx -lt $tokens.Count) {
                $t = $tokens[$idx]
                if ($t -ceq '-E' -or $t -ceq '-H') { $idx++; continue }
                if ($t -ceq '-u' -and $idx + 1 -lt $tokens.Count) { $idx += 2; continue }
                break
            }
            continue
        }
        # 3. Shell reserved words and stray group braces. Safe by construction:
        # the destructive-verb test still gates every path walk.
        $isReserved = $false
        foreach ($rw in $reservedWords) { if ($t -ceq $rw) { $isReserved = $true; break } }
        if ($isReserved) { $idx++; continue }
        break
    }
    return $idx
}

# 8b. The pre-change path walk, behaviourally unchanged: skip flags, honour
# `--`, resolve every remaining token as a path.
function Get-OffendingFromWalk($tokens, [int]$start) {
    $offending = @()
    $afterDoubleDash = $false
    for ($j = $start; $j -lt $tokens.Count; $j++) {
        $t = $tokens[$j]
        if (-not $afterDoubleDash) {
            if ($t -eq '--') { $afterDoubleDash = $true; continue }
            if ($t.StartsWith('-') -and $t.Length -gt 1) {
                # NOTE: find-predicate skip intentionally disabled here.
                # `find` is handled in its own branch; no other destructive verb
                # takes `-name`/`-path`/etc., so any such flag on
                # `rm`/`Remove-Item` is either user error or adversarial — block
                # by treating subsequent tokens as paths.
                # See 06_TEST_REPORT.md D-1 / D-2.
                continue
            }
        }
        $abs = Resolve-AbsoluteLeaf -p $t -cwd (Get-Location).Path
        if (-not (Test-IsDescendant -child $abs -parent $repoRoot)) {
            $offending += $abs
        }
    }
    return $offending
}

# 8c. Classify a single segment and collect offending paths.
function Get-OffendingFromSegment {
    param([string]$segment, [int]$depth)
    $offending = @()
    if ($depth -gt 2) {
        return ,@('__PARSE_FAIL__')
    }
    $tokens = Get-Tokens $segment
    if ($null -eq $tokens) {
        return ,@('__PARSE_FAIL__')
    }
    if ($tokens.Count -eq 0) { return $offending }

    $idx = Get-PrefixIndex $tokens
    if ($idx -ge $tokens.Count) { return $offending }
    $verb = $tokens[$idx]
    $afterVerb = $idx + 1

    # Nested pwsh / powershell.
    if (Test-PwshVerb $verb) {
        for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
            $t = $tokens[$j]
            if ($t -ieq '-c' -or $t -ieq '-Command' -or $t -ieq '-CommandWithArgs' -or $t -eq '/c') {
                if ($j + 1 -ge $tokens.Count) { return ,@('__PARSE_FAIL__') }
                $nested = $tokens[$j + 1]
                $sub = Get-OffendingFromCommandString -s $nested -depth ($depth + 1)
                foreach ($x in $sub) { $offending += $x }
                return $offending
            }
        }
        return $offending  # pwsh without -c is harmless
    }

    # Nested POSIX-shell interpreters. Deliberately broader than "find -c":
    # every non-option token is judged as a command string, so
    # `bash --rcfile foo -c "rm -rf /etc/x"` is covered and `bash script.sh`
    # degrades to judging the literal string `script.sh` (not destructive).
    if (Test-ShellVerb $verb) {
        for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
            $t = $tokens[$j]
            if (-not $t.StartsWith('-')) {
                $sub = Get-OffendingFromCommandString -s $t -depth ($depth + 1)
                foreach ($x in $sub) { $offending += $x }
            }
        }
        return $offending
    }

    # Argv carriers (IS-1 row 9). The scan runs to the end and NEVER returns —
    # `find` is a carrier AND has its own -delete branch below, and both must
    # run, in this order. No per-carrier option table: an incomplete table
    # produces false negatives, which is the forbidden direction.
    if (Test-CarrierVerb $verb) {
        for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
            $t = $tokens[$j]
            if (Test-DestructiveVerb $t) {
                $sub = Get-OffendingFromWalk $tokens ($j + 1)
                foreach ($x in $sub) { $offending += $x }
            } elseif ((Test-PwshVerb $t) -or (Test-ShellVerb $t)) {
                for ($k = $j + 1; $k -lt $tokens.Count; $k++) {
                    if (-not $tokens[$k].StartsWith('-')) {
                        $sub = Get-OffendingFromCommandString -s $tokens[$k] -depth ($depth + 1)
                        foreach ($x in $sub) { $offending += $x }
                        break
                    }
                }
            }
        }
        # NO return here — fall through to the find branch.
    }

    # find with -delete is destructive; otherwise non-destructive.
    if ($verb -ceq 'find') {
        $hasDelete = $false
        foreach ($t in $tokens) { if ($t -eq '-delete') { $hasDelete = $true; break } }
        if (-not $hasDelete) { return $offending }
        # Path args are positional before the first predicate flag.
        for ($j = $afterVerb; $j -lt $tokens.Count; $j++) {
            $t = $tokens[$j]
            if ($t.StartsWith('-')) { break }  # first predicate stops path-arg list
            $abs = Resolve-AbsoluteLeaf -p $t -cwd (Get-Location).Path
            if (-not (Test-IsDescendant -child $abs -parent $repoRoot)) {
                $offending += $abs
            }
        }
        return $offending
    }

    # Other destructive verbs.
    if (-not (Test-DestructiveVerb $verb)) { return $offending }

    $sub = Get-OffendingFromWalk $tokens $afterVerb
    foreach ($x in $sub) { $offending += $x }
    return $offending
}

# 8d. The union step and the single entry point for "judge this command string".
# INVARIANT: the position list contains the input string ITSELF at EVERY depth,
# including depth 0. Do NOT make this depth-conditional — decomposition strictly
# narrows each verb's token walk, so dropping the whole string would flip
# pre-change BLOCKs to ALLOW (a silent, fail-OPEN regression).
function Get-OffendingFromCommandString {
    param([string]$s, [int]$depth)
    $offending = @()
    if ($depth -gt 2) {
        return ,@('__PARSE_FAIL__')
    }

    $plist = [System.Collections.Generic.List[string]]::new()
    [void]$plist.Add($s)

    foreach ($seg in (Split-Pipes $s)) {
        if (-not $plist.Contains($seg)) { [void]$plist.Add($seg) }
    }

    if (Test-ScannerTrigger $s) {
        $positions = Split-CommandPositions $s
        # The scanner's $null is converted to the ONE existing external failure
        # channel here; no new mechanism is invented.
        if ($null -eq $positions) { return ,@('__PARSE_FAIL__') }
        foreach ($p in $positions) {
            if (-not $plist.Contains($p)) { [void]$plist.Add($p) }
        }
    }

    foreach ($seg in $plist) {
        if (-not $seg) { continue }
        $sub = Get-OffendingFromSegment -segment $seg -depth $depth
        foreach ($x in $sub) { $offending += $x }
    }
    return $offending
}

# 9. Judge every command position in the command line.
$allOffending = @()
$parseFailed = $false
$found = Get-OffendingFromCommandString -s $cmd -depth 0
foreach ($x in $found) {
    if ($x -eq '__PARSE_FAIL__') { $parseFailed = $true; continue }
    $allOffending += $x
}

if ($parseFailed) {
    [Console]::Error.WriteLine('harness-kit guard-rm: BLOCKED — could not parse the command safely (unbalanced quotes, nesting past depth 2, or an unterminated here-document); override with HARNESS_ALLOW_OUTSIDE_RM=1 if intended.')
    exit 2
}

if ($allOffending.Count -eq 0) { exit 0 }

# 10. Emit BLOCK message.
$truncCmd = if ($cmd.Length -gt 300) { $cmd.Substring(0, 300) } else { $cmd }
[Console]::Error.WriteLine('harness-kit guard-rm: BLOCKED — destructive command targets path outside project root.')
[Console]::Error.WriteLine("  Command: $truncCmd")
[Console]::Error.WriteLine('  Offending path(s):')
foreach ($p in $allOffending) {
    [Console]::Error.WriteLine("    - $p (outside $repoRoot)")
}
[Console]::Error.WriteLine('  Override (only if you really mean this): re-issue the command with the env var')
[Console]::Error.WriteLine('    HARNESS_ALLOW_OUTSIDE_RM=1 set for that single call.')
[Console]::Error.WriteLine('  See .harness/rules/75-safety-hook.md to fully disable.')
exit 2
