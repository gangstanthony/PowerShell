# also see:
# http://www.codeproject.com/Articles/451744/Extract-worksheets-from-Excel-into-separate-files
# http://social.technet.microsoft.com/Forums/scriptcenter/en-US/4de7ed7a-f1b3-4e35-98b1-ef1f7f2ee7b2/powershell-export-from-excel-to-csv-having-delimiter?forum=ITCG

function Save-ExcelasCSV {
    param (
        [string[]]$files = $(Throw 'No files provided.'),
        [string]$OutFolder,
        [switch]$Overwrite
    )

    BEGIN {
        function Release-Ref ($ref) {
            ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        
        $xl = New-Object -ComObject Excel.Application
        $xl.DisplayAlerts = $false
        $xl.Visible = $false
    }

    PROCESS {
        foreach ($file in $files) {
            $file = Get-Item $file | ? {$_.Extension -match '^\.xlsx?$'}
            if (!$file) {continue}
            $wb = $xl.Workbooks.Open($file.FullName)

            if ($OutFolder) {
                $CSVfilename = Join-Path $OutFolder ($file.BaseName + '.csv')
            } else {
                $CSVfilename = $file.DirectoryName + '\' + $file.BaseName + '.csv'
            }

            if (!$Overwrite -and (Test-Path $CSVfilename)) {
                $num = 1
                $folder = Split-Path $CSVfilename
                $base = (Split-Path $CSVfilename -Leaf).Substring(0, (Split-Path $CSVfilename -Leaf).LastIndexOf('.'))
                $ext = $CSVfilename.Substring($CSVfilename.LastIndexOf('.'))
                while (Test-Path $CSVfilename) {
                    $CSVfilename = Join-Path $folder $($base + "-$num" + $ext)
                    $num += 1
                }
                $wb.SaveAs($CSVfilename, 6) # 6 -> csv
            } else {
                $wb.SaveAs($CSVfilename, 6) # 6 -> csv
            }

            $wb.Close($True)
            $CSVfilename
        }
    }

    END {
        $xl.Quit()
        $null = $wb, $xl | % {try{ Release-Ref $_ }catch{}}
    }
}
