#######################################################################################################
# Script: Get a list of all Subnets and associated NSGs within Virtual networks for all subscriptions- Azure
# Author: Ahmed Hussein - Microsoft 
# Date: April 2020
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

# define variables 
$CurrentDate = Get-Date -Format 'dd-MM-yyyy-HH-mm-ss'
$csvfilelistofsubnets = "ListofNSGs_$($CurrentDate).csv"
$Allsubnetdata=@()
$virtualNetworksinfo = @()

# Login to Azure - if already logged in, use existing credentials.

Write-Host "Authenticating to Azure..." -ForegroundColor Cyan

try
{
    $AzureLogin = Get-AzSubscription
}
catch
{
    $null = Login-AzAccount
    $AzureLogin = Get-AzSubscription
}
# Authenticate to Azure if not already authenticated 
If($AzureLogin)
{
    $SubscriptionArray = Get-AzSubscription
    write-host "You have " $SubscriptionArray.Count " subscriptions under your accounts" -ForegroundColor white
    ForEach ($vsub in $SubscriptionArray)
    {

        Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan
        $NULL = Select-AzSubscription -SubscriptionId $($vsub.SubscriptionID)
        $SubscriptionID = Get-AzSubscription -SubscriptionId $vsub.SubscriptionID | Select-Object SubscriptionId
        $NULL = Select-AzSubscription -SubscriptionId $($SubscriptionID.SubscriptionID)
        $virtualNetworksinfo = Get-AzVirtualNetwork | Select-Object name , resourcegroupname , Subnets , location
        foreach($vnet in $virtualNetworksinfo) 
        {
            Write-Host "Querying VirtualNetwork : $($vnet.Name) ..." -ForegroundColor Green
            $subnets = $vnet | Select-Object -ExpandProperty Subnets
            foreach ($subnet in $subnets) 
            {
                #$subnet | Select-Object Name , AddressPrefix,NetworkSecurityGroup
                $Allsubnetdata += New-Object PsObject -property @{
                    'Subscription' = $vsub.Name;
                    'VirtualNetworkName' = $vnet.Name;
                    'Location' = $vnet.Location;
                    'Subnet' = $subnet.Name;
                    'SubnetAddressSpace' = $subnet.AddressPrefix[0];
                    'SubnetNSG' = $subnet.NetworkSecurityGroup.id;
                     }
                    }
            }
            $Allsubnetdata  | Select-Object Subscription,VirtualNetworkName,Location,Subnet,SubnetAddressSpace, @{label="NSG_ID";expression = {$_.SubnetNSG.split('/')[8]}} | Export-Csv -Path $csvfilelistofsubnets -Append
            echo "`n"
            Write-Host "Done! " -ForegroundColor Green
            echo "`n"
        }
    }