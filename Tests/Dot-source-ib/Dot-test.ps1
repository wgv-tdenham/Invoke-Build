
<#
.Synopsis
	Tests dot-sourcing of Invoke-Build.

.Description
	This script imports Invoke-Build runtime environment and tests it. It is
	supposed to be invoked by PowerShell.exe, i.e. not from a build script.
#>

Set-StrictMode -Version Latest

# to be changed/tested
Set-Location -LiteralPath $HOME

# dot-source tools, test not changed error preference
$ErrorActionPreference = 'Continue'
. Invoke-Build
if ($ErrorActionPreference -ne 'Continue') {throw}

# set error preference to stop
$ErrorActionPreference = 'Stop'

### Test assert first of all

# `assert` works and gets the proper position
($e = try {assert 0} catch {$_ | Out-String})
assert ($e -like '*Assertion failed.*try {assert*')

### Test special aliases and targets

# aliases for using

($r = (Get-Alias assert).Definition)
equals $r 'Assert-Build'

($r = (Get-Alias exec).Definition)
equals $r 'Invoke-BuildExec'

($r = (Get-Alias property).Definition)
equals $r 'Get-BuildProperty'

($r = (Get-Alias use).Definition)
equals $r 'Use-BuildAlias'

# aliases for Get-Help

($r = (Get-Alias error).Definition)
equals $r 'Get-BuildError'

($r = (Get-Alias task).Definition)
equals $r 'Add-BuildTask'

### Test special functions

Push-Location function:

# function should not exist
assert (!(Test-Path Write-Warning))

# expected public functions
$OK = 'Add-BuildTask,Assert-Build,Assert-BuildEquals,Get-BuildError,Get-BuildFile,Get-BuildProperty,Get-BuildSynopsis,Invoke-BuildExec,Test-BuildAsset,Use-BuildAlias,Write-Build'
$KO = (Get-ChildItem *-Build* -Name | Sort-Object) -join ','
assert ($OK -ceq $KO) "Unexpected functions:
OK: [$OK]
KO: [$KO]"

# expected internal functions
$OK = '*Amend,*At,*Check,*Die,*Err,*Fin,*Help,*IO,*Job,*Msg,*My,*Path,*Root,*Run,*SL,*Task,*Unsafe'
$KO = (Get-ChildItem [*]* -Name | Sort-Object) -join ','
assert ($OK -ceq $KO) "Unexpected functions:
OK: [$OK]
KO: [$KO]"

Pop-Location

### Test exposed commands

# assert is already tested

### exec

# exec 0
($r = exec { cmd /c echo Code0 })
equals $LASTEXITCODE 0
equals $r 'Code0'

# exec 42 works
($r = exec { cmd /c 'echo Code42&& exit 42' } (40..50))
equals $LASTEXITCODE 42
equals $r 'Code42'

# exec 13 fails
($e = try {exec { cmd /c exit 13 }} catch {$_ | Out-String})
equals $LASTEXITCODE 13
assert ($e -like 'exec : Command { cmd /c exit 13 } exited with code 13.*try {exec *')

### property

($r = property true)
equals $r $true

($r = property ComputerName)
equals $r $env:COMPUTERNAME

($r = property MissingVariable DefaultValue)
equals $r 'DefaultValue'

($e = try {property MissingVariable} catch {$_ | Out-String})
assert ($e -like 'property : Missing property *try {property *')

### use

#! Mind \\Framework(64)?\\ and do not log, avoid diff.

use 4.0 MSBuild
$r = (Get-Alias MSBuild).Definition
assert ($r -like '?:\*\Microsoft.NET\Framework*\v4.0.*\MSBuild')

use Framework\v4.0.30319 MSBuild
$r = (Get-Alias MSBuild).Definition
assert ($r -like '?:\*\Microsoft.NET\Framework*\v4.0.30319\MSBuild')

use (Split-Path $MyInvocation.MyCommand.Path) Dot-test.ps1
($r = (Get-Alias Dot-test.ps1).Definition)
equals $r $MyInvocation.MyCommand.Path

($e = try {use Missing MSBuild} catch {$_ | Out-String})
assert ($e -like 'use : Cannot resolve *try {use *')

### misc

# Write-Warning works as usual
Write-Warning 'Ignore this warning.'

# done, use Write-Build
Write-Build Green Succeeded
