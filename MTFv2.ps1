# INFO
# run the script in STEP 1 at the bottom as local administrator
# run the script outside the powershell IDE
# the HOUR in the new name depends on what time zone the script is run in.

# for releasing references to ComObjects later
function Release-Ref ($ref) {
    ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

# to avoid attempting to rename a file with an invalid file name
function Remove-InvalidFileNameChars ([String]$Name, [switch]$IncludeSpace) {
    if ($IncludeSpace) {
        [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape([String][System.IO.Path]::GetInvalidFileNameChars())), '')
    } else {
        [RegEx]::Replace($Name, "[{0}]" -f ([RegEx]::Escape(-join [System.IO.Path]::GetInvalidFileNameChars())), '')
    }
}

# use robocopy instead of Get-ChildItem because it can handle filenames longer than 260 characters
function Get-Files {
    param (
        [string[]]$Path = $PWD,
        [string[]]$Include,
        [switch]$Recurse,
        [switch]$FoldersOnly
    )

    $params = '/L', '/NJH', '/BYTES', '/FP', '/NC', '/TS', '/XJ', '/R:0', '/W:0'
    if ($Recurse) {$params += '/E'}
    if ($Include) {$params += $Include}
    foreach ($dir in $Path) {
        foreach ($line in $(robocopy $dir NULL $params)) {
            # folder
            if (!$Include -and $line -match '\s+\d+\s+(?<FullName>.*\\)$') {
                New-Object PSObject -Property @{
                    FullName = $matches.FullName
                    Size = $null
                    DateModified = $null
                }
            # file
            } elseif (!$FoldersOnly -and $line -match '(?<Size>\d+)\s(?<Date>\S+\s\S+)\s+(?<FullName>.*)') {
                New-Object PSObject -Property @{
                    FullName = $matches.FullName
                    Size = $matches.Size
                    DateModified = $matches.Date
                }
            } else {
                Write-Verbose ('{0}' -f $line)
            }
        }
    }
}

cls

# set up source folder
$folder = Read-Host 'Drag and drop the folder you wish to process.'
$folder = $folder -replace '"' # sometimes drag-n-drop inclues quotes in the string
if (!$folder) { Throw 'No folder provided.' }

# decide if it should be run recursively
$recursive = Read-Host 'Check all subfolders? y/[N]'
if ($recursive -eq 'y') {
    $mails = Get-Files $folder -Include *.msg -Recurse | select -ExpandProperty fullname | ? {$_ -match '\.msg$'}
} else {
    $mails = Get-Files $folder -Include *.msg | select -ExpandProperty fullname | ? {$_ -match '\.msg$'}
}

# choose a format how the files should be renamed
Write-Host '    1: SUBJECT [A][FROM][DATE]'
Write-Host '    2: [DATE][FROM][A] SUBJECT'
$format = $null
while ($format -ne 1 -and $format -ne 2) {
    $format = Read-Host 'Choose a formatting option. [1]/2'
    if (!$format) { $format = 1 }
}

# skip files that have already been done
# if enabled, progress will only show those that need to be processed rather than the total count of messages
if ($format -eq 1) {
    $mails = $mails | ? {$_ -notmatch '\[.*\]\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}\](?:-\d+)?\.msg$'}
} else {
    $mails = $mails | ? {$_ -notmatch '\\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}\]\[.*\]'}
}

# set up outlook object for checking each email's properties using microsoft outlook
$Outlook = New-Object -ComObject Outlook.application
$user = $Outlook.Session.CurrentUser.Name

# get available drives in case dealing with long file names
# we can map a drive to a long file path so it is short enough for powershell to handle
$drives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$avail = diff $drives $alpha | select -ExpandProperty inputobject
$drive = $avail[0] + ':'

# i is used to update Write-Progress
$i = 1
$total = $mails.Count
foreach ($mail in $mails) {
    
    $type = 1
    
    # basename of current file
    $file = (Split-Path $mail -Leaf) -replace '\.msg$'

    # makes sure there is more than one email, otherwise you would get divide by zero error
    $folder = Split-Path $mail
    if ($total -gt 1) {
        Write-Progress `
            -Activity 'Processing...' `
            -Status "($i of $total) [$('{0:N0}' -f (($i/$total)*100))%] FOLDER: $folder" `
            -CurrentOperation "FILE: $file" `
            -PercentComplete (($i/$total)*100)
        $i++
    }
    
    # skip files that have already been done
    # enable this to show all files in progress
    <#
    if ($format -eq 1) {
        if ($file -match '\[.*\]\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}\](?:-\d+)?$') { continue }
    } else {
        if ($file -match '\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}\.[0-9]{2}\.[0-9]{2}\]\[.*\]') { continue }
    }
    #>

    # if filename is longer than 240 characters,
    # map a drive to the current path to shorten the filename
    $null = subst $drive /d
    $subst = $false
    if ($mail.length -gt 240) {
        $path = Split-Path $mail
        subst $drive $path
        $subst = $true
        rv path
        $mail = Join-Path $drive $(Split-Path $mail -Leaf)
    }

    # create mail item to get its properties by using the outlook object
    try {
        $msg = $Outlook.CreateItemFromTemplate($mail)
    } catch {
        try {
            # i don't think i have had it fail to this part, but it's here just in case
            # this will get all the mail info just from what it can find as though opening the file in notepad

            # GOING THROUGH THIS METHOD ONLY SAYS "A" IF IT HAS ATTACHMENTS!
            
            $type = 2
            
            # GET FILE CONTENTS
            $text = $null
            $text = cmd /c "type `"$mail`" 2>&1"
            if ($text -match 'The system cannot find') { Throw 'Unable to process. Probably due to strange characters in the filename.' }
            0..$($text.count-1) | % {$text[$_] = -join([string[]]$text[$_] | % {[char[]]$_} | ? {$_})}
            
            # SUBJECT
            $subject = $null
            $subject = @($text | ? {$_ -match '(?:subject|emne): '})[0] -replace '^.*(?:subject|emne): '
            
            # ATTACHMENT
            $attachment = $false
            $attached = $text | ? {$_ -match 'X-MS-Has-Attach: yes'}
            if ($attached) {
                $attached = 'A'
                $attachment = $true
            }

            # FROM
            $from = $null
            $from = @($text | ? {$_ -match '(?:fra|from): '})[0] -replace '^.*(?:fra|from): '
            $from = $from.Trim()
            if ($from -match '^\<') {
                $from = $from -replace '\<|\>'
            } elseif ($from -match '^\[') {
                $from = $from -replace '\[|\]'
            } elseif ($from -match '\[') {
                $from = $from -replace '^([^\[]+) \[.*$', '$1' -replace '"'
            } else {
                $from = $from -replace '^([^\<]+) <.*$', '$1' -replace '"'
            }
            $from = $from -replace '\s+$'
            $from = Remove-InvalidFileNameChars $from
            $from = ($from.split() | ? {$_}) -join ' '
            #if ($from.Length -gt 30) { $from = $from.Substring(0, 30) }
            #$from = $from.Trim()

            # DATE
            $date = $null
            $date = ($text | ? {$_ -match 'date: '} | select -f 1) -replace '^.*date: '
            try {
                $day = Get-Date $date -f yyyy-MM-dd
                $date = ($date -replace '^.*(\d\d:\d\d:\d\d).*$', '$1').Replace(':', '.')
                $date = "$day $date"
            } catch { $date = $null }
            if (!$date) {
                Write-Host "Date Error: $file" -ForegroundColor Red
                $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
                "filename: $mail" >> "$env:temp\MTFerror.txt"
                'Could not get DATE information' >> "$env:temp\MTFerror.txt"
                '' >> "$env:temp\MTFerror.txt"
            }
        } catch {
            Write-Host "Skipping: $file" -ForegroundColor Yellow
            $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
            "filename: $mail" >> "$env:temp\MTFerror.txt"
            $error[0] >> "$env:temp\MTFerror.txt"
            '' >> "$env:temp\MTFerror.txt"
            
            # if both methods fail, un-map the drive if it has been mapped then go to the next email

            if ($subst) {
                subst $drive /d
            }

            continue
        }
    }
    
    # only runs if successfully created the Outlook mail object
    if ($type -eq 1) {
        # SUBJECT
        $subject = Remove-InvalidFileNameChars $msg.Subject

        # ATTACHMENT
        # get list of types of attachments
        # combined all files like 'image001.xxx' into img because this will likely be in all emails signatures
        $attachment = $false
        try {
            # if no filename
            # DisplayName      : Picture (Device Independent Bitmap)
            # no real attachments. results in [..]
            $attached = $msg.Attachments | % {if ($_.filename) {$_.filename} elseif ($_.displayname -eq 'Picture (Device Independent Bitmap)') {'image000.jpg'} else {'?'}}
        } catch {
            Write-Host "Attachments Error: $file" -ForegroundColor Red
            $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
            "filename: $mail" >> "$env:temp\MTFerror.txt"
            "attached: $attached" >> "$env:temp\MTFerror.txt"
            $error[0] >> "$env:temp\MTFerror.txt"
            '' >> "$env:temp\MTFerror.txt"
        }
        if ($attached) {
            $attached = ($attached | % {if ($_ -match '^image[0-9]{3}.[a-zA-Z]{3,4}$') {'.img'} else {$_}} | % {if ($_ -match '\.') {$_.substring($_.lastindexof('.') + 1).ToLower()} else {'..'}} | ? {$_} | select -Unique | sort) -join ','
            $attachment = $true
        }

        # FROM
        $from = $null
        $from = Remove-InvalidFileNameChars $msg.SenderName
    
        # HOW TO SEE IF YOU SENT THE MESSAGE.
        # disabling this because it will create different results depending on who ran the script
        # probably best to keep all emails as FROM
        <#
        $to = $null
        if ($from.ToLower() -eq $user) {
            $names = $msg.To
            if ($names -match ';') {
                $names = $names.Split(';') | % {$_ -replace '^ '}
            }
            if ([array]$names.Count -gt 2) {
                $names = $($names[0..1] -join ';') + ';..'
            } elseif ([array]$names.count -eq 2) {
                $names = $names[0..1] -join ';'
            }
            $to = Remove-InvalidFileNameChars $names
        }
        #>
    
        # DATE
        # the HOUR will be different depending on what time zone you run this in
        $date = $null
        $date = Get-Date $msg.SentOn -f 'yyyy-MM-dd HH.mm.ss'
        if (!$date) {
            Write-Host "Date Error: $file" -ForegroundColor Red
            $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
            "filename: $mail" >> "$env:temp\MTFerror.txt"
            'Could not get DATE information' >> "$env:temp\MTFerror.txt"
            '' >> "$env:temp\MTFerror.txt"
        }
    }

    # RELEASE COM OBJECT REFERENCES
    $null = $msg | % {
        while (Release-Ref $_) {
            Release-Ref $_
        }
    }

    # BUILD THE NEW FILENAME
    if ($format -eq 1) {
        $basename = ''
        $basename += "$subject "
        if ($attachment) { $basename += "[$attached]" }
        if ($to) {
            $basename += "[»$to][$date]"
        } else {
            $basename += "[$from][$date]"
        }
    } else {
        $basename = ''
        if ($to) {
            $basename += "[$date][»$to]"
        } else {
            $basename += "[$date][$from]"
        }
        if ($attachment) { $basename += "[$attached]" }
        $basename += " $subject"
    }

    # MAKE SURE NOT TO OVERWRITE AN EXISTING FILE
    # appends "-1" to the end of the name if the file already exists
    $num = 1
    $TargetPath = Split-Path $mail
    $ext = '.msg'
    $newname = Join-Path $TargetPath ($basename + $ext)
	while (Test-Path -LiteralPath $newname) {
        $newname = Join-Path $TargetPath $($basename + "-$num" + $ext)
        $num++
	}
    rv TargetPath
    
    # must use move with literalpath because name has brackets in it
    try {
        mv -LiteralPath $mail $newname
    } catch {
        Write-Host "Rename Error: $mail" -ForegroundColor Red
        $(Get-Date -f yyyyMMdd_HHmmss) >> "$env:temp\MTFerror.txt"
        "filename: $mail" >> "$env:temp\MTFerror.txt"
        "new name: $newname" >> "$env:temp\MTFerror.txt"
        $error[0] >> "$env:temp\MTFerror.txt"
        '' >> "$env:temp\MTFerror.txt"
    }

    # un-map drive if one was mapped
    if ($subst) {
        subst $drive /d
    }
}

# force un-map the drive just in case it was left for some reason
$null = subst $drive /d

# RELEASE COM OBJECT REFERENCES
$null = $Outlook | % {
    while (Release-Ref $_) {
        Release-Ref $_
    }
}

Write-Host 'Done!'
Read-Host 'Press Enter to continue...'

<# NOTE: DO THIS FIRST! AS (any) ADMIN!
# STEP 1
# this prevents popups in outlook
# http://www.msoutlook.info/question/883
# run as logged in user with admin rights then RESTART OUTLOOK if it's open:
$users = reg query hkey_users | ? {$_ -match '-\d{5}$'}
$users | % {
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "AdminSecurityMode" /t REG_DWORD /d "00000003" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptOOMSend" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptOOMAddressBookAccess" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptOOMAddressInformationAccess" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptOOMMeetingTaskRequestResponse" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptOOMSaveAs" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptOOMFormulaAccess" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptSimpleMAPISend" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptSimpleMAPINameResolve" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\15.0\Outlook\Security" /v "PromptSimpleMAPIOpenMessage" /t REG_DWORD /d "00000002" /f

    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "AdminSecurityMode" /t REG_DWORD /d "00000003" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptOOMSend" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptOOMAddressBookAccess" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptOOMAddressInformationAccess" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptOOMMeetingTaskRequestResponse" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptOOMSaveAs" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptOOMFormulaAccess" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptSimpleMAPISend" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptSimpleMAPINameResolve" /t REG_DWORD /d "00000002" /f
    reg add "$_\Software\Policies\Microsoft\Office\14.0\Outlook\Security" /v "PromptSimpleMAPIOpenMessage" /t REG_DWORD /d "00000002" /f
}#>
