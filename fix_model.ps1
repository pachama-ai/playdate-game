$path = "C:\Users\User\Downloads\playdate-master\playdate-master\source"
$files = @(,@("model.lua", "controller.lua", "view.lua", "main.lua"))

function Write-File {
    param($name, $content)
    $full = Join-Path "C:\Users\User\Downloads\playdate-master\playdate-master\source" $name
    [System.IO.File]::WriteAllText($full, $content, [System.Text.UTF8Encoding]::new($false))
}

Write-File "model.lua" @"
-- model.lua: 8 feste Ringe
"@

Write-Host "done"
