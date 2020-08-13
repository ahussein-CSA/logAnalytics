#######################################################################################################
# Script: Delete Snapshots older than certain days and with certain tags- Azure
# Author: Ahmed Hussein - Microsoft 
# Date: July 2020
# Version: 1.0
# References: 
# GitHub: 
#
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


$SubscriptionArray = Get-AzureRmSubscription

ForEach ($vsub in $SubscriptionArray)
    {
        Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan 
        $NULL = Select-AzSubscription -SubscriptionId $($vsub.SubscriptionID)

        $snapshots = Get-AzSnapshot | ?{($_.TimeCreated).ToString('yyyyMMdd') -lt ([datetime]::Today.AddDays(-7).tostring('yyyyMMdd'))} | where {$_.Tags['MaintenanceWindow'] -eq $tagvalue} | select-object name, resourcegroupname, tags

        foreach($snapshotInfo in $snapshots)

            {   
                $snapshotrg = $snapshotInfo.resourcegroupname
                $snapshotname = $snapshotInfo.name
                Remove-AzSnapshot -ResourceGroupName  $snapshotrg -SnapshotName $snapshotname -Force

            }

  
    }