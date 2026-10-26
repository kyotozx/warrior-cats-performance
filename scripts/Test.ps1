param([string]$LuaPath='lua')
$ErrorActionPreference='Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try{
 foreach($test in Get-ChildItem mods/ClanPerformance/tests -Filter '*.test.lua' -File | Sort-Object Name){
  & $LuaPath $test.FullName
  if($LASTEXITCODE -ne 0){throw "Failed: $($test.Name)"}
 }
 $text=Get-Content -LiteralPath README.md -Raw
 if($text.Contains([string][char]0x2014)){throw 'README must not contain em dashes.'}
}finally{Pop-Location}
