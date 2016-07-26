# https://social.technet.microsoft.com/Forums/windowsserver/en-US/30663446-4091-4a1c-9de0-407046ccc39f/powershell-script-with-submenus-how-to-go-back?forum=winserverpowershell

# the title is not very descriptive, but it's basically write-host $($a | fl * | out-string)

function Write-Object {
    param (
        [Parameter(
            ValueFromPipeline=$True,
            ValueFromPipelinebyPropertyName=$True)]
        [object[]]$Object,
        [string]$Header,
        [string]$Footer
    )
    
    if ($input) {
        $Object = @($input)
    }
    
    if (!$Object) {
        throw 'Must provide an object.'
    }
    
    if ($Header) {
        Write-Host $Header
    }

    ($Object | Format-List * | Out-String).Split("`n").Trim() | ? {$_ -notmatch '^(\s+)?$'} | % {Write-Host $_}

    if ($Footer) {
        Write-Host $Footer
    }
}
