<#	
	Version:        2.1
	Author:         Saravanan Muthiah/Ahmed Hussein
	Creation Date:  25th Apr, 2018
	Updated : May 2020 - include tags as parameters and log in through run as account
	Purpose/Change: Creating Azure Managed Disk Snapshot
#>
#######################################################################################################
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
# ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
# PARTICULAR PURPOSE.
#
# IN NO EVENT SHALL MICROSOFT AND/OR ITS RESPECTIVE SUPPLIERS BE
# LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
# ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THIS CODE OR INFORMATION.
#
#
########################################################################################################

Param
(

  [Parameter (Mandatory= $true)]
  [string] $tagvalue


)
     
$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'

try 
{ 
Add-AzureRmAccount `
    -ServicePrincipal `
    -TenantId $ServicePrincipalConnection.TenantId `
    -ApplicationId $ServicePrincipalConnection.ApplicationId `
    -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
} 
catch { 
    if (!$servicePrincipalConnection) 
    { 
        $ErrorMessage = "Connection $connectionName not found." 
        throw $ErrorMessage 
    } else{ 
        Write-Error -Message $_.Exception 
        throw $_.Exception 
    } 
} 

#$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID
#Select-AzureRmSubscription -Subscription MFC-Global-Production-Internal-S1-CoreServices
#$tags = @{"update"="yes"} # more than one value of update

$SubscriptionArray = Get-AzureRmSubscription

ForEach ($vsub in $SubscriptionArray)
    {

	Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan 
        $NULL = Select-AzSubscription -SubscriptionId $($vsub.SubscriptionID)
$tagResList = Get-AzureRmResource -TagName "MaintenanceWindow" -TagValue $tagvalue

#$tagResList = Get-AzureRmResource -Tag $tags


foreach($tagRes in $tagResList) { 
		if($tagRes.ResourceId -match "Microsoft.Compute")
		{
			$vmInfo = Get-AzureRmVM -ResourceGroupName $tagRes.ResourceId.Split("//")[4] -Name $tagRes.ResourceId.Split("//")[8]

				#Set local variables
				$location = $vmInfo.Location
                #echo $location
				$resourceGroupName = $vmInfo.ResourceGroupName
                #echo $resourceGroupName
                $timestamp = Get-Date -f MM-dd-yyyy_HH_mm_ss

                #Snapshot name of OS data disk
                $snapshotName = $vmInfo.Name + $timestamp 
                #echo $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id

				#Create snapshot configuration
                $snapshot =  New-AzureRmSnapshotConfig -SourceUri $vmInfo.StorageProfile.OsDisk.ManagedDisk.Id -Location $location  -CreateOption copy
				
				#Take snapshot
                New-AzureRmSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName 
				
                
				if($vmInfo.StorageProfile.DataDisks.Count -ge 1){
						#Condition with more than one data disks
						for($i=0; $i -le $vmInfo.StorageProfile.DataDisks.Count - 1; $i++){
								
							#Snapshot name of OS data disk
							$snapshotName = $vmInfo.StorageProfile.DataDisks[$i].Name + $timestamp 
							
							#Create snapshot configuration
							$snapshot =  New-AzureRmSnapshotConfig -SourceUri $vmInfo.StorageProfile.DataDisks[$i].ManagedDisk.Id -Location $location  -CreateOption copy
							
							#Take snapshot
							New-AzureRmSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $resourceGroupName 
							
						}
					}
				else{
						Write-Host $vmInfo.Name + " doesn't have any additional data disk."
				}
		}
		else{
			$tagRes.ResourceId + " is not a compute instance"
		}
}
}
