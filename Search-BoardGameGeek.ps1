# https://boardgamegeek.com/wiki/page/BGG_XML_API&redirectedfrom=XML_API#
# https://www.boardgamegeek.com/xmlapi2/thing?id=13&stats=1
# https://boardgamegeek.com/xmlapi/search?search=catan

function search-bgg {
    param (
        $name
    )
    
    $search = iwr https://boardgamegeek.com/xmlapi/search?search=$name

    $objs = ([xml]$search.content).boardgames.boardgame

    $all = $objs | % {$_.name} | % {if ($_.'#text') {$_.'#text'} else {$_}}

    if ($all.count -eq 0) {
        [pscustomobject]@{
            Game = $name
            ID = ''
            Average = ''
            BayesAverage = ''
        }
        return
    } elseif ($all.count -eq 1) {
        $selection = $all
    } else {
        $msd = try{
            Get-Command Measure-StringDistance -ea Stop
        } catch {
            # uncomment to load function from github
            # iex (iwr https://raw.githubusercontent.com/michaellwest/PowerShell-Modules/master/CorpApps/Measure-StringDistance.ps1).content
            $?
        }

        if ($msd) {
            $guess = @($all | select @{n='result';e={$_}}, @{n='diff';e={ 1- (Measure-StringDistance $name $_) / $name.length }} | sort diff | select -l 1 | % result)
        } else {
            $guess = $null
        }
        
        $selection = ($guess + $all) | Out-GridView -PassThru
        #$selection = ($guess + $all) | Out-Menu
        #$selection = Get-Choice -Choices ($guess + $all)
        #$selection = read-Choice -Choices ($guess + $all)
        #$selection = Show-ConsoleMenu -Choices ($guess + $all)
    }

    $hash = @{}

    for ($i = 0; $i -lt $objs.count; $i++) {
        try {
            $hash.Add($all[$i], $objs[$i])
        } catch {}
    }

    $obj = $hash[$selection]

    #$n = $obj.InnerText
    $id = $obj.objectid

    #$game = ([xml](iwr https://boardgamegeek.com/xmlapi/boardgame/$id).content).boardgames.boardgame
    $average = ([xml](iwr https://www.boardgamegeek.com/xmlapi2/thing?id=$id`&stats=1).content).items.item.statistics.ratings.average.value
    $bayesaverage = ([xml](iwr https://www.boardgamegeek.com/xmlapi2/thing?id=$id`&stats=1).content).items.item.statistics.ratings.bayesaverage.value

    [pscustomobject]@{
        Game = $selection
        ID = $id
        Average = $average
        BayesAverage = $bayesaverage
    }
}

