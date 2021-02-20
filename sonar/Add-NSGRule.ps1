param(  
  [string]$ResourceGroupName,
  [string]$SubscriptionId,
  [string]$TenantId,
  [string]$NSGName,
  [string]$ServicePrincipalPassword,
  [string]$ServicePrincipalAppId
)

[string] $RuleName = "$Env:BUILD_BUILDID"

[int] $Priority = 150
Function Connect-ToAzure() {
  [CmdletBinding()]
  param(
    [string] $TenantId,
    [string] $SubscriptionId,
    [string] $ServicePrincipalPassword
  )
	
  try {
    $securepwd = ConvertTo-SecureString -String $ServicePrincipalPassword -AsPlainText -Force
    $mycreds = New-Object System.Management.Automation.PSCredential ("$ServicePrincipalAppId", $securepwd)

    #For Connecting to Linux
    Connect-AzAccount -ServicePrincipal -Credential $mycreds -Subscription $SubscriptionId -Tenant $TenantId
  }
  catch {
    Write-Host "Unexpected error while Logging to Azure Account"
  }
}

#Retrieve the existing NSG details
Function Get-ExistingNSG() {
  [CmdletBinding()]
  param(
    [string] $ResourceGroupName,
    [string] $NSGName
  )
	
  try {
    $nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName
    return $nsg
  }
  catch {
    Write-Host "Unexpected error while getting Existing NSG"
  }
}

#Save the changes to the NSG 
Function Set-ExistingNSG() {
  [CmdletBinding()]
  param(
    $nsgnm
  )
	
  try {
    $nsg = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $nsgnm 
    return $nsg
  }
  catch {
    Write-Host "Unexpected error while Setting NSG"
  }
}

#get available priority
Function Get-AvaialablePriority() {
  [CmdletBinding()]
  param(
    $NSGdetails
  )
	
  try {
    if ($NSGdetails.SecurityRules -and $NSGdetails.SecurityRules.Count -gt 1) {
      while ($true) {
        if ($NSGdetails.SecurityRules.Priority.Contains($Priority)) {
          $Priority++
        }
        else {
          break
        }
      }
    }
    else {
      if ($Priority -eq $NSGdetails.SecurityRules.Priority) {
        $Priority++
      }
    }
    
    return $Priority
  }
  catch {
    Write-Host "Unexpected error while getting available priority"
  }
}

#region add the NSG rules based on the agent name
Function Add-NSGRule($ResourceGroupName, $NSGName, $Priority, $RuleName) {
  #NSG rule name based on the agent name
  $NSGRuleName = $RuleName

  #Get public IP Address
  $IPAddress = Invoke-RestMethod "http://ipinfo.io/json" | Select-Object -ExpandProperty IP

  #Retrieve the existing NSG details
  $nsg = Get-ExistingNSG -ResourceGroupName $ResourceGroupName -NSGName $NSGName

  #get available priority
  $Priority = Get-AvaialablePriority -NSGdetails $nsg
    
  #region Add NSG Rule: Allow port 443 for $IPAddress
  $NSGRule = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $NSGRuleName -ErrorAction SilentlyContinue 
	
  if ($null -eq $NSGRule) {  
    $null = Add-AzureRmNetworkSecurityRuleConfig -Name $NSGRuleName -Protocol Tcp -SourcePortRange * -DestinationPortRange 443 -SourceAddressPrefix $IPAddress -DestinationAddressPrefix * -Access Allow -Priority $Priority -Direction Inbound -Description 'Allow IP Address' -NetworkSecurityGroup $nsg
  }
  else {
    $null = Remove-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name $NSGRuleName
    $null = Add-AzureRmNetworkSecurityRuleConfig -Name $NSGRuleName -Protocol Tcp -SourcePortRange * -DestinationPortRange 443 -SourceAddressPrefix $IPAddress -DestinationAddressPrefix * -Access Allow -Priority $Priority -Direction Inbound -Description 'Allow IP Address' -NetworkSecurityGroup $nsg 
  }
  #endregion

  #Save the changes to the NSG
  $null = Set-ExistingNSG -nsgnm $nsg 
}
#endregion

#For Connecting to Linux
Install-Module Az -Force
Import-Module Az
Enable-AzureRmAlias

Connect-ToAzure -TenantID $TenantID -SubscriptionId $SubscriptionId -ServicePrincipalPassword $ServicePrincipalPassword

Add-NSGRule -ResourceGroupName $ResourceGroupName -NSGName $NSGName -Priority $Priority -RuleName $RuleName

Start-Sleep -Seconds 300