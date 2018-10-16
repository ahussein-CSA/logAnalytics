#######################################################################################################
# Script: Export a list of VMs within specific period to match certain criteria for all subscription for the account used - Azure
# Author: Ahmed Hussein - Microsoft 
# Date: October 2018
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
$CurrentDate = Get-Date -uformat "%m_%d_%Y"
$csvfile = "Yourfilenameandpath_$($CurrentDate).csv"  # ie. C:\data\file.csv --> this will print all the VMs within the period specified
$csvfile1 = "Yourfilenameandpath_$($CurrentDate).csv"  # ie. C:\data\file1.csv --> this will print all the VMs within the period specified with a name that match $vmname
$csvfile2 = "Yourfilenameandpath_$($CurrentDate).csv"  # ie. C:\data\file2.csv --> this will print all the VMs within the period specified with a tag that matches the tag key and value($nameoftag, $valueoftag)
$nameoftag = "the tag key in here" # "chefmanaged"
$valueoftag ="the tag value in here" # value of the tag
$vmname = "the virtual machine name" # vmname
$nofdays = "-30" # please note the value must have the - sign (i.e for one month ago use -30) 
$AllVMswithinaperiod=@()
$AllVmswithinaperiodwithnamematch=@()
$AllVMswithmatchedtags=@()
[array]$ResourcesToCheckGeneral = @()
$Summary = @()
Clear-Variable ResourcesToCheckGeneral -Scope Script



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
    $SubscriptionArray = Get-AzureRmSubscription
    write-host "You have " $SubscriptionArray.Count " subscriptions under your accounts" -ForegroundColor white
    # Get Subscriptions under the logged in account
    
    ForEach ($vsub in $SubscriptionArray)
    {
        Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan 
        $NULL = Select-AzureRmSubscription -SubscriptionId $($vsub.SubscriptionID)
        


        # get all VMs built in the last month
        
        $ResourcesToCheckGeneral= Get-AzureRmLog -StartTime (Get-Date).AddDays($nofdays) -EA SilentlyContinue | Where-Object {$_.Authorization.Action -eq 'Microsoft.Compute/virtualMachines/write'} | Select-Object {$_.ResourceGroupName} , {($_.ResourceId).Split("/")[-1]} -Unique 
        
        If (($ResourcesToCheckGeneral.Count) -eq 0) 
        {

            write-host "No VMs were built at the specified period under this subscription $($vsub.SubscriptionID)"
        

        }

        else 
        {
            write-host "number of VMs that were built  $($nofdays) days ago under this Subscritpion is " $ResourcesToCheckGeneral.Count "`n"
            #$ResourcesToCheckGeneral
            foreach ($item in $ResourcesToCheckGeneral)
                {
                    $AllVMswithinaperiod += New-Object PsObject -property @{
                    'VMname' = $item.{($_.ResourceId).Split("/")[-1]}
                    'ResourceGroupName' = $item.{$_.ResourceGroupName}
                    #'EventTimeStamp' = $item.{$_.EventTimestamp}
                    }

                   
                }

                #get VMs with Matched tags

                # get VMs that their tags match certain tag (key,value) within the same period

                # get the tag value of a tag KEy for specific VM and compare if it is PCF

                foreach ($vm in $ResourcesToCheckGeneral) {
                    $VMis = Get-AzureRmVM -ResourceGroupName $vm.{$_.ResourceGroupName} -Name $vm.{($_.ResourceId).Split("/")[-1]} | Where-Object { $_.Tags[$nameoftag] -eq $valueoftag }
                    $VMis.Count
                    if (($VMis.Count) -eq 1) {
                
                        $AllVMswithmatchedtags+= New-Object PsObject -property @{
                            'VMname' = $vm.{($_.ResourceId).Split("/")[-1]}
                            'ResourceGroupName'=$vm.{$_.ResourceGroupName}
                        }
                
                    }
                }

        }
        Clear-variable -Name ResourcesToCheckGeneral  -Scope Script
    

    }
    $AllVMswithinaperiod | Export-Csv -Path $csvfile -Append
    # Get VMs that match certain name within the same period
    $AllVmswithinaperiodwithnamematch = $AllVMswithinaperiod | Where-Object VMname -Match $vmname | Select-Object VMname , ResourceGroupName , EventTimeStamp
    
    write-host "number of VMs that were built  $($nofdays) days ago under all subscriptions and match the name $($vmname) is " $AllVmswithinaperiodwithnamematch.Count "`n"
    $AllVmswithinaperiodwithnamematch | Export-Csv -Path $csvfile1 -Append

     


    $AllVMswithmatchedtags |  Export-Csv -Path $csvfile2 -Append

    # Construct Summary
    $Summary+= New-Object PsObject -property @{
        'AllVMs' = $AllVMswithinaperiod.Count
        'ALLVMsmatchAname' = $AllVmswithinaperiodwithnamematch.Count
        'ALLVMsmatchAtag' = $AllVMswithmatchedtags.Count

    }

        $Summary | Select-Object AllVms , AllVMsmatchAname , ALLVMsmatchAtag | ft

        
    

}
