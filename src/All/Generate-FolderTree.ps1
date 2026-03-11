# PowerShell script to generate descriptive folder tree for GitHub Copilot
# Usage: .\Generate-FolderTree.ps1 -RootPath "C:\Path\To\Your\Project" -OutputFile "folder-structure.md"

param(
    [Parameter(Mandatory=$true)]
    [string]$RootPath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "folder-structure.md",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxDepth = 3,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeFiles
)

function Get-FolderDescription {
    param([string]$FolderName, [string]$ParentPath)
    
    # Define folder descriptions based on Kentico 11 structure
    $descriptions = @{
        "Admin" = "Kentico administration interface"
        "App_Data" = "Application data storage - logs, cache, temp files"
        "App_Themes" = "Theme components - Customize styling and appearance here"
        "bin" = ".NET assemblies and compiled code"
        "CMSAdminControls" = "CMS Admin UI controls and components"
        "CMSFormControls" = "Form control components - Extendable with custom controls"
        "CMSMasterPages" = "Master page templates for consistent layout"
        "CMSModules" = "Core CMS modules - Contains system code (modify with caution)"
        "CMSPages" = "CMS-specific pages and dialogs"
        "CMSScripts" = "JavaScript files - use /Custom for custom development"
        "CMSWebParts" = "Reusable page components - Can be extended with custom webparts"
        "Custom" = "Custom development area - Safe for modifications"
        "obj" = "Build output and temporary compilation files"
        "Properties" = "Project properties and publish profiles"
        "assets" = "Static assets - images, fonts, icons"
        "media" = "Site media files - images, documents"
        "Stylesheets" = "CSS files not managed by Kentico"
        "Scripts" = "JavaScript files for site functionality"
        "Images" = "Image assets for the site"
        "data-files" = "Data import/export files"
        "AzureCache" = "Azure caching data"
        "CMSTemp" = "Temporary CMS files"
        "Templates" = "Page and email templates"
        "VersionHistory" = "Content versioning data"
        "roslyn" = "C# compiler services"
        "jquery" = "jQuery library files"
        "Bootstrap" = "Bootstrap framework files"
        "Vendor" = "Third-party vendor libraries"
        "open-iconic" = "Licensed icon font files"
        "PublishProfiles" = "Deployment configuration files"
        "Old_App_Code" = "Legacy code files (archived)"
    }
    
    # Check for specific patterns
    if ($FolderName -match "Site$") {
        return "Site-specific assets and customizations"
    }
    elseif ($FolderName -match "^CMS") {
        return "Kentico CMS system component"
    }
    elseif ($descriptions.ContainsKey($FolderName)) {
        return $descriptions[$FolderName]
    }
    else {
        return "Project component"
    }
}

function Get-TreeStructure {
    param(
        [string]$Path,
        [int]$CurrentDepth = 0,
        [string]$Prefix = "",
        [bool]$IsLast = $true
    )
    
    if ($CurrentDepth -gt $MaxDepth) { return }
    
    $items = Get-ChildItem -Path $Path -Directory | Sort-Object Name
    
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item = $items[$i]
        $isLastItem = ($i -eq ($items.Count - 1))
        
        # Create tree characters
        $connector = if ($isLastItem) { "+---" } else { "+---" }
        $nextPrefix = if ($isLastItem) { "$Prefix    " } else { "$Prefix|   " }
        
        # Get folder description
        $description = Get-FolderDescription -FolderName $item.Name -ParentPath $Path
        
        # Output the current folder
        "$Prefix$connector$($item.Name)   #$description"
        
        # Recursively process subdirectories
        if ($CurrentDepth -lt $MaxDepth) {
            Get-TreeStructure -Path $item.FullName -CurrentDepth ($CurrentDepth + 1) -Prefix $nextPrefix -IsLast $isLastItem
        }
    }
    
    # Include files if requested
    if ($IncludeFiles -and $CurrentDepth -le 1) {
        $files = Get-ChildItem -Path $Path -File | Where-Object { $_.Extension -in @('.cs', '.js', '.ts', '.css', '.ascx', '.aspx') } | Sort-Object Name
        foreach ($file in $files) {
            $fileType = switch ($file.Extension) {
                '.cs' { 'C# code file' }
                '.js' { 'JavaScript file' }
                '.ts' { 'TypeScript file' }
                '.css' { 'Stylesheet' }
                '.ascx' { 'User control' }
                '.aspx' { 'Web page' }
                default { 'Project file' }
            }
            "$Prefix    $($file.Name)   #$fileType"
        }
    }
}

# Main execution
try {
    if (-not (Test-Path $RootPath)) {
        throw "Path does not exist: $RootPath"
    }
    
    $rootFolderName = Split-Path $RootPath -Leaf
    $output = @()
    
    # Header
    $output += "# Project Folder Structure"
    $output += ""
    $output += "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Root Path: $RootPath"
    $output += ""
    
    # Start code block
    $codeBlockStart = '```'
    $output += $codeBlockStart
    $output += "$rootFolderName/   #Project Root - Main Kentico 11 application directory"
    
    # Generate tree structure
    $treeOutput = Get-TreeStructure -Path $RootPath
    $output += $treeOutput
    
    # End code block
    $codeBlockEnd = '```'
    $output += $codeBlockEnd
    $output += ""
    $output += "## Key Directories for Development"
    $output += ""
    $output += "- **CMSWebParts/Custom/**: Primary location for custom webpart development"
    $output += "- **CMSScripts/Custom/**: Safe location for custom JavaScript files"
    $output += "- **App_Themes/**: Theme customization and styling"
    $output += "- **CMSFormControls/**: Custom form controls and input components"
    $output += "- **assets/**: Static assets not managed by Kentico"
    $output += ""
    $output += "## Modification Guidelines"
    $output += ""
    $output += "- ✅ **Safe to modify**: Custom folders, themes, assets"
    $output += "- ⚠️ **Modify with caution**: CMSModules, core CMS files"
    $output += "- ❌ **Do not modify**: bin/, obj/, App_Data/CMSTemp/"
    
    # Write to file
    $output | Out-File -FilePath $OutputFile -Encoding UTF8
    
    Write-Host "Folder structure generated successfully: $OutputFile" -ForegroundColor Green
    Write-Host "Total directories processed: $($treeOutput.Count)" -ForegroundColor Cyan
}
catch {
    Write-Error "Error generating folder structure: $($_.Exception.Message)"
}
