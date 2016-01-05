# Source VHD
$srcVhd = "https://mwasmhost.blob.core.windows.net/vhds/mw-asm-ho-mw-asm-host-os-1451493085931.vhd"

# Destination VHD name
$destVhdName = "mw-arm-host.vhd"

# Destination Container Name 
$destContainerName = "vhds"

# Source Storage Account and Key
$srcStorageAccount = "mwasmhost"
$srcStorageKey = "bvwisvZfX4jU08dnPOIAJSaDxZq+sKYyP+2YX4gtsyN0/OhcSSD0qoIR2Edb/3AoD39sX/QD7G36Gnn9x0eXPg=="

# Target Storage Account and Key
$destStorageAccount = "mwarmhost"
$destStorageKey = "cKUMXfP41zBci0a48k/SAhMBuHa0dn7eMCKeGZDfJlnCfyV8wuRbmIoUUwkhX+uWWY+J/WglY3ET8DYSr9czQA=="

# Create the source storage account context (this creates the context, it does not actually create a new storage account)
$srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey

# Create the destination storage account context 
$destContext = New-AzureStorageContext -StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey

# Start the copy  
$blob1 = Start-AzureStorageBlobCopy -Context $srcContext -AbsoluteUri $srcVhd -DestContainer $destContainerName -DestBlob $destVhdName -DestContext $destContext -Verbose 

# check status of copy
$blob1 | Get-AzureStorageBlobCopyState