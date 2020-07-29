#######################################################################################################
# Script: Turn on VMs that are powered off and keep their info into an automation account variable- Azure
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
  
$variableName = "vmListId-" + $tagvalue #variablename in automation account
$automationAccount = <<yourAutomationaccountName>
$resourceGroup = <Resourcegroupofyourautomationaccount>

#$ServicePrincipalConnection = Get-AzAutomationConnection -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount -Name 'AzureRunAsConnection'
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

$updatedMachines = @()
$startableStates = "stopped" , "stopping", "deallocated", "deallocating"
$jobIDs= New-Object System.Collections.Generic.List[System.Object]

New-AzureRmAutomationVariable -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount -Name $variableName -Value "" -Encrypted $false

#Parse the list of VMs and start those which are stopped
#Azure VMs are expressed by:
# subscription/$subscriptionID/resourcegroups/$resourceGroup/providers/microsoft.compute/virtualmachines/$name

# <Tagname> this is your tagname hardcoded, for example maintenance is the tagname, value is being captured from parameter input when running the automation account as an adhoc
# $vmIds = Get-AzureRmVM | where {$_.Tags['maintenance'] -eq $tagvalue} 

$vmIds = Get-AzureRmVM | where {$_.Tags['<Tagname>'] -eq $tagvalue} 

Write-Output "checking the list"
Write-Output $vmIds

if (!$vmIds) 
{
    
        Write-Output "No Azure VMs found"
        return

}

foreach ($vmid in $vmIds)
{

    $split = $vmid.Id -split "/";
    $subscriptionId = $split[2]; 
   
    $rg = $split[4];
     Write-Output ("the Resource group is: " + $rg)
    $name = $vmid.name;
    Write-Output ("the name is: " + $name)
    Write-Output ("Subscription Id: " + $subscriptionId)
    $mute = Select-AzureRmSubscription -Subscription $subscriptionId

    $vm = Get-AzureRmVM -ResourceGroupName $rg -Name $name -Status 
    #$vm = Get-AzureRmVM -ResourceGroupName "RESERVEPROXYTEST-RG" -Name "linuxpocdemo" -Status

Write-Output ("the VMS are " + $vm)
    #Query the state of the VM to see if it's already running or if it's already started
    $state = ($vm.Statuses[1].DisplayStatus -split " ")[1]
    Write-Output $state
    if($state -in $startableStates) {
        Write-Output "Starting '$($name)' ..."
        #Store the VM we started so we remember to shut it down later
        $updatedMachines += $vmid.Id
        $newJob = Start-ThreadJob -ScriptBlock { param($resource, $vmname) Start-AzureRmVM -ResourceGroupName $resource -Name $vmname} -ArgumentList $rg,$name
        $jobIDs.Add($newJob.Id)
    }else {
        Write-Output ($name + ": no action taken. State: " + $state) 
    }
}


$updatedMachinesCommaSeperated = $updatedMachines -join ","

#Wait until all machines have finished starting before proceeding to the Update Deployment
$jobsList = $jobIDs.ToArray()
if ($jobsList)
{
    Write-Output "Waiting for machines to finish starting..."
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

Write-output $updatedMachinesCommaSeperated
#Store output in the automation variable
#Set-AutomationVariable -Name $runId -Value $updatedMachinesCommaSeperated

Set-AzureRmAutomationVariable -AutomationAccountName $automationAccount -Name $variableName -ResourceGroupName $resourceGroup -Value $updatedMachinesCommaSeperated -Encrypted $False
