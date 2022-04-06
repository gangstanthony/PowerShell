# https://www.itdroplets.com/automating-telegram-messages-with-powershell/
# https://techthoughts.info/poshgram-powershell-module-for-telegram/

function Send-Telegram {
    param (
        $token = '',
        $chatid = '',
        $message = ''
    )

    Invoke-RestMethod -Uri "https://api.telegram.org/bot$($token)/sendMessage?chat_id=$($chatid)&text=$($message)"
}

return

Send-Telegram -token "<token>" -chatid "<id>" -message "test"

