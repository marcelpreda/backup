$src_path = @(
    "C:\Workfolder\yourpath...",
    "C:\Users\$Env:USERNAME\Dropbox\PFA",
    "C:\Workfolder\yourpath2...",
    "C:\Workfolder\yourpath3...")
$backup_host = "nas2"
$backup_user = "backup2"

$date = Get-Date -Format "yyyy_MM_dd__HH_mm_ss"
$backup_dst_path = "/mnt/backup/$Env:USERNAME/$date"


ssh ${backup_user}@${backup_host} "mkdir -p $backup_dst_path"

# create the local folder for archiving
$new_bkp_path = New-Item -Path "$pwd\backup_$date" -ItemType Directory

# Copress $src to $dst
Function CompressItem($src, $dst) {
    $compress = @{
        Path = $src
        DestinationPath = $dst
        CompressionLevel = "Fastest"
    }
    Compress-Archive @compress
    #return $compress.DestinationPath
}


# keep here all the scp processes tahat are started in background
# later we should wait for them to finish
$all_scp_procs = @()

foreach ($p in $src_path) {
    $f_name = Split-Path $p -leaf
    $zip_name = "$f_name.zip".Replace(" ", "_")
    $dst_zip = "$new_bkp_path\$zip_name"
    Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "    Compress $p"
    "    To       $dst_zip"
    CompressItem $p $dst_zip        
    $proc = Start-Process scp -ArgumentList "$dst_zip ${backup_user}@${backup_host}:${backup_dst_path}" -PassThru
    $all_scp_procs += $proc
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"    All archives created. Wait to finish all scp processes"

Foreach ($p in $all_scp_procs) {
    $p.WaitForExit()
}
Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Read-Host -Prompt "Press any key and then ENTER to close." | Out-Null

