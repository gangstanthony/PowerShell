function PRobocopy {
    param (
        [string]$Source = $PWD,
        [string]$Destination = 'NULL',
        [string[]]$Include,
        [long]$Retries = 1000000,
        [long]$WaitTime = 30,
        [string]$ExcludeAttributes,    # RASHCNETO
        [switch]$ExcludeChanged,
        [switch]$ExcludeNewer,
        [switch]$ExcludeOlder,
        [switch]$ListOnly,
        [switch]$Recurse,
        [switch]$NoJobHeader,
        [switch]$Bytes,
        [switch]$FullPathname,
        [switch]$NoClass,
        [switch]$NoDirectoryList,
        [switch]$TimeStamps,
        [switch]$ExcludeJunctions,
        [switch]$Mirror,
        [switch]$FATFileTimes,
        [switch]$Restartable
    )

    if ($Source, $Destination, $Include, $ExcludeAttributes, $args -match '\?') {
        cmd /c Robocopy.exe /?
        return
    }
    if (!$Source) { Throw 'No source directory provided' }
        
    $params = @()
    if ($Destination.ToUpper() -eq 'NULL') {$params += '/L'}
    if ($Retries -ne 1000000)    {$params += "/R:$Retries"}
    if ($WaitTime -ne 30)        {$params += "/W:$WaitTime"}
    if ($ExcludeAttributes)      {$params += "/XA:$ExcludeAttributes"} # need to add validation
    if ($ExcludeChanged)    {$params += '/XC'}
    if ($ExcludeNewer)      {$params += '/XN'}
    if ($ExcludeOlder)      {$params += '/XO'}
    if ($ListOnly)          {$params += '/L'}
    if ($Recurse)           {$params += '/S'}
    if ($NoJobHeader)       {$params += '/NJH'}
    if ($Bytes)             {$params += '/BYTES'}
    if ($FullPathname)      {$params += '/FP'}
    if ($NoClass)           {$params += '/NC'}
    if ($NoDirectoryList)   {$params += '/NDL'}
    if ($TimeStamps)        {$params += '/TL'}
    if ($ExcludeJunctions)  {$params += '/XJ'}
    if ($Mirror)            {$params += '/MIR'}
    if ($FATFileTimes)      {$params += '/FFT'}
    if ($Restartable)       {$params += '/Z'}
    if ($Include)           {$params += $Include}
    
    # Debugging
    #$Source
    #$Destination
    #$params

    robocopy $Source $Destination $params
}

#cls
#PRobocopy 'path' -Include *.txt, *.ps1 -ExcludeAttributes H -ExcludeChanged -ExcludeNewer -ExcludeOlder  -ListOnly -Subdirectories -NoJobHeader -Bytes -FullPathname -NoClass -NoDirectoryList -TimeStamps -ExcludeJunctions -Retries 0 -WaitTime 0 -Mirror -Restartable -FATFileTimes
