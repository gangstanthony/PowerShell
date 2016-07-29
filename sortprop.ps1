# sorts properties by name.
# ex: get-mailbox 'user' | sortprop
# ex: (get-psdrive)[0] | sortprop

filter sortprop {
    $obj = $_
    $props = $obj | gm -m *property | % {$_.name} | sort
    $obj | select $props
}
