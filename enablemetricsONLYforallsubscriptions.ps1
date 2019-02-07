#######################################################################################################
# Script: Enable AllMetrics for all subscriptions under the current account to Workspace and remove any other diagnostic settings - Azure
# Author: Ahmed Hussein - Microsoft 
# Date: Feb 2019
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


$workspaceid = "<workspaceid>"


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


If($AzureLogin)

{
    $SubscriptionArray = Get-AzureRmSubscription

    write-host "You have " $SubscriptionArray.Count " subscriptions under your accounts" -ForegroundColor white


    ForEach ($vsub in $SubscriptionArray)

    {

        Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan

        $NULL = Select-AzureRmSubscription -SubscriptionId $($vsub.SubscriptionID)

        $SubscriptionID = Get-AzureRmSubscription -SubscriptionId $vsub.SubscriptionID | Select-Object SubscriptionId


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
                 
                    write-host $resource.ResourceType.Split("/")[-1]


                    Set-AzureRmDiagnosticSetting -Name "ServiceMetrics" -ResourceId "$($resourceidtoenable)" -WorkspaceId "$($workspaceid)" -Enabled $True -MetricCategory "AllMetrics"

        }
    }


        

}

