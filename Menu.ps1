# https://www.reddit.com/r/PowerShell/comments/4ad8or/create_user_menus_from_objectsarrays/
# https://www.reddit.com/r/PowerShell/comments/49tqgx/need_some_help_with_an_automation_script_im/
# http://www.powertheshell.com/input_psv3/

# TODO:
#  - allow select multiple items. ex: 0, 1 then split and trim

function Menu {
    param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [object[]]$Object,
        $Prompt,
        [switch]$AllowCancel
    )

    begin {
        $arraylist = New-Object System.Collections.ArrayList
    }

    process {
        [void]$arraylist.Add($Object)
    }

    end {
        if (!$arraylist) { Throw 'Must provide an object.' }
        $ok = $false
        Write-Host ''

        do {
            if ($Prompt) {
                Write-Host $Prompt
            } elseif ($AllowCancel) {
                Write-Host 'Choose an option, or enter "C" to cancel'
            } else {
                Write-Host 'Choose an option'
            }

            for ($i = 0; $i -lt $arraylist.count; $i++) {
                Write-Host $i`. $($arraylist[$i])
            }

            Write-Host ''

            $answer = Read-Host

            if ($AllowCancel -and $answer.ToLower() -eq 'c') {
                return
            }

            if ($answer -in 0..($arraylist.count - 1)) {
                $arraylist[$answer]
                $ok = $true
            } else {
                Write-Host 'Not an option!' -ForegroundColor Red
                Write-Host ''
            }
        } while (!$ok)
    }
}
