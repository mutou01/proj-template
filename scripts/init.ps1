<#
.SYNOPSIS
  init.ps1 - create a project from this template.

.DESCRIPTION
  Windows counterpart of scripts/init.sh. Same arguments, same result: it
  copies template/ into the target directory and fills in the project's name,
  description and stack. For a known stack it also writes the stack block into
  the Makefile, the code standards and the CI workflow.

  The verification commands it writes are a contract, not a working build: they
  are what a real project must be able to run. A fresh project has no code, so
  the gate is expected to fail until there is something to check.

  Arguments are parsed by hand rather than through PowerShell's parameter
  binder, so that `--name foo` means the same thing here as it does in
  init.sh. A script pair whose two halves take different arguments is a trap
  for whoever runs the wrong one.

.EXAMPLE
  ./scripts/init.ps1 ..\my-service --name my-service --desc "Does the thing" --lang go --git
#>

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Files are read and written whole, and written back as UTF-8 without a BOM and
# with LF endings. `Set-Content -Encoding UTF8` would add a BOM on Windows
# PowerShell, and `WriteAllLines` would rewrite every line ending as CRLF -
# which .gitattributes then fights over, in a way that looks like a broken test.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Die([string]$Message) {
    [Console]::Error.WriteLine("init: $Message")
    exit 1
}

function Show-Usage {
    @'
Usage: scripts/init.ps1 <target-dir> [options]

  --name <name>       Project name, as it should read in the docs. Defaults to
                      the target directory's name.
  --desc "<text>"     One line describing the project. Optional.
  --lang <stack>      go | python | ts | other. Defaults to other.
  --no-conventions    Do not write the stack's language conventions into
                      docs/code-standards.md. The gate is still written.
  --git               Run `git init -b main` in the new project. Nothing is
                      staged or committed.
  --force             Write into a target directory that is not empty.
  -h, --help          This text.

Examples:
  ./scripts/init.ps1 ..\my-service --name my-service --desc "Does the thing" --lang go --git
  ./scripts/init.ps1 .\scratch --name scratch --lang python --no-conventions
'@
}

# --- arguments ---------------------------------------------------------------
$Target = $null
$Name = $null
$Desc = ''
$Lang = 'other'
$Conventions = $true
$DoGit = $false
$Force = $false

$i = 0
while ($i -lt $args.Count) {
    $a = $args[$i]
    switch -Exact ($a) {
        '--name' {
            $i++
            if ($i -ge $args.Count) { Die '--name needs a value' }
            $Name = $args[$i]
        }
        '--desc' {
            $i++
            if ($i -ge $args.Count) { Die '--desc needs a value' }
            $Desc = $args[$i]
        }
        '--lang' {
            $i++
            if ($i -ge $args.Count) { Die '--lang needs a value' }
            $Lang = $args[$i]
        }
        '--no-conventions' { $Conventions = $false }
        '--git' { $DoGit = $true }
        '--force' { $Force = $true }
        '-h' { Show-Usage; exit 0 }
        '--help' { Show-Usage; exit 0 }
        default {
            if ($a -like '-*') { Die "unknown option: $a (try --help)" }
            if ($Target) { Die "more than one target directory given: '$Target' and '$a'" }
            $Target = $a
        }
    }
    $i++
}

if ($Lang -notin @('go', 'python', 'ts', 'other')) {
    Die "--lang must be go, python, ts or other (got '$Lang')"
}

if (-not $Target) {
    Show-Usage | Write-Error
    Die 'no target directory given'
}

# --- locate the template -----------------------------------------------------
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $Here
$Template = Join-Path $Root 'template'
$Stacks = Join-Path $Here 'stacks'

if (-not (Test-Path -LiteralPath $Template -PathType Container)) {
    Die "no template directory at $Template"
}
$StackDir = Join-Path $Stacks $Lang
if (-not (Test-Path -LiteralPath $StackDir -PathType Container)) {
    Die "no stack definition at $StackDir"
}

$ConventionsSrc = if ($Conventions) {
    Join-Path $StackDir 'conventions.md'
}
else {
    Join-Path $Here 'no-conventions.md'
}
if (-not (Test-Path -LiteralPath $ConventionsSrc)) {
    Die "no conventions file at $ConventionsSrc"
}

# --- target directory --------------------------------------------------------
$Target = (New-Item -ItemType Directory -Path $Target -Force).FullName

# Refuse a directory that already has something in it. Copying a template over
# someone's work is not something this script can undo, and a half-overwritten
# tree is worse than a refusal.
$existing = Get-ChildItem -LiteralPath $Target -Force -ErrorAction SilentlyContinue
if (-not $Force -and $existing) {
    Die "$Target is not empty (pass --force to write into it anyway)"
}

# --- the values that get substituted -----------------------------------------
if (-not $Name) {
    $Name = Split-Path -Leaf $Target
}

$Slug = ($Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
if (-not $Slug) { $Slug = 'project' }

$LangLabel = switch -Exact ($Lang) {
    'go' { 'Go' }
    'python' { 'Python' }
    'ts' { 'TypeScript / Node' }
    default { 'Other' }
}

# The separator travels with the description, so an omitted --desc leaves no
# dangling dash. The em dash is built from its code point rather than typed:
# Windows PowerShell 5.1 reads a BOM-less UTF-8 script as ANSI and would mangle
# a literal one.
$EmDash = [char]0x2014
$DescSuffix = if ($Desc) { " $EmDash $Desc" } else { '' }

$Guard = ([System.IO.File]::ReadAllText((Join-Path $StackDir 'guard'))).Trim()
if (-not $Guard) { Die "$StackDir\guard is empty" }

# --- copy --------------------------------------------------------------------
Get-ChildItem -LiteralPath $Template -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $Target -Recurse -Force
}

# --- substitute the placeholders ---------------------------------------------
# Only the files the template ships, found by walking the template rather than
# the target. With --force the target may already hold a user's own files, and
# rewriting those is not this script's business.
#
# `.Replace` is a literal string replacement, not a regular expression, so a
# project name containing `$` or `&` cannot corrupt the file it lands in.
$replacements = [ordered]@{
    '{{PROJECT_NAME}}'              = $Name
    '{{PROJECT_SLUG}}'              = $Slug
    '{{PROJECT_DESCRIPTION_SUFFIX}}' = $DescSuffix
    '{{LANG}}'                      = $LangLabel
    '{{GUARD_FILE}}'                = $Guard
}

$templateFiles = Get-ChildItem -LiteralPath $Template -Recurse -File -Force
foreach ($src in $templateFiles) {
    $rel = $src.FullName.Substring($Template.Length).TrimStart('\', '/')
    $dest = Join-Path $Target $rel
    if (-not (Test-Path -LiteralPath $dest -PathType Leaf)) { continue }

    $text = [System.IO.File]::ReadAllText($dest)
    $changed = $false
    foreach ($key in $replacements.Keys) {
        if ($text.Contains($key)) {
            $text = $text.Replace($key, $replacements[$key])
            $changed = $true
        }
    }
    if ($changed) {
        [System.IO.File]::WriteAllText($dest, $text, $Utf8NoBom)
    }
}

# --- splice in the stack's blocks --------------------------------------------
# Replaces the lines strictly between two marker lines with the contents of a
# file, so the generated text lands where the template left room for it.
#
# Both markers must be present. Without this check, a missing end marker would
# silently delete everything after the begin marker - and `--force` exists, so
# that could happen to a project someone has already edited.
function Splice([string]$Path, [string]$Begin, [string]$End, [string]$Source) {
    $lines = [System.IO.File]::ReadAllLines($Path)
    if (-not ($lines -ccontains $Begin)) { Die "$Path has no '$Begin' marker" }
    if (-not ($lines -ccontains $End)) { Die "$Path has no '$End' marker" }

    $src = [System.IO.File]::ReadAllLines($Source)
    $out = New-Object System.Collections.Generic.List[string]
    $skipping = $false
    foreach ($line in $lines) {
        if ($line -ceq $Begin) {
            $out.Add($line)
            foreach ($s in $src) { $out.Add($s) }
            $skipping = $true
            continue
        }
        if ($line -ceq $End) { $skipping = $false }
        if (-not $skipping) { $out.Add($line) }
    }
    # Join with LF, not Environment.NewLine: the whole tree is LF by policy,
    # and .gitattributes enforces it.
    [System.IO.File]::WriteAllText($Path, ($out -join "`n") + "`n", $Utf8NoBom)
}

Splice (Join-Path $Target 'Makefile') `
    '# === STACK ===' '# === END STACK ===' (Join-Path $StackDir 'makefile-block.mk')
Splice (Join-Path $Target 'docs/code-standards.md') `
    '<!-- stack:begin -->' '<!-- stack:end -->' $ConventionsSrc
Splice (Join-Path $Target '.github/workflows/verify.yml') `
    '      # === toolchain ===' '      # === end toolchain ===' (Join-Path $StackDir 'workflow-setup.yml')

# --- git ---------------------------------------------------------------------
# `-b main` because the generated workflow triggers on `main`; a default
# `master` would leave the project's first push without a CI run.
if ($DoGit) {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git -C $Target init --quiet -b main
    }
    else {
        [Console]::Error.WriteLine('init: git is not on PATH; skipping git init')
    }
}

# --- what to do next ---------------------------------------------------------
Write-Host ""
Write-Host "  $Name is ready at $Target"
Write-Host ""
Write-Host "  Next:"
Write-Host "    1. cd `"$Target`""
Write-Host "    2. read AGENTS.md - it is the one file that says how work happens here"
Write-Host "    3. fill in the `"This project`" section at the foot of AGENTS.md"
Write-Host "    4. make setup && make verify"
Write-Host ""
Write-Host "  Step 4 is the contract the project has to meet. It fails on a project with"
Write-Host "  no code yet, and that is expected: there is nothing to verify."
Write-Host ""

if ($Lang -eq 'other') {
    Write-Host "  Note: no stack block was written, because --lang other was used. Every gate"
    Write-Host "  in the Makefile fails on purpose until you fill the STACK block in. That is"
    Write-Host "  deliberate: a check that does not run must not look like one that passed."
    Write-Host ""
}
