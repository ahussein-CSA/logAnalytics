#######################################################################################################################
# Script: Export a list of VMs Connected to workspace for all or single subscription for the account used - Azure to a .csv file
# Author: Ahmed Hussein - Microsoft 
# Date: January 2020
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
$csvfilelistofVMs = "ListofVMs_$($CurrentDate).csv"
$AllVMSwithinaworkspace=@()
$ResourcesToCheckGeneral = @()
 
# null means get the required for all the subscription the user has access to , other wise replace null with a sepcific subscription id
$subscriptionid ="null"

Clear-Variable ResourcesToCheckGeneral -Scope Script

# Login to Azure - if already logged in, use existing credentials.
Write-Host "Authenticating to Azure..." -ForegroundColor Cyan
try
{
    $AzureLogin = Get-AzureRMSubscription
}
catch
{
    $null = Login-Azureccount
    $AzureLogin = Get-AzureRmSubscription
}

# Authenticate to Azure if not already authenticated 
# Ensure this is the subscription where your Azure Resources are you want to send diagnostic data from
If($AzureLogin)
{
    # check for single subscription , if not get for all subscriptions
    if ($subscriptionid -eq "null") {
    $SubscriptionArray = Get-AzureRmSubscription
    }
    else {
        $SubscriptionArray = Get-AzureRmSubscription -subscriptionid $subscriptionid
    }
    write-host "You have " $SubscriptionArray.Count " subscriptions under your accounts" -ForegroundColor white
    # Get Subscriptions under the logged in account
    
    ForEach ($vsub in $SubscriptionArray)
    {
        Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan 
        $NULL = Select-AzSubscription -SubscriptionId $($vsub.SubscriptionID)
        


        # get all workspaces within the subscription
        
        $ResourcesToCheckGeneral= Get-AzOperationalInsightsWorkspace

        If (($ResourcesToCheckGeneral.Count) -eq 0) 
        {

            write-host "No workspaces exist under this subscription $($vsub.SubscriptionID)"
        

        }

        else 
        {
            write-host "number of workspaces under this Subscritpion is " $ResourcesToCheckGeneral.Count "`n"
            Write-Host "Gathering VMs and adding them to the array..." -ForegroundColor Yellow 
            foreach ($item in $ResourcesToCheckGeneral)
                {
                    $workspacename=$item.Name
                    $workspaceRG= $item.ResourceGroupName
                    $workspace= Get-AzOperationalInsightsWorkspace -ResourceGroupName $workspaceRG -Name $workspacename
                    $QueryResults = Invoke-AzOperationalInsightsQuery -Workspace $Workspace -Query 'Heartbeat | where Category == "Direct Agent" | distinct Computer'
                    foreach ($itemm in $QueryResults.Results) {
                    $AllVMSwithinaworkspace += New-Object PsObject -property @{
                    'WorkspaceName' = $item.Name;
                    'VMname' = $itemm.Computer;
                    'Subscription' = $vsub.Name }
                    }

                   
                }



        }
        Clear-variable -Name ResourcesToCheckGeneral  -Scope Script
    

    }

    $AllVMSwithinaworkspace | Select-Object "Subscription", "WorkSpaceName", "VMname" |Export-Csv -Path $csvfilelistofVMs -Append
    echo "`n"
    Write-Host "Done! " -ForegroundColor Green
    echo "`n"
    
    }
