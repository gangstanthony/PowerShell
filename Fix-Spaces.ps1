# EXAMPLE:
# $a = @(
# 'System File Checker Utility (Scan On Every Boot) = sfc /scanboot'
# 'System File Checker Utility (Return Scan Setting To Default) = sfc /revert'
# )
# 
# PS C:\> Fix-Spaces '=' $a
# System File Checker Utility (Scan On Every Boot)             = sfc /scanboot
# System File Checker Utility (Return Scan Setting To Default) = sfc /revert

function Fix-Spaces {
    param (
        [string]$delim = $(Throw 'A delimiter must be supplied.'),
        [string[]]$array
    )
    
    $len = 0
    $array | % {
        if ($_.contains($delim) -and $_.indexof($delim) -gt $len) {
            $len = $_.indexof($delim)
        }
    }

    $array | % {
        if ($_.Contains($delim)) {
            $front = $_.substring(0, $_.indexof($delim))
            $back  = $_.substring($_.indexof($delim) + $delim.Length)
            if ($front.length -lt $len) {
                $spaces = $len - $front.Length - 1
                0..$spaces | % {$front += ' '}
            }
            $front + $delim + $back
        } else {
            $_
        }
    }
}
