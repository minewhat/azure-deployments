########################################################################
# Connect to an Azure subscription
########################################################################
Login-AzureRmAccount

########################################################################
# Copy a Vhd from an existing storage account to a new storage account
########################################################################

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

########################################################################
# Create a Virtual Machine from an existing OS disk
########################################################################

$resourceGroupName= "armgroup"
$location= "WestEurope"
$storageAccountName= "mwarmhost"
$vmName= "mwarmhost"
$vmSize="Standard_DS2"
$vnetName= "newarm"

# Get storage account configuration for the target storage account
$StorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourcegroupName -AccountName $storageAccountNAme 

#Get Virtual Network configuration
$vnet = Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName 

# Create VM from an existing image
$OSDiskName="$vmName-C-01"
$vm = New-AzureRmVMConfig -vmName $vmName -vmSize $vmSize
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -SubnetId $vnet.Subnets[1].Id 
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id 
$destOSDiskUri = "https://mwarmhost.blob.core.windows.net/vhds/mw-arm-host.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $OSDiskName -VhdUri $destOSDiskUri -Windows -CreateOption attach
New-AzureRmVM -ResourceGroupName $resourceGroupName -VM $vm

########################################################################
