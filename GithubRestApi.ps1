# https://www.reddit.com/r/PowerShell/comments/lb2j6j/managing_github_files_via_rest_api/
# https://docs.github.com/en/rest/reference/repos#get-repository-content

# create token https://github.com/settings/tokens
# https://channel9.msdn.com/Blogs/trevor-powershell/Automating-the-GitHub-REST-API-Using-PowerShell
# https://web.archive.org/web/20211109164206/https://channel9.msdn.com/Blogs/trevor-powershell/Automating-the-GitHub-REST-API-Using-PowerShell

function git-createfile {
    param (
        $token,
        $message = '',
        $content,
        $owner,
        $repo,
        $path = '.\'
    )

    $base64token = [System.Convert]::ToBase64String([char[]]$token)

    $headers = @{
        Authorization = 'Basic {0}' -f $base64token
    }

    $body = @{
        message = $message
        content = [System.Convert]::ToBase64String([char[]]$($content))
    } | ConvertTo-Json

    Invoke-RestMethod -Headers $headers -Uri https://api.github.com/repos/$owner/$repo/contents/$path -Body $body -Method Put
}

# git-createfile -token '<your token>' -owner gangstanthony -repo MyProject -path 'test/output.txt' -content 'hello world'


function git-getfile {
    param (
        $token,
        $owner,
        $repo,
        $path
    )

    $base64token = [System.Convert]::ToBase64String([char[]]$token)

    $headers = @{
        Authorization = 'Basic {0}' -f $base64token
        accept = 'application/vnd.github.v3+json'
    }

    Invoke-RestMethod -Headers $headers -Uri https://api.github.com/repos/$owner/$repo/contents/$path -Method Get | select *, @{n='content_decoded';e={[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_.content))}}
}

# git-getfile -token '<your token>' -owner gangstanthony -repo MyProject -path 'test/output.txt'


function git-updatefile {
    # requires git-getfile
    param (
        $token,
        $message = '',
        $content,
        $sha,
        $owner,
        $repo,
        $path
    )

    $base64token = [System.Convert]::ToBase64String([char[]]$token)

    $headers = @{
        Authorization = 'Basic {0}' -f $base64token
    }

    if (!$sha) {
        $sha = (git-getfile -token $token -owner $owner -repo $repo -path $path).sha
    }

    $body = @{
        message = $message
        content = [System.Convert]::ToBase64String([char[]]$($content))
        sha = $sha
    } | ConvertTo-Json

    Invoke-RestMethod -Headers $headers -Uri https://api.github.com/repos/$owner/$repo/contents/$path -Body $body -Method Put
}

# git-updatefile -token '<your token>' -owner gangstanthony -repo MyProject -path 'test/output.txt' -content 'newtext'


function git-deletefile {
    # requires git-getfile
    param (
        $token,
        $message = '',
        $sha,
        $owner,
        $repo,
        $path
    )

    $base64token = [System.Convert]::ToBase64String([char[]]$token)

    $headers = @{
        Authorization = 'Basic {0}' -f $base64token
    }

    if (!$sha) {
        $sha = (git-getfile -token $token -owner $owner -repo $repo -path $path).sha
    }

    $body = @{
        message = $message
        sha = $sha
    } | ConvertTo-Json

    Invoke-RestMethod -Headers $headers -Uri https://api.github.com/repos/$owner/$repo/contents/$path -Body $body -Method Delete
}

# git-deletefile -token '<your token>' -owner gangstanthony -repo MyProject -path 'test/output.txt'


function git-uploadfile {
    param (
        $token,
        $message = '',
        $file,
        $owner,
        $repo,
        $path = '.\',
        $sha,
        [switch]$force
    )

    $path = (Join-Path $path (Split-Path $file -Leaf))

    $base64token = [System.Convert]::ToBase64String([char[]]$token)

    $headers = @{
        Authorization = 'Basic {0}' -f $base64token
    }

    if ($force -and !$sha) {
        $sha = $(
            try {
                (git-getfile -token $token -owner $owner -repo $repo -path $path).sha
            } catch {
                $null
            }
        )
    }

    $body = @{
        message = $message
        content = [convert]::ToBase64String((Get-Content $file -Encoding Byte))
        sha = $sha
    } | ConvertTo-Json

    Invoke-RestMethod -Headers $headers -Uri https://api.github.com/repos/$owner/$repo/contents/$path -Body $body -Method Put
}

# git-uploadfile -token '<your token>' -file 'C:\temp\MsWordExample.docx' -owner gangstanthony -repo MyProject -path test -force

