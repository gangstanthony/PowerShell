# http://powershell.org/wp/forums/topic/convertfrom-pdf-powershell-cmdlet/
# https://social.technet.microsoft.com/Forums/scriptcenter/en-US/1268809d-5dc6-4cd2-a97f-a26bc3ae3a8b/using-powershell-to-parse-a-pdf-file?forum=ITCG
# https://www.reddit.com/r/PowerShell/comments/4ad9gp/crappy_powershell_script_to_scrape_the_cafeteria/

function Get-PdfText
{
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    $Path = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)

    try
    {
        $reader = New-Object iTextSharp.text.pdf.pdfreader -ArgumentList $Path
    }
    catch
    {
        throw
    }

    $stringBuilder = New-Object System.Text.StringBuilder

    for ($page = 1; $page -le $reader.NumberOfPages; $page++)
    {
        $text = [iTextSharp.text.pdf.parser.PdfTextExtractor]::GetTextFromPage($reader, $page)
        $null = $stringBuilder.AppendLine($text) 
    }

    $reader.Close()

    return $stringBuilder.ToString()
}
