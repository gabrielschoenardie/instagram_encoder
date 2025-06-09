function Get-VideoFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Vertical', 'Horizontal')]
        [string]$AspectRatio
    )

    if ($AspectRatio -eq 'Vertical') {
        return "scale=if(gt(a,9/16),1080,-2):if(gt(a,9/16),-2,1920):flags=lanczos,format=yuv420p"
    }
    else {
        return "scale=if(gt(a,16/9),1920,-2):if(gt(a,16/9),-2,1080):flags=lanczos,format=yuv420p"
    }
}