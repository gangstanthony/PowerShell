
function Get-FileName($InitialDirectory) {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $InitialDirectory
    #$OpenFileDialog.Filter = "All files (*.*)| *.*"
    $OpenFileDialog.Filter = "CHT files|*.cht"
    $null = $OpenFileDialog.ShowDialog()
    $OpenFileDialog.FileName
}

function update-listbox {
    $listbox.items.Clear()

    $global:cheatsobj | sort number | % {
        $cheat = $_

        $desc = $(
            if ($cheat.desc.length -lt 13) {
                $cheat.desc + (' ' * (13 - $cheat.desc.length))
            } elseif ($cheat.desc.length -gt 13) {
                $cheat.desc.substring(0, 10) + '...'
            } else {
                $cheat.desc
            }
        )

        $text = "Cheat #$('{0:D2}' -f $cheat.number): $desc ($(if ($cheat.enable -eq 'true') {'ON'} elseif ($cheat.enable -eq 'false') {'OFF'} else {'error'})) : $($cheat.code)"
        $listbox.items.Add($text)
    }

    clear-fields

    disable-buttons
}

function clear-fields {
    $lblnumbervalue.Text = ''
    $cmbenable.Items.Clear(); $cmbenable.Items.AddRange(($false, $true))
    $txtdesc.Text = ''
    $txtcode.Text = ''
    $txtaddress.Text = ''
    $txtaddressbitposition.Text = ''
    $txtbigendian.Text = ''
    $txtcheattype.Text = ''
    $txthandler.Text = ''
    $txtmemorysearchsize.Text = ''
    $txtrepeataddtoaddress.Text = ''
    $txtrepeataddtovalue.Text = ''
    $txtrepeatcount.Text = ''
    $txtrumbleport.Text = ''
    $txtrumbleprimaryduration.Text = ''
    $txtrumbleprimarystrength.Text = ''
    $txtrumblesecondaryduration.Text = ''
    $txtrumblesecondarystrength.Text = ''
    $txtrumbletype.Text = ''
    $txtrumblevalue.Text = ''
    $txtvalue.Text = ''
}

function disable-buttons {
    $btnmoveup.Enabled = $false
    $btnmovedown.Enabled = $false
    $btnremovecheat.Enabled = $false
    $btnsavechanges.Enabled = $false
}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = '750,600'
$Form.text = 'Form'
$Form.TopMost = $false

$lblpath = New-Object System.Windows.Forms.Label
$lblpath.Width = $form.Width
$lblpath.Height = 20
$lblpath.Location = New-Object System.Drawing.Point(10, 10)

$btnsave = New-Object system.Windows.Forms.Button
$btnsave.text = "Save File"
$btnsave.Enabled = $false
$btnsave.width = 60
$btnsave.height = 30
$btnsave.location = New-Object System.Drawing.Point(70,50)
$btnsave.add_click({
    # preserve non cheat lines by deleting all lines that begin with cheat then adding these back to the file

    $existing = @(Get-Content $file | ? {$_ -notmatch '^cheat'})

    $output = @()
    $output += $existing

    $global:cheatsobj | % {
        $cheat = $_
        $props = $cheat | gm -MemberType NoteProperty | % name | ? {$_ -ne 'number'}
        $props | % {
            $prop = $_
            $line = 'cheat' + $cheat.number + "_$prop = " + '"' + $cheat.$prop + '"'
            $output += $line
        }
    }

    $output += 'cheats = "' + $global:cheatsobj.count + '"'

    $output | Set-Content $global:file
})

$btnmoveup = New-Object system.Windows.Forms.Button
$btnmoveup.text = "Move Up"
$btnmoveup.Enabled = $false
$btnmoveup.width = 60
$btnmoveup.height = 30
$btnmoveup.location = New-Object System.Drawing.Point(150,50)
$btnmoveup.add_click({
    
    if ($lblnumbervalue.Text -eq 0) {
        return
    }

    $tempcheat = [pscustomobject]@{
        number = $global:cheatsobj[$lblnumbervalue.Text].number
        address = $global:cheatsobj[$lblnumbervalue.Text].address
        address_bit_position = $global:cheatsobj[$lblnumbervalue.Text].address_bit_position
        big_endian = $global:cheatsobj[$lblnumbervalue.Text].big_endian
        cheat_type = $global:cheatsobj[$lblnumbervalue.Text].cheat_type
        code = $global:cheatsobj[$lblnumbervalue.Text].code
        desc = $global:cheatsobj[$lblnumbervalue.Text].desc
        enable = $global:cheatsobj[$lblnumbervalue.Text].enable
        handler = $global:cheatsobj[$lblnumbervalue.Text].handler
        memory_search_size = $global:cheatsobj[$lblnumbervalue.Text].memory_search_size
        repeat_add_to_address = $global:cheatsobj[$lblnumbervalue.Text].repeat_add_to_address
        repeat_add_to_value = $global:cheatsobj[$lblnumbervalue.Text].repeat_add_to_value
        repeat_count = $global:cheatsobj[$lblnumbervalue.Text].repeat_count
        rumble_port = $global:cheatsobj[$lblnumbervalue.Text].rumble_port
        rumble_primary_duration = $global:cheatsobj[$lblnumbervalue.Text].rumble_primary_duration
        rumble_primary_strength = $global:cheatsobj[$lblnumbervalue.Text].rumble_primary_strength
        rumble_secondary_duration = $global:cheatsobj[$lblnumbervalue.Text].rumble_secondary_duration
        rumble_secondary_strength = $global:cheatsobj[$lblnumbervalue.Text].rumble_secondary_strength
        rumble_type = $global:cheatsobj[$lblnumbervalue.Text].rumble_type
        rumble_value = $global:cheatsobj[$lblnumbervalue.Text].rumble_value
        value = $global:cheatsobj[$lblnumbervalue.Text].value
    }
    
    $global:cheatsobj[$lblnumbervalue.Text].number = [int]$lblnumbervalue.Text - 1
    $global:cheatsobj[$lblnumbervalue.Text].address = $global:cheatsobj[$lblnumbervalue.Text-1].address
    $global:cheatsobj[$lblnumbervalue.Text].address_bit_position = $global:cheatsobj[$lblnumbervalue.Text-1].address_bit_position
    $global:cheatsobj[$lblnumbervalue.Text].big_endian = $global:cheatsobj[$lblnumbervalue.Text-1].big_endian
    $global:cheatsobj[$lblnumbervalue.Text].cheat_type = $global:cheatsobj[$lblnumbervalue.Text-1].cheat_type
    $global:cheatsobj[$lblnumbervalue.Text].code = $global:cheatsobj[$lblnumbervalue.Text-1].code
    $global:cheatsobj[$lblnumbervalue.Text].desc = $global:cheatsobj[$lblnumbervalue.Text-1].desc
    $global:cheatsobj[$lblnumbervalue.Text].enable = $global:cheatsobj[$lblnumbervalue.Text-1].enable
    $global:cheatsobj[$lblnumbervalue.Text].handler = $global:cheatsobj[$lblnumbervalue.Text-1].handler
    $global:cheatsobj[$lblnumbervalue.Text].memory_search_size = $global:cheatsobj[$lblnumbervalue.Text-1].memory_search_size
    $global:cheatsobj[$lblnumbervalue.Text].repeat_add_to_address = $global:cheatsobj[$lblnumbervalue.Text-1].repeat_add_to_address
    $global:cheatsobj[$lblnumbervalue.Text].repeat_add_to_value = $global:cheatsobj[$lblnumbervalue.Text-1].repeat_add_to_value
    $global:cheatsobj[$lblnumbervalue.Text].repeat_count = $global:cheatsobj[$lblnumbervalue.Text-1].repeat_count
    $global:cheatsobj[$lblnumbervalue.Text].rumble_port = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_port
    $global:cheatsobj[$lblnumbervalue.Text].rumble_primary_duration = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_primary_duration
    $global:cheatsobj[$lblnumbervalue.Text].rumble_primary_strength = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_primary_strength
    $global:cheatsobj[$lblnumbervalue.Text].rumble_secondary_duration = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_secondary_duration
    $global:cheatsobj[$lblnumbervalue.Text].rumble_secondary_strength = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_secondary_strength
    $global:cheatsobj[$lblnumbervalue.Text].rumble_type = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_type
    $global:cheatsobj[$lblnumbervalue.Text].rumble_value = $global:cheatsobj[$lblnumbervalue.Text-1].rumble_value
    $global:cheatsobj[$lblnumbervalue.Text].value = $global:cheatsobj[$lblnumbervalue.Text-1].value
    
    $global:cheatsobj[$lblnumbervalue.Text-1].number = [int]$lblnumbervalue.Text
    $global:cheatsobj[$lblnumbervalue.Text-1].address = $tempcheat.address
    $global:cheatsobj[$lblnumbervalue.Text-1].address_bit_position = $tempcheat.address_bit_position
    $global:cheatsobj[$lblnumbervalue.Text-1].big_endian = $tempcheat.big_endian
    $global:cheatsobj[$lblnumbervalue.Text-1].cheat_type = $tempcheat.cheat_type
    $global:cheatsobj[$lblnumbervalue.Text-1].code = $tempcheat.code
    $global:cheatsobj[$lblnumbervalue.Text-1].desc = $tempcheat.desc
    $global:cheatsobj[$lblnumbervalue.Text-1].enable = $tempcheat.enable
    $global:cheatsobj[$lblnumbervalue.Text-1].handler = $tempcheat.handler
    $global:cheatsobj[$lblnumbervalue.Text-1].memory_search_size = $tempcheat.memory_search_size
    $global:cheatsobj[$lblnumbervalue.Text-1].repeat_add_to_address = $tempcheat.repeat_add_to_address
    $global:cheatsobj[$lblnumbervalue.Text-1].repeat_add_to_value = $tempcheat.repeat_add_to_value
    $global:cheatsobj[$lblnumbervalue.Text-1].repeat_count = $tempcheat.repeat_count
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_port = $tempcheat.rumble_port
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_primary_duration = $tempcheat.rumble_primary_duration
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_primary_strength = $tempcheat.rumble_primary_strength
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_secondary_duration = $tempcheat.rumble_secondary_duration
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_secondary_strength = $tempcheat.rumble_secondary_strength
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_type = $tempcheat.rumble_type
    $global:cheatsobj[$lblnumbervalue.Text-1].rumble_value = $tempcheat.rumble_value
    $global:cheatsobj[$lblnumbervalue.Text-1].value = $tempcheat.value

    update-listbox
})

$btnmovedown = New-Object system.Windows.Forms.Button
$btnmovedown.text = "Move Down"
$btnmovedown.Enabled = $false
$btnmovedown.width = 80
$btnmovedown.height = 30
$btnmovedown.location = New-Object System.Drawing.Point(210,50)
$btnmovedown.add_click({
})

$btnaddcheat = New-Object system.Windows.Forms.Button
$btnaddcheat.text = "Add Cheat"
$btnaddcheat.Enabled = $false
$btnaddcheat.width = 70
$btnaddcheat.height = 30
$btnaddcheat.location = New-Object System.Drawing.Point(325,50)
$btnaddcheat.add_click({
    $newcheat = [pscustomobject]@{
        number = $global:cheatsobj.Count
        address = $global:cheatsobj[0].address
        address_bit_position = $global:cheatsobj[0].address_bit_position
        big_endian = $global:cheatsobj[0].big_endian
        cheat_type = $global:cheatsobj[0].cheat_type
        code = $global:cheatsobj[0].code
        desc = $global:cheatsobj[0].desc
        enable = $global:cheatsobj[0].enable
        handler = $global:cheatsobj[0].handler
        memory_search_size = $global:cheatsobj[0].memory_search_size
        repeat_add_to_address = $global:cheatsobj[0].repeat_add_to_address
        repeat_add_to_value = $global:cheatsobj[0].repeat_add_to_value
        repeat_count = $global:cheatsobj[0].repeat_count
        rumble_port = $global:cheatsobj[0].rumble_port
        rumble_primary_duration = $global:cheatsobj[0].rumble_primary_duration
        rumble_primary_strength = $global:cheatsobj[0].rumble_primary_strength
        rumble_secondary_duration = $global:cheatsobj[0].rumble_secondary_duration
        rumble_secondary_strength = $global:cheatsobj[0].rumble_secondary_strength
        rumble_type = $global:cheatsobj[0].rumble_type
        rumble_value = $global:cheatsobj[0].rumble_value
        value = $global:cheatsobj[0].value
    }
    
    $global:cheatsobj += $newcheat

    update-listbox
})

$btnremovecheat = New-Object system.Windows.Forms.Button
$btnremovecheat.text = "Remove Cheat"
$btnremovecheat.Enabled = $false
$btnremovecheat.width = 90
$btnremovecheat.height = 30
$btnremovecheat.location = New-Object System.Drawing.Point(395,50)
$btnremovecheat.add_click({
    $global:cheatsobj = $global:cheatsobj | ? number -ne $lblnumbervalue.Text

    update-listbox
})

$btnsavechanges = New-Object system.Windows.Forms.Button
$btnsavechanges.text = "Save Edits"
$btnsavechanges.Enabled = $false
$btnsavechanges.width = 80
$btnsavechanges.height = 30
$btnsavechanges.location = New-Object System.Drawing.Point(520,50)
$btnsavechanges.add_click({
    $global:cheatsobj[$listbox.SelectedIndex].address = $txtaddress.Text
    $global:cheatsobj[$listbox.SelectedIndex].address_bit_position = $txtaddressbitposition.Text
    $global:cheatsobj[$listbox.SelectedIndex].big_endian = $txtbigendian.Text
    $global:cheatsobj[$listbox.SelectedIndex].cheat_type = $txtcheattype.Text
    $global:cheatsobj[$listbox.SelectedIndex].code = $txtcode.Text
    $global:cheatsobj[$listbox.SelectedIndex].desc = $txtdesc.Text
    $global:cheatsobj[$listbox.SelectedIndex].enable = $cmbenable.Text
    $global:cheatsobj[$listbox.SelectedIndex].handler = $txthandler.Text
    $global:cheatsobj[$listbox.SelectedIndex].memory_search_size = $txtmemorysearchsize.Text
    $global:cheatsobj[$listbox.SelectedIndex].repeat_add_to_address = $txtrepeataddtoaddress.Text
    $global:cheatsobj[$listbox.SelectedIndex].repeat_add_to_value = $txtrepeataddtovalue.Text
    $global:cheatsobj[$listbox.SelectedIndex].repeat_count = $txtrepeatcount.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_port = $txtrumbleport.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_primary_duration = $txtrumbleprimaryduration.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_primary_strength = $txtrumbleprimarystrength.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_secondary_duration = $txtrumblesecondaryduration.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_secondary_strength = $txtrumblesecondarystrength.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_type = $txtrumbletype.Text
    $global:cheatsobj[$listbox.SelectedIndex].rumble_value = $txtrumblevalue.Text
    $global:cheatsobj[$listbox.SelectedIndex].value = $txtvalue.Text

    # refresh the listbox
    update-listbox

    clear-fields
})

$btnload = New-Object system.Windows.Forms.Button
$btnload.text = "Load File"
$btnload.width = 60
$btnload.height = 30
$btnload.location = New-Object System.Drawing.Point(10,50)
$btnload.add_click({
    $lblpath.Text = ''
    $listbox.items.Clear()
    $btnsave.Enabled = $false
    $btnaddcheat.Enabled = $false
    clear-fields
    disable-buttons
    
    $global:file = Get-FileName
    $lblpath.Text = $global:file

    if ($global:file) {
        $btnsave.Enabled = $true
        $btnaddcheat.Enabled = $true

        # only get lines that begin with "cheat..."
        $content = Get-Content $file | ? {$_ -match '^cheat'}
        write-host $($content -join "`r`n")
        $cheats = $content | group {$_.split('_')[0]} | ? count -eq 20 | sort {'{0:d2}' -f [int]$_.name.replace('cheat','')}
        
        $global:cheatsobj = $(
            foreach ($cheat in $cheats) {
                $lines = $cheat.group
                $hash = @{}
                $hash.Add('number',[int]$cheat.name.Replace('cheat',''))
                foreach ($line in $lines) {
                    $split = $line.split('=').trim()
                    $name = $split[0].split('_',2)[1]
                    $value = $split[1].trim('"')
                    $hash.Add($name, $value)
                }
                [pscustomobject]$hash
            }
        )

        # update listbox
        update-listbox
    }
})

$listbox = New-Object System.Windows.Forms.ListBox
$listbox.Width = 350
$listbox.Height = 450
$listbox.Location = New-Object System.Drawing.Point(10, 100)
$listbox.Font = 'consolas,10'

$listbox.add_SelectedIndexChanged({
    $btnsavechanges.Enabled = $true
    #$btnmoveup.Enabled = $true
    #$btnmovedown.Enabled = $true
    $btnremovecheat.Enabled = $true

    $lblnumbervalue.Text = $global:cheatsobj[$listbox.SelectedIndex].number
    $cmbenable.SelectedIndex = $(if ($global:cheatsobj[$listbox.SelectedIndex].enable -eq 'true') {1} else {0})
    $txtdesc.Text = $global:cheatsobj[$listbox.SelectedIndex].desc
    $txtcode.Text = $global:cheatsobj[$listbox.SelectedIndex].code
    $txtaddress.Text = $global:cheatsobj[$listbox.SelectedIndex].address
    $txtaddressbitposition.Text = $global:cheatsobj[$listbox.SelectedIndex].address_bit_position
    $txtbigendian.Text = $global:cheatsobj[$listbox.SelectedIndex].big_endian
    $txtcheattype.Text = $global:cheatsobj[$listbox.SelectedIndex].cheat_type
    $txthandler.Text = $global:cheatsobj[$listbox.SelectedIndex].handler
    $txtmemorysearchsize.Text = $global:cheatsobj[$listbox.SelectedIndex].memory_search_size
    $txtrepeataddtoaddress.Text = $global:cheatsobj[$listbox.SelectedIndex].repeat_add_to_address
    $txtrepeataddtovalue.Text = $global:cheatsobj[$listbox.SelectedIndex].repeat_add_to_value
    $txtrepeatcount.Text = $global:cheatsobj[$listbox.SelectedIndex].repeat_count
    $txtrumbleport.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_port
    $txtrumbleprimaryduration.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_primary_duration
    $txtrumbleprimarystrength.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_primary_strength
    $txtrumblesecondaryduration.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_secondary_duration
    $txtrumblesecondarystrength.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_secondary_strength
    $txtrumbletype.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_type
    $txtrumblevalue.Text = $global:cheatsobj[$listbox.SelectedIndex].rumble_value
    $txtvalue.Text = $global:cheatsobj[$listbox.SelectedIndex].value
})


$lblnumber = New-Object System.Windows.Forms.Label
$lblnumber.Width = 150
$lblnumber.Height = 20
$lblnumber.Location = New-Object System.Drawing.Point(370, 100)
$lblnumber.TextAlign = 'middleright'
$lblnumber.Text = 'number'

$lblenable = New-Object System.Windows.Forms.Label
$lblenable.Width = 150
$lblenable.Height = 20
$lblenable.Location = New-Object System.Drawing.Point(370, 120)
$lblenable.TextAlign = 'middleright'
$lblenable.Text = 'enable'

$lbldesc = New-Object System.Windows.Forms.Label
$lbldesc.Width = 150
$lbldesc.Height = 20
$lbldesc.Location = New-Object System.Drawing.Point(370, 140)
$lbldesc.TextAlign = 'middleright'
$lbldesc.Text = 'desc'

$lblcode = New-Object System.Windows.Forms.Label
$lblcode.Width = 150
$lblcode.Height = 20
$lblcode.Location = New-Object System.Drawing.Point(370, 160)
$lblcode.TextAlign = 'middleright'
$lblcode.Text = 'code'

$lbladdress = New-Object System.Windows.Forms.Label
$lbladdress.Width = 150
$lbladdress.Height = 20
$lbladdress.Location = New-Object System.Drawing.Point(370, 180)
$lbladdress.TextAlign = 'middleright'
$lbladdress.Text = 'address'

$lbladdressbitposition = New-Object System.Windows.Forms.Label
$lbladdressbitposition.Width = 150
$lbladdressbitposition.Height = 20
$lbladdressbitposition.Location = New-Object System.Drawing.Point(370, 200)
$lbladdressbitposition.TextAlign = 'middleright'
$lbladdressbitposition.Text = 'address bit position'

$lblbigendian = New-Object System.Windows.Forms.Label
$lblbigendian.Width = 150
$lblbigendian.Height = 20
$lblbigendian.Location = New-Object System.Drawing.Point(370, 220)
$lblbigendian.TextAlign = 'middleright'
$lblbigendian.Text = 'big endian'

$lblcheattype = New-Object System.Windows.Forms.Label
$lblcheattype.Width = 150
$lblcheattype.Height = 20
$lblcheattype.Location = New-Object System.Drawing.Point(370, 240)
$lblcheattype.TextAlign = 'middleright'
$lblcheattype.Text = 'cheat type'

$lblhandler = New-Object System.Windows.Forms.Label
$lblhandler.Width = 150
$lblhandler.Height = 20
$lblhandler.Location = New-Object System.Drawing.Point(370, 260)
$lblhandler.TextAlign = 'middleright'
$lblhandler.Text = 'handler'

$lblmemorysearchsize = New-Object System.Windows.Forms.Label
$lblmemorysearchsize.Width = 150
$lblmemorysearchsize.Height = 20
$lblmemorysearchsize.Location = New-Object System.Drawing.Point(370, 280)
$lblmemorysearchsize.TextAlign = 'middleright'
$lblmemorysearchsize.Text = 'memory search size'

$lblrepeataddtoaddress = New-Object System.Windows.Forms.Label
$lblrepeataddtoaddress.Width = 150
$lblrepeataddtoaddress.Height = 20
$lblrepeataddtoaddress.Location = New-Object System.Drawing.Point(370, 300)
$lblrepeataddtoaddress.TextAlign = 'middleright'
$lblrepeataddtoaddress.Text = 'repeat add to address'

$lblrepeataddtovalue = New-Object System.Windows.Forms.Label
$lblrepeataddtovalue.Width = 150
$lblrepeataddtovalue.Height = 20
$lblrepeataddtovalue.Location = New-Object System.Drawing.Point(370, 320)
$lblrepeataddtovalue.TextAlign = 'middleright'
$lblrepeataddtovalue.Text = 'repeat add to value'

$lblrepeatcount = New-Object System.Windows.Forms.Label
$lblrepeatcount.Width = 150
$lblrepeatcount.Height = 20
$lblrepeatcount.Location = New-Object System.Drawing.Point(370, 340)
$lblrepeatcount.TextAlign = 'middleright'
$lblrepeatcount.Text = 'repeat count'

$lblrumbleport = New-Object System.Windows.Forms.Label
$lblrumbleport.Width = 150
$lblrumbleport.Height = 20
$lblrumbleport.Location = New-Object System.Drawing.Point(370, 360)
$lblrumbleport.TextAlign = 'middleright'
$lblrumbleport.Text = 'rumble port'

$lblrumbleprimaryduration = New-Object System.Windows.Forms.Label
$lblrumbleprimaryduration.Width = 150
$lblrumbleprimaryduration.Height = 20
$lblrumbleprimaryduration.Location = New-Object System.Drawing.Point(370, 380)
$lblrumbleprimaryduration.TextAlign = 'middleright'
$lblrumbleprimaryduration.Text = 'rumble primary duration'

$lblrumbleprimarystrength = New-Object System.Windows.Forms.Label
$lblrumbleprimarystrength.Width = 150
$lblrumbleprimarystrength.Height = 20
$lblrumbleprimarystrength.Location = New-Object System.Drawing.Point(370, 400)
$lblrumbleprimarystrength.TextAlign = 'middleright'
$lblrumbleprimarystrength.Text = 'rumble primary strength'

$lblrumblesecondaryduration = New-Object System.Windows.Forms.Label
$lblrumblesecondaryduration.Width = 150
$lblrumblesecondaryduration.Height = 20
$lblrumblesecondaryduration.Location = New-Object System.Drawing.Point(370, 420)
$lblrumblesecondaryduration.TextAlign = 'middleright'
$lblrumblesecondaryduration.Text = 'rumble secondary duration'

$lblrumblesecondarystrength = New-Object System.Windows.Forms.Label
$lblrumblesecondarystrength.Width = 150
$lblrumblesecondarystrength.Height = 20
$lblrumblesecondarystrength.Location = New-Object System.Drawing.Point(370, 440)
$lblrumblesecondarystrength.TextAlign = 'middleright'
$lblrumblesecondarystrength.Text = 'rumble secondary strength'

$lblrumbletype = New-Object System.Windows.Forms.Label
$lblrumbletype.Width = 150
$lblrumbletype.Height = 20
$lblrumbletype.Location = New-Object System.Drawing.Point(370, 460)
$lblrumbletype.TextAlign = 'middleright'
$lblrumbletype.Text = 'rumble type'

$lblrumblevalue = New-Object System.Windows.Forms.Label
$lblrumblevalue.Width = 150
$lblrumblevalue.Height = 20
$lblrumblevalue.Location = New-Object System.Drawing.Point(370, 480)
$lblrumblevalue.TextAlign = 'middleright'
$lblrumblevalue.Text = 'rumble value'

$lblvalue = New-Object System.Windows.Forms.Label
$lblvalue.Width = 150
$lblvalue.Height = 20
$lblvalue.Location = New-Object System.Drawing.Point(370, 500)
$lblvalue.TextAlign = 'middleright'
$lblvalue.Text = 'value'


###############

$lblnumbervalue = New-Object System.Windows.Forms.Label
$lblnumbervalue.width = 150
$lblnumbervalue.height = 20
$lblnumbervalue.location = New-Object System.Drawing.Point(520,100)

$cmbenable = New-Object System.Windows.Forms.ComboBox
$cmbenable.width = 150
$cmbenable.height = 20
$cmbenable.location = New-Object System.Drawing.Point(520,120)
$cmbenable.Items.AddRange(($false,$true))

$txtdesc = New-Object system.Windows.Forms.TextBox
$txtdesc.width = 150
$txtdesc.height = 20
$txtdesc.location = New-Object System.Drawing.Point(520,140)

$txtcode = New-Object system.Windows.Forms.TextBox
$txtcode.width = 150
$txtcode.height = 20
$txtcode.location = New-Object System.Drawing.Point(520,160)

$txtaddress = New-Object system.Windows.Forms.TextBox
$txtaddress.width = 150
$txtaddress.height = 20
$txtaddress.location = New-Object System.Drawing.Point(520,180)

$txtaddressbitposition = New-Object system.Windows.Forms.TextBox
$txtaddressbitposition.width = 150
$txtaddressbitposition.height = 20
$txtaddressbitposition.location = New-Object System.Drawing.Point(520,200)

$txtbigendian = New-Object system.Windows.Forms.TextBox
$txtbigendian.width = 150
$txtbigendian.height = 20
$txtbigendian.location = New-Object System.Drawing.Point(520,220)

$txtcheattype = New-Object system.Windows.Forms.TextBox
$txtcheattype.width = 150
$txtcheattype.height = 20
$txtcheattype.location = New-Object System.Drawing.Point(520,240)

$txthandler = New-Object system.Windows.Forms.TextBox
$txthandler.width = 150
$txthandler.height = 20
$txthandler.location = New-Object System.Drawing.Point(520,260)

$txtmemorysearchsize = New-Object system.Windows.Forms.TextBox
$txtmemorysearchsize.width = 150
$txtmemorysearchsize.height = 20
$txtmemorysearchsize.location = New-Object System.Drawing.Point(520,280)

$txtrepeataddtoaddress = New-Object system.Windows.Forms.TextBox
$txtrepeataddtoaddress.width = 150
$txtrepeataddtoaddress.height = 20
$txtrepeataddtoaddress.location = New-Object System.Drawing.Point(520,300)

$txtrepeataddtovalue = New-Object system.Windows.Forms.TextBox
$txtrepeataddtovalue.width = 150
$txtrepeataddtovalue.height = 20
$txtrepeataddtovalue.location = New-Object System.Drawing.Point(520,320)

$txtrepeatcount = New-Object system.Windows.Forms.TextBox
$txtrepeatcount.width = 150
$txtrepeatcount.height = 20
$txtrepeatcount.location = New-Object System.Drawing.Point(520,340)

$txtrumbleport = New-Object system.Windows.Forms.TextBox
$txtrumbleport.width = 150
$txtrumbleport.height = 20
$txtrumbleport.location = New-Object System.Drawing.Point(520,360)

$txtrumbleprimaryduration = New-Object system.Windows.Forms.TextBox
$txtrumbleprimaryduration.width = 150
$txtrumbleprimaryduration.height = 20
$txtrumbleprimaryduration.location = New-Object System.Drawing.Point(520,380)

$txtrumbleprimarystrength = New-Object system.Windows.Forms.TextBox
$txtrumbleprimarystrength.width = 150
$txtrumbleprimarystrength.height = 20
$txtrumbleprimarystrength.location = New-Object System.Drawing.Point(520,400)

$txtrumblesecondaryduration = New-Object system.Windows.Forms.TextBox
$txtrumblesecondaryduration.width = 150
$txtrumblesecondaryduration.height = 20
$txtrumblesecondaryduration.location = New-Object System.Drawing.Point(520,420)

$txtrumblesecondarystrength = New-Object system.Windows.Forms.TextBox
$txtrumblesecondarystrength.width = 150
$txtrumblesecondarystrength.height = 20
$txtrumblesecondarystrength.location = New-Object System.Drawing.Point(520,440)

$txtrumbletype = New-Object system.Windows.Forms.TextBox
$txtrumbletype.width = 150
$txtrumbletype.height = 20
$txtrumbletype.location = New-Object System.Drawing.Point(520,460)

$txtrumblevalue = New-Object system.Windows.Forms.TextBox
$txtrumblevalue.width = 150
$txtrumblevalue.height = 20
$txtrumblevalue.location = New-Object System.Drawing.Point(520,480)

$txtvalue = New-Object system.Windows.Forms.TextBox
$txtvalue.width = 150
$txtvalue.height = 20
$txtvalue.location = New-Object System.Drawing.Point(520,500)



$Form.controls.AddRange(@($lblpath,$btnload,$btnsave,$btnsavechanges,$btnaddcheat,$btnmoveup,$btnmovedown,$btnremovecheat,
$listbox,
$lblnumber,$lbladdress,
$lbladdressbitposition,$lblbigendian,$lblcheattype,$lblcode,$lbldesc,
$lblenable,$lblhandler,$lblmemorysearchsize,$lblrepeataddtoaddress,
$lblrepeataddtovalue,$lblrepeatcount,$lblrumbleport,$lblrumbleprimaryduration,
$lblrumbleprimarystrength,$lblrumblesecondaryduration,$lblrumblesecondarystrength,
$lblrumbletype,$lblrumblevalue,$lblvalue,$lblnumbervalue,$cmbenable,
$txtdesc,$txtvalue,$txtaddress,$txtaddressbitposition,$txtbigendian,$txtcheattype,$txtcode,$txthandler,$txtmemorysearchsize,$txtrepeataddtoaddress,$txtrepeataddtovalue,$txtrepeatcount,$txtrumbleport,
$txtrumbleprimaryduration,$txtrumbleprimarystrength,$txtrumblesecondaryduration,$txtrumblesecondarystrength,$txtrumbletype,$txtrumblevalue))

#####



#####

$Form.ShowDialog()

