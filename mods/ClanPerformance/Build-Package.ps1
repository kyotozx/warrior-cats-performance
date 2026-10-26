param([string]$Version='0.3.0',[string]$OutputRoot)
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if($Version -notmatch '^[0-9][A-Za-z0-9._-]{0,50}$'){throw 'Invalid version.'}
if(!$OutputRoot){$OutputRoot=Join-Path $repo 'dist'}
$OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
$stage=Join-Path $OutputRoot ('Performance-'+$Version);$zip=$stage+'.zip'
if((Test-Path -LiteralPath $stage) -or (Test-Path -LiteralPath $zip)){throw 'Package exists. Choose a new version or output root.'}
$files=@()
foreach($name in @('main.lua','options.lua','controller.lua','backend.lua','meter.lua','store.lua','menu.lua','json.lua','native_panel.lua','native_skin.lua','runtime_valid.lua','navigation.lua','text_entry.lua','legacy.lua','comfort.lua','comfort_options.lua','comfort_layout.lua')){
 $dest=Join-Path $stage ('payload/ClanPerformance/Scripts/'+$name)
 $null=New-Item -ItemType Directory -Path (Split-Path $dest -Parent) -Force
 Copy-Item -LiteralPath (Join-Path $PSScriptRoot ('Scripts/'+$name)) -Destination $dest
 $files+=@{path='Scripts/'+$name;sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash.ToLowerInvariant()}
}
$manifest=[ordered]@{schema=1;loaderApi=1;gameBuild='24847281';id='ClanPerformance';name='Performance';version=$Version;
 description='Graphics, Camera & Comfort, saved presets and FPS controls. Open from the game menus [F9 / L3].';dependencies=@('ClanLoader');files=$files}
$encoding=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $stage 'mod.json'),($manifest|ConvertTo-Json -Depth 6),$encoding)
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.txt') -Destination (Join-Path $stage 'README.txt')
Copy-Item -LiteralPath (Join-Path $repo 'LICENSE') -Destination (Join-Path $stage 'LICENSE.txt')
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($stage,$zip)
$hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText(($zip+'.sha256'),($hash+'  '+[IO.Path]::GetFileName($zip)+"`n"),$encoding)
Write-Output $zip
Write-Output $hash
