#
# Remove_NSGRules.ps1
#
param(  
  [string]$ResourceGroupName,
  [string]$SubscriptionId,
  [string]$TenantId,
  [string]$NSGName,
  [string]$ServicePrincipalPassword,
  [string]$ServicePrincipalAppId
)

[string] $RuleName = "$Env:BUILD_BUILDID"

Function Connect-ToAzure() {
  [CmdletBinding()]
  param(
  	[string] $TenantId,
  	[string] $SubscriptionId,
  	[string] $ServicePrincipalPassword
  )
  
  try {
  	$securepwd=ConvertTo-SecureString -String $ServicePrincipalPassword -AsPlainText -Force
  	$mycreds = New-Object System.Management.Automation.PSCredential ("$ServicePrincipalAppId", $securepwd)  
    
    #For Connecting to Linux
    Connect-AzAccount -ServicePrincipal -Credential $mycreds -Subscription $SubscriptionId -Tenant $TenantId
  }
  catch {
  	Write-Host "Unexpected error while Logging to Azure Account"
  }
}

Function Remove-NSGRule($ResourceGroupName, $NSGName, $AgentName) {
  #Retrieve the existing NSG details
  $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName
  
  #Remove NSG Rule from NSG
  $null = Remove-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $AgentName -ErrorAction SilentlyContinue
  
  #Save the changes to the NSG 
  $null = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsg -ErrorAction SilentlyContinue
}

#For Linux env
Install-Module Az -Force
Import-Module Az
Enable-AzureRmAlias

Connect-ToAzure -TenantID $TenantID -SubscriptionId $SubscriptionId -ServicePrincipalPassword $ServicePrincipalPassword
#region add the NSG rules based on the agent name's last 2 digit
Remove-NSGRule -ResourceGroupName $ResourceGroupName -NSGName $NSGName -AgentName "$RuleName"
#endregion