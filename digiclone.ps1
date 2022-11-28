Function Start-DigiClone {

  Param     (
    [ValidateScript({Test-Path $_ })]
        [Parameter(Mandatory=$true,
        HelpMessage='Source binary')]
        $Source = '',
    
    [ValidateScript({Test-Path $_ })]
        [Parameter(Mandatory=$true,
        HelpMessage='Target binary')]
        $Target = '',

    [Parameter(Mandatory=$False,
        HelpMessage='Include digital signature')]
        [Switch]$Sign
        
  )

# Logo

$logo = @"

========================================================
  _____  _  _____ _         _____ _                  
 |  __ \(_)/ ____(_)       / ____| |                 
 | |  | |_| |  __ _ ______| |    | | ___  _ __   ___ 
 | |  | | | | |_ | |______| |    | |/ _ \| '_ \ / _ \
 | |__| | | |__| | |      | |____| | (_) | | | |  __/
 |_____/|_|\_____|_|       \_____|_|\___/|_| |_|\___|                                                                                                         
                          
                          By - Kishan Mishra (201000018)
                               Akshit Rana(201000002)  
                               IIIT NAYA RAIPUR.
========================================================

"@

Set-StrictMode -Version 2


Function Invoke-TimeStomp ($source, $dest) {
    $source_attributes = Get-Item $source
    $dest_attributes = Get-Item $dest 
    $dest_attributes.CreationTime = $source_attributes.CreationTime
    $dest_attributes.LastAccessTime = $source_attributes.LastAccessTime
    $dest_attributes.LastWriteTime = $source_attributes.LastWriteTime
}

# Binaries
$resourceHackerBin = ".\src\resource_hacker\ResourceHacker.exe"
$sigthiefBin       = ".\src\SigThief-master\dist\sigthief.exe"


# If ((Test-Path $resourceHackerBin) -ne $True) 
#     {
#         Write-Output "[!] Missing Dependency: $resourceHackerBin"
#         Write-Output "[!] Ensure you're running MetaTwin from its local directory. Exiting"
#         break
#     }

# If ((Test-Path $sigthiefBin) -ne $True) 
#     {
#         Write-Output "[!] Missing Dependency: $sigthiefBin"
#         Write-Output "[!] Ensure you're running MetaTwin from its local directory. Exiting."
#         break
#     }

$timestamp = Get-Date -f yyyyMMdd_HHmmss
$log_file_base = (".\" + $timestamp + "\" + $timestamp)
$source_binary_filename = Split-Path $Source -Leaf -Resolve
$source_binary_filepath = $Source
$target_binary_filename = Split-Path $Target -Leaf -Resolve
$target_binary_filepath = $Target
$source_resource = (".\" + $timestamp + "\" + $timestamp + "_" + $source_binary_filename + ".res")
$target_saveas = (".\" + $timestamp + "\" + $timestamp + "_" + $target_binary_filename)
$target_saveas_signed = (".\" + $timestamp + "\" + $timestamp + "_signed_" + $target_binary_filename)

New-Item ".\$timestamp" -type directory | out-null
Write-Output $logo
Write-Output "Source:         $source_binary_filepath"
Write-Output "Target:         $target_binary_filepath"
Write-Output "Output:         $target_saveas"
Write-Output "Signed Output:  $target_saveas_signed"
Write-Output "---------------------------------------------- "


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Stop-Process -Name ResourceHacker -ea "SilentlyContinue"

# Using resource hacker
 Write-Output "[*] Extracting resources from $source_binary_filename "

$log_file = ($log_file_base + "_extract.log")

$arg = "-open $source_binary_filepath -action extract -mask ,,, -save $source_resource -log $log_file"
start-process -FilePath $resourceHackerBin -ArgumentList $arg -NoNewWindow -Wait

# Check if extract was successful
if (Select-String -Encoding Unicode -path $log_file -pattern "Failed") {
    Write-Output "[!] Failed to extract Metadata from $source_binary_filepath"
    Write-Output "    Perhaps, try a differenct source file. Exiting..."
    break   
}

# Copy resources using Resource Hacker
"[*] Copying resources from $source_binary_filename to $target_saveas"

$arg = "-open $target_binary_filepath -save $target_saveas -resource $source_resource -action addoverwrite"
start-process -FilePath $resourceHackerBin -ArgumentList $arg -NoNewWindow -Wait

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# Add Digital Signature using SigThief
if ($Sign) {

    # Copy signature from source and add to target
    "[*] Extracting and adding signature ..."
    $arg = "-i $source_binary_filepath -t $target_saveas -o $target_saveas_signed"
    $proc = start-process -FilePath $sigthiefBin -ArgumentList $arg -Wait -PassThru
    #$proc | Select * |Format-List
    #$proc.ExitCode
    if ($proc.ExitCode -ne 0) {
        Write-Output "[-] Cannot extract signature, skipping ..."     
        $Sign = $False   
    }
}

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Display Results
Start-Sleep .5
Write-Output "`n[+] Results"
Write-Output " -----------------------------------------------"


if ($Sign) {

    Write-Output "[+] Metadata"
    Get-Item $target_saveas_signed | Select VersionInfo | Format-List

    Write-Output "[+] Digital Signature"
    Get-AuthenticodeSignature (gi $target_saveas_signed) | select SignatureType,SignerCertificate,Status | fl
    Invoke-TimeStomp $source_binary_filepath $target_saveas_signed
} 

else {
    Write-Output "[+] Metadata"
    Get-Item $target_saveas | Select VersionInfo | Format-List
    Write-Output "[+] Digital Signature"
    Write-Output "    Signature not added ... "
    Invoke-TimeStomp $source_binary_filepath $target_saveas
}

}
