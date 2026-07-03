param(
    [string]$srcDir = "C:\Users\jo\.gemini\antigravity\scratch\kok3-decomp\src",
    [string]$outFile = "C:\Users\jo\.gemini\antigravity\scratch\kok3-decomp\WE.vcproj"
)

# Collect all source files
$cppFiles = Get-ChildItem -Path $srcDir -Recurse -Filter "*.cpp" | Sort-Object FullName
$hFiles = Get-ChildItem -Path $srcDir -Recurse -Filter "*.h" | Sort-Object FullName

# Build filter groups (by directory)
function Get-FilterName($file, $root) {
    $rel = $file.DirectoryName.Substring($root.Length)
    if ($rel.StartsWith("\")) { $rel = $rel.Substring(1) }
    if ($rel -eq "") { return "Source Files" }
    return "Source Files\$rel"
}

$xml = @"
<?xml version="1.0" encoding="Windows-1252"?>
<VisualStudioProject
	ProjectType="Visual C++"
	Version="8.00"
	Name="WE"
	ProjectGUID="{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}"
	RootNamespace="WE"
	Keyword="Win32Proj"
	>
	<Platforms>
		<Platform Name="Win32"/>
	</Platforms>
	<ToolFiles/>
	<Configurations>
		<Configuration
			Name="Debug|Win32"
			OutputDirectory="Debug"
			IntermediateDirectory="Debug"
			ConfigurationType="1"
			CharacterSet="2"
			>
			<Tool
				Name="VCPreBuildEventTool"/>
			<Tool
				Name="VCCLCompilerTool"
				Optimization="0"
				AdditionalIncludeDirectories="src;include;`$(DXSDK_DIR)\Include"
				PreprocessorDefinitions="WIN32;_DEBUG;_WINDOWS"
				MinimalRebuild="true"
				BasicRuntimeChecks="3"
				RuntimeLibrary="3"
				UsePrecompiledHeader="0"
				WarningLevel="3"
				Detect64BitPortabilityProblems="true"
				DebugInformationFormat="4"
			/>
			<Tool
				Name="VCLinkerTool"
				AdditionalDependencies="d3d9.lib d3dx9.lib dinput8.lib dxguid.lib winmm.lib ws2_32.lib"
				OutputFile="`$(OutDir)\WE.exe"
				AdditionalLibraryDirectories="`$(DXSDK_DIR)\Lib\x86"
				GenerateDebugInformation="true"
				ProgramDatabaseFile="`$(OutDir)\WE.pdb"
				SubSystem="2"
				TargetMachine="1"
			/>
			<Tool Name="VCResourceCompilerTool"/>
		</Configuration>
		<Configuration
			Name="Release|Win32"
			OutputDirectory="Release"
			IntermediateDirectory="Release"
			ConfigurationType="1"
			CharacterSet="2"
			WholeProgramOptimization="1"
			>
			<Tool
				Name="VCPreBuildEventTool"/>
			<Tool
				Name="VCCLCompilerTool"
				Optimization="2"
				AdditionalIncludeDirectories="src;include;`$(DXSDK_DIR)\Include"
				PreprocessorDefinitions="WIN32;NDEBUG;_WINDOWS"
				RuntimeLibrary="2"
				UsePrecompiledHeader="0"
				WarningLevel="3"
				Detect64BitPortabilityProblems="true"
				DebugInformationFormat="3"
			/>
			<Tool
				Name="VCLinkerTool"
				AdditionalDependencies="d3d9.lib d3dx9.lib dinput8.lib dxguid.lib winmm.lib ws2_32.lib"
				OutputFile="`$(OutDir)\WE.exe"
				AdditionalLibraryDirectories="`$(DXSDK_DIR)\Lib\x86"
				GenerateDebugInformation="true"
				ProgramDatabaseFile="`$(OutDir)\WE.pdb"
				SubSystem="2"
				OptimizeReferences="2"
				EnableCOMDATFolding="2"
				TargetMachine="1"
			/>
			<Tool Name="VCResourceCompilerTool"/>
		</Configuration>
	</Configurations>
	<References/>
	<Files>
"@

# Group files by directory for VS filters
$allFiles = @()
$allFiles += $cppFiles | ForEach-Object { [PSCustomObject]@{ File = $_; Type = "cpp" } }
$allFiles += $hFiles | ForEach-Object { [PSCustomObject]@{ File = $_; Type = "h" } }

$groups = $allFiles | Group-Object { Get-FilterName $_.File $srcDir }

foreach ($group in ($groups | Sort-Object Name)) {
    $filterName = $group.Name
    $xml += "`t`t<Filter Name=`"$filterName`">`n"
    foreach ($item in $group.Group) {
        $relPath = "src" + $item.File.FullName.Substring($srcDir.Length)
        $xml += "`t`t`t<File RelativePath=`"$relPath`"/>`n"
    }
    $xml += "`t`t</Filter>`n"
}

$xml += @"
	</Files>
	<Globals/>
</VisualStudioProject>
"@

$xml | Out-File -FilePath $outFile -Encoding ASCII
Write-Output "Generated $outFile with $($cppFiles.Count) .cpp and $($hFiles.Count) .h files"
