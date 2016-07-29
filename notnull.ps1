# only return properties that do not contain a null value
# ex: get-mailbox 'user' | notnull
# ex: (get-psdrive)[0] | notnull | fl

filter notnull {
    $props = @()
    $obj = $_
    $obj | gm -m *property | % { if ( $obj.$($_.name) ) {$props += $_.name} }
    $obj | select $props
}
