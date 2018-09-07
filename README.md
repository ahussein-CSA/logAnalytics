#########################################################################################

Script: gather all enabled logs for resources within subscriptions belonging to an account - Azure

Author: Ahmed Hussein - Microsoft

Date: August 2018

Version: 1.0

[References](https://www.powershellgallery.com/packages/Enable-AzureRMDiagnostics/2.52/DisplayScript)

THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
IN NO EVENT SHALL MICROSOFT AND/OR ITS RESPECTIVE SUPPLIERS BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS CODE OR INFORMATION.

#########################################################################################

## What does the powershell script "forscotiasimple-automated-Final.ps1" do ?

The scripts loop through all the subscriptions that belong to the account being singed in to Azure , pull all the resources under each subscription 
determine if the resource has metrics and logs , then export the logs that can be captured by log analytics to a csv file , and present another file
where it shows which resource has support for both logs and metrics. the script is built upon some concepts mentioned in this [powershell script](https://www.powershellgallery.com/packages/Enable-AzureRMDiagnostics/2.52/DisplayScript) 

### Pre-requisites:

Please login first to Azure using the powershell command, then run the script

## Variables

```
$csvfile = "CSV file to push the logs supported for each resource"  # ie. C:\data\file.csv
$csvfileanalysis = "CSV file to indicate which resource can have metrics/logs"  # ie. C:\data\file2.csv

```




