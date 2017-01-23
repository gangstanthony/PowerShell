# https://www.reddit.com/r/PowerShell/comments/4ad8or/create_user_menus_from_objectsarrays/
# https://www.reddit.com/r/PowerShell/comments/49tqgx/need_some_help_with_an_automation_script_im/
# http://www.powertheshell.com/input_psv3/

<# 
.Synopsis 
    This function provides a convenient way to convert a PowerShell object to a list of choices for user input. 
 
.DESCRIPTION 
    Creates a user selection menu based on a given object. Useful for converting any PowerShell object into a list of choices from which the user can select a subset of items. 
 
.EXAMPLE 
    PS>$locations = 'AMER', 'EMEA', 'APAC' 
    PS>Out-Menu -Object $locations 
     
    Description 
    ----------- 
    lists folder contents and prompts user to select one of the items 
 
    Choose an option 
    01. AMER 
    02. EMEA 
    03. APAC 
 
    1 
    AMER 
 
.EXAMPLE 
    PS>$locations = 'AMER', 'EMEA', 'APAC' 
    PS>Out-Menu -Object $locations -Header '---Location List---' -Footer '---Enter a location number---' 
     
    Description 
    ----------- 
    lists folder contents and prompts user to select one of the items between specified header and footer text 
 
    ---Location List--- 
    01. AMER 
    02. EMEA 
    03. APAC 
    ---Enter a location number--- 
 
    2 
    EMEA 
    
.EXAMPLE 
    PS>$locations = 'AMER', 'EMEA', 'APAC' 
    PS>Menu $locations -AllowMultiple 
    
    Description 
    ----------- 
    lists folder contents and allows user to select multiple items by giving a comma separated list of items (1, 2, 5) 
 
    Choose an option 
    To select multiple, enter numbers separated by a comma EX: 1, 2 
    01. AMER 
    02. EMEA 
    03. APAC 
 
    1, 3 
    AMER 
    APAC 
 
.EXAMPLE 
    PS>[IO.DriveInfo]::GetDrives() | Menu -AllowCancel 
     
    Description 
    ----------- 
    lists drives to choose from. if 'c' is entered, the menu selection is canceled and $null is returned 
 
    Choose an option, or enter "c" to cancel. 
    01. C:\ 
    02. D:\ 
 
    c 
 
.INPUTS 
    Accepts common PowerShell object types as input. 
 
.OUTPUTS 
    Outputs object at whichever item the user has selected. 
 
.NOTES 
    If a menu option is selected that does not exist, the menu will be shown again. 
 
.COMPONENT 
    Scripting Techniques 
 
.ROLE 
    Retrieving Input 
 
.FUNCTIONALITY 
    Quickly create a menu for a script that requires user choice. 
 
.LINK 
    https://gallery.technet.microsoft.com/scriptcenter/Out-Menu-41259908 
    https://github.com/gangstanthony/PowerShell/blob/master/Out-Menu.ps1 
     
    Similar functions: 
    Read-Choice http://poshcode.org/5128 
    Show-ConsoleMenu http://poshcode.org/5295 
    Get-Input https://github.com/dfinke/powershell-for-developers/blob/master/chapter07/ShowUI/CommonControls/Get-Input.ps1 
    Select-ViaUI https://github.com/dfinke/powershell-for-developers/blob/master/chapter07/ShowUI/CommonControls/Select-ViaUI.ps1 
#> 
 
function Out-Menu { 
    param ( 
        [Parameter( 
            Mandatory=$true, 
            ValueFromPipeline=$True, 
            ValueFromPipelinebyPropertyName=$True)] 
        [object[]]$Object, 
        [string]$Header, 
        [string]$Footer, 
        [switch]$AllowCancel, 
        [switch]$AllowMultiple 
    ) 
 
    if ($input) { 
        $Object = @($input) 
    } 
 
    if (!$Object) { 
        throw 'Must provide an object.' 
    } 
 
    Write-Host '' 
 
    do { 
        $prompt = New-Object System.Text.StringBuilder 
        switch ($true) { 
            {[bool]$Header -and $Header -notmatch '^(?:\s+)?$'} { $null = $prompt.Append($Header); break }
            $true { $null = $prompt.Append('Choose an option') } 
            $AllowCancel { $null = $prompt.Append(', or enter "c" to cancel.') } 
            $AllowMultiple {$null = $prompt.Append("`nTo select multiple, enter numbers separated by a comma EX: 1, 2") } 
        } 
        Write-Host $prompt.ToString() 
 
        for ($i = 0; $i -lt $Object.Count; $i++) { 
            Write-Host "$('{0:D2}' -f ($i+1)). $($Object[$i])" 
        } 
 
        if ($Footer) { 
            Write-Host $Footer 
        } 
 
        Write-Host '' 
 
        if ($AllowMultiple) { 
            $answers = @(Read-Host).Split(',').Trim() 
 
            if ($AllowCancel -and $answers -match 'c') { 
                return 
            } 
 
            $ok = $true 
            foreach ($ans in $answers) { 
                if ($ans -in 1..$Object.Count) { 
                    $Object[$ans-1] 
                } else { 
                    Write-Host 'Not an option!' -ForegroundColor Red 
                    Write-Host '' 
                    $ok = $false 
                } 
            } 
        } else { 
            $answer = Read-Host 
 
            if ($AllowCancel -and $answer -eq 'c') { 
                return 
            } 
 
            $ok = $true 
            if ($answer -in 1..$Object.Count) { 
                $Object[$answer-1] 
            } else { 
                Write-Host 'Not an option!' -ForegroundColor Red 
                Write-Host '' 
                $ok = $false 
            } 
        } 
    } while (!$ok) 
} 
 
Set-Alias -Name Menu -Value Out-Menu
