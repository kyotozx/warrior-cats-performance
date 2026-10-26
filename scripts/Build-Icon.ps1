$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationCore,WindowsBase
$root=Split-Path $PSScriptRoot -Parent
[xml]$svg=Get-Content -LiteralPath (Join-Path $root 'mods/ClanPerformance/icon.svg') -Raw
$visual=[Windows.Media.DrawingVisual]::new();$drawing=$visual.RenderOpen()
$drawing.PushTransform([Windows.Media.ScaleTransform]::new(8,8))
$brush=[Windows.Media.BrushConverter]::new()
$drawing.DrawGeometry($brush.ConvertFromString('#9FCDBE'),$null,[Windows.Media.Geometry]::Parse($svg.svg.path.d))
foreach($path in $svg.svg.g.path){
 $width=if($path.'stroke-width'){[double]$path.'stroke-width'}else{3}
 $pen=[Windows.Media.Pen]::new($brush.ConvertFromString('#17363A'),$width)
 $pen.StartLineCap='Round';$pen.EndLineCap='Round';$pen.LineJoin='Round'
 $drawing.DrawGeometry($null,$pen,[Windows.Media.Geometry]::Parse($path.d))
}
$drawing.Pop();$drawing.Close()
$bitmap=[Windows.Media.Imaging.RenderTargetBitmap]::new(512,512,96,96,[Windows.Media.PixelFormats]::Pbgra32);$bitmap.Render($visual)
$encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
$file=[IO.File]::Create((Join-Path $root 'docs/images/icon.png'));try{$encoder.Save($file)}finally{$file.Dispose()}
