
if (gcm Set-Clipboard -ea 0) {
    return
}

# http://stackoverflow.com/questions/1567112/convert-keith-hills-powershell-get-clipboard-and-set-clipboard-to-a-psm1-script
# for some reason, this adds new lines after everything...
#function Out-Clipboard {
#
#    # !! We do NOT use an advanced function here, because we want to use $Input.
#    param (
#        [PSObject]$InputObject,
#        [switch]$Verbose
#    )
#
#    if ($args.count) { throw 'Unrecognized parameter(s) specified.' }
#
#    # Out-string invariably adds an extra terminating newline, which we want to strip.
#    $stripTrailingNewline = $true
#    if ($InputObject) { # Direct argument specified.
#        if ($InputObject -is [string]) {
#            $stripTrailingNewline = $false
#            $text = $InputObject # Already a string, use as is.
#        } else {
#            $text = $InputObject | Out-String # Convert to string as it would display in the console
#        }
#    } else { # Use pipeline input, if present.
#        $text = $input | Out-String # convert ENTIRE pipeline input to string as it would display in the console
#    }
#
#    if ($stripTrailingNewline -and $text.Length -gt 2) {
#        $text = $text.Substring(0, $text.Length - 2)
#    }
#
#    Add-Type -AssemblyName System.Windows.Forms
#    if ([threading.thread]::CurrentThread.ApartmentState.ToString() -eq 'STA') {
#        if ($Verbose) { # Simulate verbose output.
#            $fgColor = 'Cyan'
#            if ($PSVersionTable.PSVersion.major -le 2) { $fgColor = 'Yellow' }
#            Write-Host -ForegroundColor $fgColor 'STA mode: Using [Windows.Forms.Clipboard] directly.'
#        }
#
#        if (-not $text) { $text = "`0" } # Strangely, SetText() breaks with an empty string, claiming $null was passed -> use a null char.
#        [System.Windows.Forms.Clipboard]::SetText($text, [System.Windows.Forms.TextDataFormat]::UnicodeText)
#
#    } else {
#        if ($Verbose) { # Simulate verbose output.
#            $fgColor = 'Cyan'
#            if ($PSVersionTable.PSVersion.major -le 2) { $fgColor = 'Yellow' }
#            Write-Host -ForegroundColor $fgColor 'MTA mode: Using a [System.Windows.Forms.TextBox] instance for clipboard access.'
#        }
#
#        if (-not $text) { 
#            # !! This approach cannot set the clipboard to an empty string: the text box must
#            # !! must be *non-empty* in order to copy something. A null character doesn't work.
#            # !! We use the least obtrusive alternative - a newline - and issue a warning.
#            $text = "`r`n"
#            Write-Warning 'Setting clipboard to empty string not supported in MTA mode; using newline instead.'
#        }
#
#        $tb = New-Object System.Windows.Forms.TextBox
#        $tb.Multiline = $true
#        $tb.Text = $text
#        $tb.SelectAll()
#        $tb.Copy()
#    }
#}

# http://poshcode.org/2219
# for some reason, this adds new lines after everything...
#function Out-Clipboard {
#    param(
#        ## The input to send to the clipboard
#        [Parameter(ValueFromPipeline = $true)]
#        [object[]] $InputObject
#    )
#
#    begin {
#        Set-StrictMode -Version Latest
#        $objectsToProcess = @()
#    }
#
#    process {
#        ## Collect everything sent to the script either through
#        ## pipeline input, or direct input.
#        $objectsToProcess += $inputObject
#    }
#
#    end {
#        ## Launch a new instance of PowerShell in STA mode.
#        ## This lets us interact with the Windows clipboard.
#        $objectsToProcess | PowerShell -NoProfile -STA -Command {
#            Add-Type -Assembly PresentationCore
#
#            ## Convert the input objects to a string representation
#            $clipText = ($input | Out-String -Stream) -join "`r`n"
#
#            ## And finally set the clipboard text
#            [Windows.Clipboard]::SetText($clipText)
#        }
#    }
#}

# http://andyarismendi.blogspot.com/2013/04/out-clipboard-cmdlet.html
# this one works as expected
function Set-Clipboard {
    [cmdletbinding()]
    param (
        [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]$InputObject,
        [switch] $File
    )

    begin {
        $ps = [PowerShell]::Create()
        $rs = [RunSpaceFactory]::CreateRunspace()
        $rs.ApartmentState = 'STA'
        $rs.ThreadOptions = 'ReuseThread'
        $rs.Open()
        $data = @()
    }

    process {
        $data += $InputObject
    }

    end {
        $rs.SessionStateProxy.SetVariable('do_file_copy', $File)
        $rs.SessionStateProxy.SetVariable('data', $data)
        $ps.Runspace = $rs
        $ps.AddScript({
            Add-Type -AssemblyName System.Windows.Forms
            if ($do_file_copy) {
                $file_list = New-Object -TypeName System.Collections.Specialized.StringCollection
                $data | % {
                    if ($_ -is [System.IO.FileInfo]) {
                        [void]$file_list.Add($_.FullName)
                    } elseif ([IO.File]::Exists($_)) {
                        [void]$file_list.Add($_)
                    }
                }
                [System.Windows.Forms.Clipboard]::SetFileDropList($file_list)
            } else {
                $host_out = (($data | Out-String -Width 1000) -split "`n" | % {$_.TrimEnd()}) -join "`n"
                [System.Windows.Forms.Clipboard]::SetText($host_out)
            }
        }).Invoke()
    }
}

# http://stackoverflow.com/questions/1567112/convert-keith-hills-powershell-get-clipboard-and-set-clipboard-to-a-psm1-script
# this just puts 'ok' in the clipboard...
#function Out-ClipBoard() {
#    Param(
#      [Parameter(ValueFromPipeline=$true)]
#      [string] $text
#    )
#    Add-Type -AssemblyName System.Windows.Forms
#    $tb = New-Object System.Windows.Forms.TextBox
#    $tb.Multiline = $true
#    $tb.Text = $text
#    $tb.SelectAll()
#    $tb.Copy()
#}

<# https://www.reddit.com/r/PowerShell/comments/4fp0ut/what_are_you_using_in_your_powershell_profile/
function Out-ClipBoard 
{
    param(  
        [Parameter(
            Position=0, 
            Mandatory=$true, 
            ValueFromPipeline=$true)
        ]
        $output,
        [Parameter(Position=1)]
        $sep = " "
    )

    begin
    {
        $str = "";
    }

    process
    {
        if($output.EndsWith("\n") -or $output.EndsWith("\r"))
        {
            $str += ($output.SubString(0, $output.Length - 1) + $sep)
        }
        else
        {
            $str += ($output + $sep)
        }
    }

    end
    {
        $str = $str.SubString(0, $str.Length - 1)
        if($sep -eq "`n")
        {
            $str | clip
        }
        else
        {
            cmd.exe /c "(echo.|set /p=`"$str`") | clip"
        }
    }
}
#>
