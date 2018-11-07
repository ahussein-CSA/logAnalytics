#######################################################################################################
# Script: Enable AllMetrics and logs within a subscription to Workspace and remove any other diagnostic settings - Azure
# Author: Ahmed Hussein - Microsoft 
# Date: November 2018
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

$workspaceid = "yourworkspaceid"
$subid = "yoursubscriptionid"

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzureRmSubscription 
}
catch
{
    $null = Login-AzureRmAccount
    $AzureLogin = Get-AzureRmSubscription
}

# Authenticate to Azure if not already authenticated 
# Ensure this is the subscription where your Azure Resources are you want to send diagnostic data from
If($AzureLogin)
{
   
    $SubscriptionID = Get-AzureRmSubscription -SubscriptionId $subid | Select-Object SubscriptionId

    # Get Subscriptions under the logged in account
        $ResourcesToCheck = @()
        $getnameofdiagnosticsettings = @()
        Write-Host "Selecting Azure Subscription: $($SubscriptionID.SubscriptionID) ..." -ForegroundColor Cyan
        $NULL = Select-AzureRmSubscription -SubscriptionId $($SubscriptionID.SubscriptionID)
        $ResourcesToCheck = Get-AzureRmResource | select-object ResourceId, ResourceType
        write-host "number of resources " $ResourcesToCheck.Count
        
        foreach ($resource in $ResourcesToCheck)
        {

        $resourceidtoenable = $resource.ResourceId
        
            
                    $getnameofdiagnosticsettings = Get-AzureRmDiagnosticSetting -ResourceId "$($resourceidtoenable)" | select-object Name

                    foreach($diagtoremove in $getnameofdiagnosticsettings)
                    {
                        #Remove-AzureRmDiagnosticSetting -ResourceId "$($resourceidtoenable)" -Name $diagtoremove.Name
                        Set-AzureRmDiagnosticSetting -ResourceId "$($resourceidtoenable)" -Name $diagtoremove.Name -Enabled $false
                    }
                    
                    #write-host $resource.ResourceType.Split("/")[-1]

                    if ($resource.ResourceType.Split("/")[-1] -eq "networkSecurityGroups")
                    {
                        Set-AzureRmDiagnosticSetting -Name "ServiceLogs" -ResourceId "$($resourceidtoenable)" -WorkspaceId "$($workspaceid)" -Enabled $True -Categories "NetworkSecurityGroupEvent","NetworkSecurityGroupRuleCounter"
                    }

                    Set-AzureRmDiagnosticSetting -Name "ServiceMetrics" -ResourceId "$($resourceidtoenable)" -WorkspaceId "$($workspaceid)" -Enabled $True -MetricCategory "AllMetrics"
                    $setting = Get-AzureRmDiagnosticSetting -ResourceId "$($resourceidtoenable)"
                    
                    if ($setting.Logs) 
                        { 
                            $Categories = $setting.Logs.category

                            foreach ($cat in $categories) 
                            
                            {

                                write-host $cat
                                
                                Set-AzureRmDiagnosticSetting -Name "ServiceLogs" -ResourceId "$($resourceidtoenable)" -Enabled $True -Categories $cat



                            }
                        
                        }
                   
                
          

        }
        
 


}


