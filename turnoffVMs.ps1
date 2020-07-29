#######################################################################################################
# Script: Turn off previously turned on VMs where their info is kept on a variable an automation account- Azure
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
  [string] $variablenameinput  # variable name as an input


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

$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID

$variableName = $variablenameinput
$automationAccount = <automationaccountname>
$resourceGroup = <resourcegroupautomationaccount>


$variable = Get-AzureRmAutomationVariable -AutomationAccountName $automationAccount -Name $variableName -ResourceGroupName $resourceGroup

if (!$variable) 
{
    Write-Output "No machines to turn off"
    return
}

Write-Output ("the Variable is" + $variable)
$vmIds = $variable.value -split ","
Write-Output ("the VMIDs is" + $vmIds)
$stoppableStates = "starting", "running"
$jobIDs= New-Object System.Collections.Generic.List[System.Object]

foreach ($vmid in $vmIds)
{
     $split = $vmid -split "/";
     Write-Output ("split is: " + $split)
    $subscriptionId = $split[2]; 
   
    $rg = $split[4];
    Write-Output ("the Resource group is: " + $rg)
    $name = $split[8];
    Write-Output ("the name is: " + $name)
    Write-Output ("Subscription Id: " + $subscriptionId)

    $mute = Select-AzureRmSubscription -Subscription $subscriptionId

    $vm = Get-AzureRmVM -ResourceGroupName $rg -Name $name -Status 

    $state = ($vm.Statuses[1].DisplayStatus -split " ")[1]
    if($state -in $stoppableStates) {
        Write-Output "Stopping '$($name)' ..."
        $newJob = Start-ThreadJob -ScriptBlock { param($resource, $vmname) Stop-AzureRmVM -ResourceGroupName $resource -Name $vmname -Force} -ArgumentList $rg,$name 
        $jobIDs.Add($newJob.Id)
    }else {
        Write-Output ($name + ": already stopped. State: " + $state) 
    }
}
#Wait for all machines to finish stopping so we can include the results as part of the Update Deployment
$jobsList = $jobIDs.ToArray()
if ($jobsList)
{
    Write-Output "Waiting for machines to finish stopping..."
    Wait-Job -Id $jobsList
}

foreach($id in $jobsList)
{
    $job = Get-Job -Id $id
    if ($job.Error)
    {
        Write-Output $job.Error
    }
}
#Clean up our variables:
Remove-AzureRmAutomationVariable -AutomationAccountName $automationAccount -ResourceGroupName $resourceGroup -name $variableName
