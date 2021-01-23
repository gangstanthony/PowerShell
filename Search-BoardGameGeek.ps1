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
    
    $selection = $null

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
    }
    
    if (!$selection) {
        $selection = $all | Out-GridView -PassThru
        #$selection = $all | Out-Menu
        #$selection = Get-Choice -Choices $all
        #$selection = read-Choice -Choices $all
        #$selection = Show-ConsoleMenu -Choices $all
    }

    $hash = @{}

    for ($i = 0; $i -lt $objs.count; $i++) {
        try {
            $hash.Add($all[$i], $objs[$i])
        } catch {}
    }

    $obj = $hash[$selection]

    $n = $obj.InnerText
    $id = $obj.objectid

    #$game = ([xml](iwr https://boardgamegeek.com//xmlapi/boardgame/$id).content).boardgames.boardgame
    $average = ([xml](iwr https://www.boardgamegeek.com/xmlapi2/thing?id=$id`&stats=1).content).items.item.statistics.ratings.average.value
    $bayesaverage = ([xml](iwr https://www.boardgamegeek.com/xmlapi2/thing?id=$id`&stats=1).content).items.item.statistics.ratings.bayesaverage.value

    [pscustomobject]@{
        Game = $selection
        ID = $id
        Average = $average
        BayesAverage = $bayesaverage
    }
}

