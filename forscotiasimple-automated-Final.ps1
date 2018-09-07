
#######################################################################################################
# Script: Export a list of logs for each resources within a subscription - Azure
# Author: Ahmed Hussein - Microsoft 
# Date: August 2018
# Version: 1.0
# References: https://www.powershellgallery.com/packages/Enable-AzureRMDiagnostics/2.52/DisplayScript
# GitHub: Coming
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

$csvfile = "C:\ScotiaBank\filescotia2.csv"  # ie. C:\data\file.csv
$csvfileanalysis = "C:\ScotiaBank\filescotia3.csv"  # ie. C:\data\file2.csv

# capturing resource types and checking their logging cabapilities.
function Get-ResourceType (
    [Parameter(Mandatory=$True)]
    [array]$allResources
    )
{
    $analysis = @()
    $outarray = @()
    
    foreach($resource in $allResources)
    {
        $Categories =@();
        $metrics = $false #initialize metrics flag to $false
        $logs = $false #initialize logs flag to $false
    
        if (! $analysis.where({$_.ResourceType -eq $resource.ResourceType}))
        {
            try
            {
                Write-Verbose "Checking $($resource.ResourceType)"
                $setting = Get-AzureRmDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction Stop
                # If logs are supported or metrics on each resource, set value as $True
                if ($setting.Logs) 
                { 
                    $logs = $true
                    $Categories = $setting.Logs.category   
                   
                    foreach ($cat in $categories) {

                     
                        $outarray += New-Object PsObject -property @{'resourcetype'= $resource.ResourceType ; 'log' = $cat }


                    }
                    # debugging outputs
                    write-host $outarray
                    # write-host "Resource is: " $resource.ResourceType  
                    # write-host "Category is: " $Categories
              

                  
                }


                if ($setting.Metrics) 
                { 
                    $metrics = $true
                   # Get-AzureRmMetric -ResourceId $resource.ResourceId
                   # $metricss = $setting.Metrics.Name
                   # write-host "Metrics are: " $metricss

                }   
                
            }
            catch {}
            finally
            {
                $object = New-Object -TypeName PSObject -Property @{'ResourceType' = $resource.ResourceType; 'Metrics' = $metrics; 'Logs' = $logs; 'Categories' = $Categories}
                $analysis += $object
                
               
                
            }
        }
        
    }
    # Return the list of supported resources
    
    
    $outarray | select-object -property ResourceType, log | Export-Csv -Path $csvfile -Append   
    # request to export another CSV for different view
    $analysis  
    $analysis | select-object -property ResourceType, Metrics , Logs | Export-Csv -Path $csvfileanalysis -Append   



}

# create an array of items
function Add-IndexNumberToArray (
    [Parameter(Mandatory=$True)]
    [array]$array
    )
{
    for($i=0; $i -lt $array.Count; $i++) 
    { 
        Add-Member -InputObject $array[$i] -Name "#" -Value ($i+1) -MemberType NoteProperty 
    }
    $array
}

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
        [array]$ResourcesToCheck = @()
        [array]$DiagnosticCapable=@()

        # get resources within this subscriptions.

        $ResourcesToCheck = Get-AzureRmResource

        write-host "number of resources " $ResourcesToCheck.Count

        
        Write-Host "Gathering a list of monitorable Resource Types from Azure Subscription ID " -NoNewline -ForegroundColor Cyan
        Write-Host "$($vsub.SubscriptionID)..." -ForegroundColor Yellow
        try
            {
                $DiagnosticCapable = Add-IndexNumberToArray (Get-ResourceType $ResourcesToCheck).where({$_.metrics -eq $True -or $_.Logs -eq $True})
                [int]$ResourceTypeToProcess = 0
                Write-Host "diagnostic cabalble : " $DiagnosticCapable.Count
                while($ResourceTypeToProcess -lt 1)
                {
                    $DiagnosticCapable | Select-Object "#", ResourceType, Metrics, Logs |Format-Table
                    $ResourceTypeToProcess = $ResourceTypeToProcess + 1
                }
                
            }
        catch
            {
                Throw "No diagnostic capable resources available in selected subscription $($vsub.SubscriptionID)"
            }
        


    }


}