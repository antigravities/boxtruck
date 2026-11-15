param (
    [Parameter(Mandatory=$false)]
    [string]$AppId
)

Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Drawing

function Create-DiskArt {
    param(
        [string]$sourceImagePath,
        [string]$outputImagePath,
        [string]$blurredSourceImage
    )

    try {
        $blurredImage = $Null
        $attributes = $Null
        $canvas = [System.Drawing.Bitmap]::new(1200, 1200)
        $graphics = [System.Drawing.Graphics]::FromImage($canvas)

        $color = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
        $graphics.Clear($color);

        if( $blurredSourceImage ){
            $blurredImage = [System.Drawing.Bitmap]::FromFile($blurredSourceImage)

            $blurredImageScale = [Math]::Max($canvas.Width / $blurredImage.Width, $canvas.Height / $blurredImage.Height);
            $blurredImageWidth = [Math]::Round($blurredImage.Width * $blurredImageScale);
            $blurredImageHeight = [Math]::Round($blurredImage.Height * $blurredImageScale);

            $blurredX = [Math]::Round(($canvas.Width - $blurredImageWidth) / 2);
            $blurredY = [Math]::Round(($canvas.Height - $blurredImageHeight) / 2);

            $attributes = [System.Drawing.Imaging.ImageAttributes]::new()
            $attributes.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)

            $destRect = [System.Drawing.Rectangle]::new($blurredX, $blurredY, $blurredImageWidth, $blurredImageHeight)

            $graphics.DrawImage($blurredImage, $destRect, 0, 0, $blurredImage.Width, $blurredImage.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)

            $blurredImage.Dispose()
            $attributes.Dispose()
        }

        $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver;
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality;
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;

        $source = [System.Drawing.Bitmap]::FromFile($sourceImagePath)

        $horizontalPadding = 120
        $availableWidth = $canvas.Width - (2 * $horizontalPadding)

        $scale = [Math]::Min($availableWidth / $source.Width, $canvas.Height / $source.Height);
        $drawWidth = [Math]::Round($source.Width * $scale);
        $drawHeight = [Math]::Round($source.Height * $scale);

        $x = [Math]::Round(($canvas.Width - $drawWidth) / 2);
        $y = [Math]::Round(($canvas.Height - $drawHeight) / 2);

        $graphics.DrawImage($source, $x, $y, $drawWidth, $drawHeight);

        $canvas.Save($outputImagePath, [System.Drawing.Imaging.ImageFormat]::Jpeg);
    } finally {
        if ($graphics) { $graphics.Dispose() }
        if ($source) { $source.Dispose() }
        if ($canvas) { $canvas.Dispose() }
        if ($blurredImage) { $blurredImage.Dispose() }
        if ($attributes) { $attributes.Dispose() }
    }    
}

$basepath = "$($Env:LocalAppData)Low\NestedLoop\BOXROOM\steam_cache_v2"

if( ! $AppId ){
    $directories = Get-ChildItem -Path "C:\Program Files (x86)\Steam\appcache\librarycache" | Where-Object { $_.PSIsContainer }
} else {
    $directories = @(Get-Item -Path "C:\Program Files (x86)\Steam\appcache\librarycache\$AppId")
}

foreach( $directory in $directories ){
    $newpath = Join-Path -Path $basepath -ChildPath $directory.Name
    if( -not (Test-Path -Path $newpath) ){
        New-Item -ItemType Directory -Path $newpath | Out-Null
    }

    if( Test-Path -Path "$($directory.FullName)\library_600x900.jpg" ){
        Copy-Item -Path "$($directory.FullName)\library_600x900.jpg" -Destination "$newpath\boxart.jpg" -Force
    }
    
    $sourceImagePath = $null;

    if( Test-Path -Path "$($directory.FullName)\logo.png"){
        $sourceImagePath = "$($directory.FullName)\logo.png"
    } elseif( Test-Path -Path "$($directory.FullName)\header.jpg" ){
        $sourceImagePath = "$($directory.FullName)\header.jpg"
    }

    if( $sourceImagePath -ne $null -and (Test-Path -Path $sourceImagePath) ){
        if( Test-Path -Path "$($directory.FullName)\library_hero_blur.jpg" ){
            Create-DiskArt -sourceImagePath $sourceImagePath -outputImagePath "$newpath\diskart.jpg" -blurredSourceImage "$($directory.FullName)\library_hero_blur.jpg"
        } else {
            Create-DiskArt -sourceImagePath $sourceImagePath -outputImagePath "$newpath\diskart.jpg"
        }
        Write-Host "Created diskart.jpg for $($directory.Name) using $($sourceImagePath)"
    }
}
