$src = "C:\Users\User\Downloads\playdate-master\playdate-master\source"
$enc = New-Object System.Text.UTF8Encoding($false)

function wf($n, $c) {
    [System.IO.File]::WriteAllText("$src\$n", $c, $enc)
}

wf "model.lua" @"
-- model.lua: 8 feste Ringe, kein Queue
"@
