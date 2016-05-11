# https://www.reddit.com/r/PowerShell/comments/4ad8or/create_user_menus_from_objectsarrays/
# https://www.reddit.com/r/PowerShell/comments/49tqgx/need_some_help_with_an_automation_script_im/
# http://www.powertheshell.com/input_psv3/

# EXAMPLE1
# $folder = Get-ChildItem | Out-Menu
# lists folder contents and prompts user to select one of the items

# EXAMPLE 2
# $folder = Out-Menu -Object $(Get-ChildItem) -Header '---Folder List---' -Footer '---Enter a folder number---'
# lists folder contents between header and footer text

# EXAMPLE 3
# menu $(dir) -AllowMultiple
# lists folder contents and allows user to select multiple items by giving a comma separated list of items (1, 2, 5)

# EXAMPLE 4
# [IO.DriveInfo]::GetDrives() | menu -AllowCancel
# lists drives to choose from. if 'c' is entered, the menu selection is canceled and $null is returned

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

    if (!$Object) { Throw 'Must provide an object.' }
    Write-Host ''

    do {
        if ($Header) {
            Write-Host $Header
        } elseif ($AllowCancel) {
            Write-Host 'Choose an option, or enter "C" to cancel'
        } else {
            Write-Host 'Choose an option'
        }

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

            if ($AllowCancel -and $answer.ToLower() -eq 'c') {
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
