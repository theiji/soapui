#Requires -Version 5.1
<#
.SYNOPSIS
    Compila, empacota e executa o SoapUI via Maven.

.DESCRIPTION
    Wrapper para os comandos Maven mais usados no modulo soapui.
    Requer JAVA_HOME definido no ambiente e mvn disponivel no PATH.

    No CMD, use por exemplo:
      scripts\run-soapui.ps1 help
      scripts\run-soapui.ps1 run
      scripts\run-soapui.ps1 -Action clean-package

.PARAMETER Action
    Acao a executar:

      package                  - mvn package -Dmaven.test.skip -pl soapui (padrao; nao compila nem roda testes)
      clean-package            - mvn clean package -Dmaven.test.skip -pl soapui
      package-skip-tests       - mvn package -DskipTests -pl soapui (compila testes, nao executa)
      clean-package-skip-tests - mvn clean package -DskipTests -pl soapui
      compile                  - mvn compile -pl soapui
      run                      - mvn exec:java -pl soapui
      build-run                - mvn clean compile exec:java -Dmaven.test.skip -pl soapui
      help                     - exibe a ajuda

.PARAMETER ShowHelp
    Exibe a ajuda resumida e encerra.

.EXAMPLE
    .\scripts\run-soapui.ps1
    Empacota o modulo (package incremental).

.EXAMPLE
    .\scripts\run-soapui.ps1 help
    Exibe a ajuda.

.EXAMPLE
    .\scripts\run-soapui.ps1 -Action clean-package
    Limpa e empacota o modulo.

.EXAMPLE
    .\scripts\run-soapui.ps1 run
    Executa o SoapUI (requer compilacao previa).

.EXAMPLE
    Get-Help .\scripts\run-soapui.ps1 -Full
    Ajuda detalhada do PowerShell.
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet('package', 'clean-package', 'package-skip-tests', 'clean-package-skip-tests', 'compile', 'run', 'build-run', 'help')]
    [string] $Action,

    [Alias('?')]
    [switch] $ShowHelp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:ValidActions = @('package', 'clean-package', 'package-skip-tests', 'clean-package-skip-tests', 'compile', 'run', 'build-run', 'help')

$Script:Actions = [ordered]@{
    'package'                  = @{
        Description = 'Empacota sem compilar nem executar testes (padrao)'
        Command     = @('-pl', 'soapui', 'package', '-Dmaven.test.skip')
    }
    'clean-package'            = @{
        Description = 'Limpa e empacota sem compilar nem executar testes'
        Command     = @('-pl', 'soapui', 'clean', 'package', '-Dmaven.test.skip')
    }
    'package-skip-tests'       = @{
        Description = 'Empacota compilando testes, mas sem executa-los'
        Command     = @('-pl', 'soapui', 'package', '-DskipTests')
    }
    'clean-package-skip-tests' = @{
        Description = 'Limpa e empacota compilando testes, mas sem executa-los'
        Command     = @('-pl', 'soapui', 'clean', 'package', '-DskipTests')
    }
    'compile'                  = @{
        Description = 'Compila o modulo soapui'
        Command     = @('-pl', 'soapui', 'compile')
    }
    'run'                      = @{
        Description = 'Executa o SoapUI (mvn exec:java)'
        Command     = @('-pl', 'soapui', 'exec:java')
    }
    'build-run'                = @{
        Description = 'Limpa, compila e executa o SoapUI'
        Command     = @('-pl', 'soapui', 'clean', 'compile', 'exec:java', '-Dmaven.test.skip')
    }
}

function Show-ScriptHelp {
    Write-Host ''
    Write-Host 'run-soapui.ps1 - Compila, empacota e executa o SoapUI' -ForegroundColor Green
    Write-Host ''
    Write-Host 'Uso:' -ForegroundColor Yellow
    Write-Host '  .\scripts\run-soapui.ps1 [acao]'
    Write-Host '  .\scripts\run-soapui.ps1 -Action <acao>'
    Write-Host '  .\scripts\run-soapui.ps1 -ShowHelp'
    Write-Host ''
    Write-Host 'Acoes disponiveis:' -ForegroundColor Yellow

    foreach ($name in $Script:Actions.Keys) {
        $cmd = 'mvn ' + ($Script:Actions[$name].Command -join ' ')
        Write-Host ("  {0,-26} {1}" -f $name, $Script:Actions[$name].Description)
        Write-Host ("  {0,-26} -> {1}" -f '', $cmd) -ForegroundColor DarkGray
    }

    Write-Host ''
    Write-Host '  help           Exibe esta ajuda'
    Write-Host ''
    Write-Host 'Exemplos:' -ForegroundColor Yellow
    Write-Host '  .\scripts\run-soapui.ps1'
    Write-Host '  .\scripts\run-soapui.ps1 help'
    Write-Host '  .\scripts\run-soapui.ps1 run'
    Write-Host '  .\scripts\run-soapui.ps1 -Action clean-package'
    Write-Host '  .\scripts\run-soapui.ps1 -Action package-skip-tests'
    Write-Host '  .\scripts\run-soapui.ps1 -Action build-run'
    Write-Host ''
    Write-Host 'Requisitos:' -ForegroundColor Yellow
    Write-Host '  JAVA_HOME  variavel de ambiente apontando para um JDK valido'
    Write-Host '  mvn        disponivel no PATH (Maven 3.6.3+)'
    Write-Host ''
    Write-Host 'Ajuda detalhada:' -ForegroundColor Yellow
    Write-Host '  Get-Help .\scripts\run-soapui.ps1 -Full'
    Write-Host ''
}

function Split-ArgumentString {
    param([string] $ArgumentString)

    if ([string]::IsNullOrWhiteSpace($ArgumentString)) {
        return @()
    }

    $tokens = [regex]::Matches($ArgumentString, '[^\s"]+|"[^"]*"') |
        ForEach-Object { $_.Value.Trim('"') }

    return @($tokens)
}

function Get-ExternalScriptArguments {
    $scriptPath = $PSCommandPath
    $scriptName = Split-Path $scriptPath -Leaf
    $collected = New-Object System.Collections.Generic.List[string]

    $cmdArgs = [Environment]::GetCommandLineArgs()
    $pastScript = $false

    foreach ($arg in $cmdArgs) {
        if ($pastScript) {
            $collected.Add($arg)
            continue
        }

        if ($arg -eq $scriptPath -or $arg -like "*$scriptName") {
            $pastScript = $true
        }
    }

    if ($collected.Count -gt 0) {
        return $collected.ToArray()
    }

    try {
        $parentId = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId
        $parentCmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$parentId").CommandLine
    } catch {
        return @()
    }

    if ([string]::IsNullOrWhiteSpace($parentCmd)) {
        return @()
    }

    foreach ($needle in @($scriptPath, $scriptName)) {
        $index = $parentCmd.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase)
        if ($index -lt 0) {
            continue
        }

        $tail = $parentCmd.Substring($index + $needle.Length).Trim()
        $tail = $tail.TrimStart('"', '''', ' ')
        $tail = $tail.TrimEnd('"', '''')

        if (-not [string]::IsNullOrWhiteSpace($tail)) {
            return Split-ArgumentString $tail
        }
    }

    return @()
}

function Resolve-ScriptAction {
    if ($ShowHelp) {
        return 'help'
    }

    if ($Action -in $Script:ValidActions) {
        return $Action
    }

    $externalArgs = @(Get-ExternalScriptArguments) + @($args)

    for ($i = 0; $i -lt $externalArgs.Count; $i++) {
        $token = $externalArgs[$i]

        if ($token -in @('-ShowHelp', '-?')) {
            return 'help'
        }

        if ($token -match '^-Action[:=](.+)$') {
            return $matches[1]
        }

        if ($token -in @('-Action', '/Action') -and ($i + 1) -lt $externalArgs.Count) {
            return $externalArgs[$i + 1]
        }

        $normalized = $token.TrimStart('-').ToLower()
        if ($normalized -in $Script:ValidActions) {
            return $normalized
        }
    }

    return 'package'
}

function Resolve-ProjectJavaHome {
    # SoapUI (maxJdkVersion=17). Prefer local JDK 17 for this process only — does not change the global JAVA_HOME.
    $preferred = 'C:\Program Files\Microsoft\jdk-17.0.21.102-hotspot'
    if (Test-Path (Join-Path $preferred 'bin\java.exe')) {
        return $preferred
    }

    $microsoftJdks = Get-ChildItem 'C:\Program Files\Microsoft' -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'jdk-17*' } |
        Sort-Object Name -Descending
    foreach ($dir in $microsoftJdks) {
        if (Test-Path (Join-Path $dir.FullName 'bin\java.exe')) {
            return $dir.FullName
        }
    }

    return $null
}

function Assert-JavaHome {
    $projectJdk = Resolve-ProjectJavaHome
    if ($projectJdk) {
        $env:JAVA_HOME = $projectJdk
        $javaBin = Join-Path $env:JAVA_HOME 'bin'
        $env:Path = "$javaBin;" + (($env:Path -split ';' | Where-Object { $_ -and ($_ -ne $javaBin) }) -join ';')
        Write-Host "Usando JDK do projeto (somente neste script): $env:JAVA_HOME" -ForegroundColor DarkGray
        return
    }

    if ([string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
        throw 'JDK 17 do projeto nao encontrado e JAVA_HOME nao esta definido. Instale com: winget install --id Microsoft.OpenJDK.17 -e --source winget --accept-package-agreements --accept-source-agreements  (ou defina JAVA_HOME).'
    }

    $javaExe = Join-Path $env:JAVA_HOME 'bin\java.exe'
    if (-not (Test-Path $javaExe)) {
        throw "JAVA_HOME aponta para um diretorio invalido: $env:JAVA_HOME"
    }
}

function Enable-NetskopeTrustStore {
    # Corporate SSL inspection (Netskope) breaks Maven HTTPS unless Java trusts the CA.
    $trustStore = Join-Path $env:USERPROFILE '.soapui-java-trust\cacerts'
    if (-not (Test-Path $trustStore)) {
        return
    }

    $flag = "-Djavax.net.ssl.trustStore=$trustStore -Djavax.net.ssl.trustStorePassword=changeit"
    if ([string]::IsNullOrWhiteSpace($env:JAVA_TOOL_OPTIONS)) {
        $env:JAVA_TOOL_OPTIONS = $flag
    }
    elseif ($env:JAVA_TOOL_OPTIONS -notlike '*javax.net.ssl.trustStore*') {
        $env:JAVA_TOOL_OPTIONS = ($env:JAVA_TOOL_OPTIONS.Trim() + ' ' + $flag)
    }

    Write-Host "Usando truststore Netskope: $trustStore" -ForegroundColor DarkGray
}

function Invoke-Maven {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    $mvn = Get-Command mvn -ErrorAction SilentlyContinue
    if (-not $mvn) {
        throw 'Maven (mvn) nao encontrado no PATH. Instale com: winget install --id Apache.Maven -e --source winget --accept-package-agreements --accept-source-agreements'
    }

    Write-Host ('mvn ' + ($Arguments -join ' ')) -ForegroundColor Cyan
    & mvn @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Maven falhou com codigo $LASTEXITCODE"
    }
}

$Action = Resolve-ScriptAction

if ($Action -eq 'help') {
    Show-ScriptHelp
    return
}

Assert-JavaHome
Enable-NetskopeTrustStore

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "JAVA_HOME=$env:JAVA_HOME" -ForegroundColor DarkGray
Write-Host "Acao: $Action" -ForegroundColor Green

Invoke-Maven -Arguments $Script:Actions[$Action].Command
