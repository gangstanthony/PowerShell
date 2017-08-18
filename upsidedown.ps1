function upsidedown ([string]$text) {
    $alpha = @'
    up,upchar,down,downchar
    a,97,?,592
    b,98,q,113
    c,99,?,596
    d,100,p,112
    e,101,?,477
    f,102,?,607
    g,103,?,387
    h,104,?,613
    i,105,i,305
    j,106,?,638
    k,107,?,670
    l,108,l,108
    m,109,?,623
    n,110,u,117
    o,111,o,111
    p,112,d,100
    q,113,b,98
    r,114,?,633
    s,115,s,115
    t,116,?,647
    u,117,n,110
    v,118,?,652
    w,119,?,653
    x,120,x,120
    y,121,?,654
    z,122,z,122
    .,46,?,729
    _,95,?,8254
    (,40,),41
    ),41,(,40
    [,91,],93
    ],93,[,91
    {,123,},125
    },125,{,123
    ?,63,¿,191
    !,33,¡,161
    ",",44,',39
    ',39,",",44
'@ | ConvertFrom-Csv
    
    $hash = @{}
    $alpha | select upchar, downchar | % {$hash[$_.upchar] = $_.downchar}
    
    $arraylist = New-Object System.Collections.ArrayList
    $arraylist.AddRange(($text.ToCharArray() | % {if ($hash[[string]$([int]$_)]) {[char][int]($hash[[string]$([int]$_)])} else {$_}})) | Out-Null
    $arraylist.Reverse()
    -join $arraylist.ToArray()
}

# PS> upsidedown "eh... what's up, doc?"
# ¿ɔop 'dn s,ʇɐɥʍ ˙˙˙ɥǝ
