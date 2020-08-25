#######################################################################################################
# Script: run command on Azure VMs as part of automation account- using Rest APIs- Azure
# Author: Ahmed Hussein - Microsoft 
# Date: August 2020
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


$AzureContext = Select-AzureRmSubscription -SubscriptionId $ServicePrincipalConnection.SubscriptionID

$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($AzureContext.Subscription.TenantId)
$authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}

$SubscriptionArray = Get-AzureRmSubscription
ForEach ($vsub in $SubscriptionArray)
    {

      Write-Host "Selecting Azure Subscription: $($vsub.SubscriptionID) ..." -ForegroundColor Cyan 
      $NULL = Select-AzSubscription -SubscriptionId $($vsub.SubscriptionID)

      $vmIds = Get-AzureRmVM | where {$_.Tags['<Tagname>'] -eq $tagvalue} 

      Write-Output "checking the list"
      Write-Output $vmIds

      if (!$vmIds) 
      {

              Write-Output "No Azure VMs found"
              continue

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
            # Invoke the REST API
            $restUri = 'https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/$name/runCommand?api-version=2017-03-30'
            $body = @{
                'commandId' = 'RunShellScript'
              'script' = @('ps -aux')
            }
            $response = Invoke-webrequest -Uri $restUri -Method Post -UseBasicParsing -Headers $authHeader -Body $($body | ConvertTo-Json)

            $asyncstatus = $($response.headers.'Azure-AsyncOperation')
            $status = "InProgress"
            While($status -eq "InProgress")`
            {
            Write-Output "Status: $status"
            $response = invoke-webrequest -uri $asyncstatus -Headers $authHeader -UseBasicParsing
            $status = $($response.Content | ConvertFrom-Json).status -eq "InProgress"
            sleep 5
            }
            Write-Output $($response.Content | ConvertFrom-Json).properties.output.message

    }
  }
