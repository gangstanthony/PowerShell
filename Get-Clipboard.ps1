
if (gcm Get-Clipboard -ea 0) {
    return
}

#https://www.reddit.com/r/PowerShell/comments/68jpzx/a_small_getclipboard_function_for_ps_before_v5/

<# http://stackoverflow.com/questions/34700427/quickly-create-a-list-of-strings
Add-Type -Assembly System.Windows.Forms | Out-Null
$clp = [Windows.Forms.Clipboard]::GetText() -split "`r`n"
#>

# http://stackoverflow.com/questions/1567112/convert-keith-hills-powershell-get-clipboard-and-set-clipboard-to-a-psm1-script
function Get-Clipboard {
    Add-Type -AssemblyName System.Windows.Forms

    $(if ([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'STA') {
        Write-Verbose 'STA mode: Using [Windows.Forms.Clipboard] directly.'
        # To be safe, we explicitly specify that Unicode (UTF-16) be used - older platforms may default to ANSI.
        [System.Windows.Forms.Clipboard]::GetText([System.Windows.Forms.TextDataFormat]::UnicodeText)
    } else {
        Write-Verbose 'MTA mode: Using a [System.Windows.Forms.TextBox] instance for clipboard access.'
        $tb = New-Object System.Windows.Forms.TextBox
        $tb.Multiline = $true
        $tb.Paste()
        $tb.Text
    }).Split("`n") | % {$_.Trim()}
}

<# http://poshcode.org/2150
function Get-Clipboard {
    Set-StrictMode -Version Latest
    PowerShell -NoProfile -STA -Command {
        Add-Type -Assembly PresentationCore
        [Windows.Clipboard]::GetText()
    }
}
#>

<# http://stackoverflow.com/questions/1567112/convert-keith-hills-powershell-get-clipboard-and-set-clipboard-to-a-psm1-script
function Get-ClipBoard {
    Add-Type -AssemblyName System.Windows.Forms
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true
    $tb.Paste()
    $tb.Text
}
#>
