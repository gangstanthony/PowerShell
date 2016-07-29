# only return properties whose value matches your search
# ex: get-mailbox 'user' | propmatch 'user'
# ex: (get-psdrive)[0] | propmatch 'alias'

filter propmatch ([string]$match='') {
    $props = @()
    $obj = $_
    $obj | gm -m *property | % { if ($obj.$($_.name) -match $match) {$props += [string]$_.name} }
    $obj | select $props
}
