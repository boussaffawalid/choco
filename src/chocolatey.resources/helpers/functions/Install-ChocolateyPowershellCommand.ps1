﻿# Copyright 2011 - Present RealDimensions Software, LLC & original authors/contributors from https://github.com/chocolatey/chocolatey
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Install-ChocolateyPowershellCommand {
<#
.SYNOPSIS
Installs a PowerShell Script as a command

.DESCRIPTION
This will install a PowerShell script as a command on your system. Like
an executable can be run from a batch redirect, this will do the same,
calling PowerShell with this command and passing your arguments to it.
If you include a url, it will first download the PowerShell file.

.NOTES
Chocolatey works best when the packages contain the software it is
managing and doesn't require downloads. However most software in the
Windows world requires redistribution rights and when sharing packages
publicly (like on the community feed), maintainers may not have those
aforementioned rights. Chocolatey understands how to work with that,
hence this function. You are not subject to this limitation with
internal packages.

.INPUTS
None

.OUTPUTS
None

.PARAMETER PackageName
The name of the package - while this is an arbitrary value, it's
recommended that it matches the package id.

.PARAMETER PsFileFullPath
Full file path to PowerShell file to turn into a command. If embedding
it in the package next to the install script, the path will be like
`"$(Split-Path -parent $MyInvocation.MyCommand.Definition)\\Script.ps1"`

.PARAMETER Url
This is the 32 bit url to download the resource from. This resource can
be used on 64 bit systems when a package has both a Url and Url64bit
specified if a user passes `--forceX86`. If there is only a 64 bit url
available, please remove do not use the paramter (only use Url64bit).
Will fail on 32bit systems if missing or if a user attempts to force
a 32 bit installation on a 64 bit system.

Prefer HTTPS when available. Can be HTTP, FTP, or File URIs.

.PARAMETER Url64bit
OPTIONAL - If there is a 64 bit resource available, use this
parameter. Chocolatey will automatically determine if the user is
running a 64 bit OS or not and adjust accordingly. Please note that
the 32 bit url will be used in the absence of this. This parameter
should only be used for 64 bit native software. If the original Url
contains both (which is quite rare), set this to '$url' Otherwise remove
this parameter.

Prefer HTTPS when available. Can be HTTP, FTP, or File URIs.

.PARAMETER Checksum
OPTIONAL (Highly recommended) - The checksum hash value of the Url
resource. This allows a checksum to be validated for files that are not
local. The checksum type is covered by ChecksumType.

.PARAMETER ChecksumType
OPTIONAL - The type of checkum that the file is validated with - valid
values are 'md5', 'sha1', 'sha256' or 'sha512' - defaults to 'md5'.

MD5 is not recommended as certain organizations need to use FIPS
compliant algorithms for hashing - see
https://support.microsoft.com/en-us/kb/811833 for more details.

.PARAMETER Checksum64
OPTIONAL (Highly recommended) - The checksum hash value of the Url64bit
resource. This allows a checksum to be validated for files that are not
local. The checksum type is covered by ChecksumType64.

.PARAMETER ChecksumType64
OPTIONAL - The type of checkum that the file is validated with - valid
values are 'md5', 'sha1', 'sha256' or 'sha512' - defaults to
ChecksumType parameter value.

MD5 is not recommended as certain organizations need to use FIPS
compliant algorithms for hashing - see
https://support.microsoft.com/en-us/kb/811833 for more details.

.PARAMETER Options
OPTIONAL - Specify custom headers. Available in 0.9.10+.

.PARAMETER IgnoredArguments
Allows splatting with arguments that do not apply. Do not use directly.

.EXAMPLE
>
$psFile = Join-Path $(Split-Path -Parent $MyInvocation.MyCommand.Definition) "Install-WindowsImage.ps1"
Install-ChocolateyPowershellCommand -PackageName 'installwindowsimage.powershell' -PSFileFullPath $psFile

.EXAMPLE
>
$psFile = Join-Path $(Split-Path -Parent $MyInvocation.MyCommand.Definition) `
 "Install-WindowsImage.ps1"
Install-ChocolateyPowershellCommand `
 -PackageName 'installwindowsimage.powershell' `
 -PSFileFullPath $psFile `
 -PSFileFullPath $psFile `
 -Url 'http://somewhere.com/downloads/Install-WindowsImage.ps1'

.EXAMPLE
>
$psFile = Join-Path $(Split-Path -Parent $MyInvocation.MyCommand.Definition) `
 "Install-WindowsImage.ps1"
Install-ChocolateyPowershellCommand `
 -PackageName 'installwindowsimage.powershell' `
 -PSFileFullPath $psFile `
 -Url 'http://somewhere.com/downloads/Install-WindowsImage.ps1' `
 -Url64 'http://somewhere.com/downloads/Install-WindowsImagex64.ps1'

.LINK
Get-ChocolateyWebFile

.LINK
Install-ChocolateyInstallPackage

.LINK
Install-ChocolateyPackage

.LINK
Install-ChocolateyZipPackage
#>
param(
  [parameter(Mandatory=$false, Position=0)][string] $packageName,
  [parameter(Mandatory=$true, Position=1)][string] $psFileFullPath,
  [parameter(Mandatory=$false, Position=2)][string] $url ='',
  [parameter(Mandatory=$false, Position=3)]
  [alias("url64")][string] $url64bit = '',
  [parameter(Mandatory=$false)][string] $checksum = '',
  [parameter(Mandatory=$false)][string] $checksumType = '',
  [parameter(Mandatory=$false)][string] $checksum64 = '',
  [parameter(Mandatory=$false)][string] $checksumType64 = '',
  [parameter(Mandatory=$false)][hashtable] $options = @{Headers=@{}},
  [parameter(ValueFromRemainingArguments = $true)][Object[]] $ignoredArguments
)
  Write-Debug "Running 'Install-ChocolateyPowershellCommand' for $packageName with psFileFullPath:`'$psFileFullPath`', url: `'$url`', url64bit:`'$url64bit`', checkSum: `'$checksum`', checksumType: `'$checksumType`', checkSum64: `'$checksum64`', checksumType64: `'$checksumType64`' ";

  if ($url -ne '') {
    Get-ChocolateyWebFile $packageName $psFileFullPath $url $url64bit -checksum $checksum -checksumType $checksumType -checksum64 $checksum64 -checksumType64 $checksumType64 -Options $options
  }

  if ($env:chocolateyPackageName -ne $null -and $env:chocolateyPackageName -eq $env:ChocolateyInstallDirectoryPackage) {
    Write-Warning "Install Directory override not available for PowerShell command packages."
  }

  $nugetPath = $(Split-Path -parent $helpersPath)
  $nugetExePath = Join-Path $nuGetPath 'bin'

  $cmdName = [System.IO.Path]::GetFileNameWithoutExtension($psFileFullPath)
  $packageBatchFileName = Join-Path $nugetExePath "$($cmdName).bat"

  Write-Host "Adding $packageBatchFileName and pointing it to powershell command $psFileFullPath"
"@echo off
powershell -NoProfile -ExecutionPolicy unrestricted -Command ""& `'$psFileFullPath`'  %*"""| Out-File $packageBatchFileName -encoding ASCII

}
