# Run Ghidra headless analysis via cmd.exe to avoid PowerShell/batch incompatibilities
$projDir = "C:\Users\jo\Downloads\ghidra_proj"

# Clean up and recreate project directory
if (Test-Path $projDir) {
    Remove-Item $projDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $projDir -Force | Out-Null
Write-Output "Project directory ready: $projDir"

# Build the cmd.exe command string
$cmdArgs = @(
    '/c',
    'set JAVA_HOME=C:\jdk-17',
    '&&',
    'set PATH=C:\jdk-17\bin;%PATH%',
    '&&',
    'set _JAVA_OPTIONS=-Xmx1200m -XX:MaxMetaspaceSize=384m',
    '&&',
    '"C:\ghidra\support\analyzeHeadless.bat"',
    '"C:\Users\jo\Downloads\ghidra_proj"',
    'KOK3Decomp',
    '-import',
    '"C:\gamigo\King of Kings 3\WEbug.exe"',
    '-postScript',
    '"C:\Users\jo\.gemini\antigravity\scratch\kok3-decomp\tools\ghidra_export.py"',
    '-deleteProject',
    '>',
    '"C:\Users\jo\Downloads\ghidra_analysis_full.log"',
    '2>&1'
)

Write-Output "Launching Ghidra headless via cmd.exe..."
$process = Start-Process -FilePath "cmd.exe" -ArgumentList $cmdArgs -Wait -PassThru -NoNewWindow
Write-Output "Ghidra exited with code: $($process.ExitCode)"
