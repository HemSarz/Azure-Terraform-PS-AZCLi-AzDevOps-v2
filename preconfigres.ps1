# Set the resource variables
$backend_spn = "tfazinfra"
$backend_spn_role = "Contributor"
$backend_rg = "backend-tf-rg"
$backend_stg = "backendstgtf"
$backend_stg_sku = "Standard_LRS"
$backend_cont = "backendcont"
$backend_location = "norwayeast"
$backendAzureRmKey = "terraform.tfstate"

# Key Vault variables
$backend_kv = "bcknd-kvsc-tfaz"

# Key Vault Secret Names
$backend_AZDOSrvConnName_kv_sc = "AZDONamec"
$backend_RGName_kv_sc = "RGName"
$backend_STGPass_Name_kv_sc = "STGNamec"
$backend_ContName_kv_sc = "ContName"
$backendAzureRmKey_kv_sc = "TFStatefileName"
$backend_SUBid_Name_kv_sc = "SUBidName"
$backend_TNTid_Name_kv_sc = "TNTidName"
$backend_STGPass_Name_kv_sc = "STGPass"
$backend_SPNPass_Name_kv_sc = "SPNPass"

# Set the Azure DevOps organization and project details
$backend_org = "https://dev.azure.com/tfazlab"
$backend_project = "tfazlab"
$backend_pat = "ftyhdbvr2xjqnp5345hl3vxaqbkb7aueobbsfhs7fbct66ufw2fq"

# Set the variable group details
$backend_VBGroup = "hawaVB"
$description = "backendVB"

# Azure DevOps Connection variables
$backend_AZDOSrvConnName = "azdo-tfaz-conn"

# Repository name
$backend_RepoName = "tfazlab"

Write-Host "Creating service principal..." -ForegroundColor Yellow
$backend_SPNPass = $(az ad sp create-for-rbac --name $backend_spn --role $backend_spn_role --scopes /subscriptions/64208b73-267b-43b1-9bb1-649f128147e6 --query 'password' -o tsv)

Start-Sleep -Seconds 2

Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $backend_rg --location $backend_location

Write-Host "Creating storage account..." -ForegroundColor Yellow
az storage account create --resource-group $backend_rg --name $backend_stg --sku $backend_stg_sku --encryption-services blob

Start-Sleep -Seconds 2

Write-Host "Retrieving storage account access key..." -ForegroundColor Yellow
$backend_STGPass = $(az storage account keys list --resource-group $backend_rg --account-name $backend_stg --query "[0].value" -o tsv)

Start-Sleep -Seconds 2

Write-Host "Creating storage container..." -ForegroundColor Yellow
az storage container create --name $backend_cont --account-name $backend_stg --account-key $backend_STGPass

Start-Sleep -Seconds 5

Write-Host "Creating the Key Vault..." -ForegroundColor Yellow
az keyvault create --resource-group $backend_rg --name $backend_kv --location $backend_location

Start-Sleep -Seconds 2

Write-Host "Allowing the Service Principal Access to Key Vault..." -ForegroundColor Yellow
$backend_SPNAppID = $(az ad sp list --display-name $backend_spn --query '[0].appId' -o tsv)
$backend_SPNid = $(az ad sp show --id $backend_SPNAppID --query id -o tsv)
az keyvault set-policy --name $backend_kv --object-id $backend_SPNid --secret-permissions get list

Start-Sleep -Seconds 2

$backend_SUBid = $(az account show --query 'id' -o tsv)
$backend_SUBName = $(az account show --query 'name' -o tsv)
$backend_TNTid = $(az account show --query 'tenantId' -o tsv)

Start-Sleep -Seconds 2

Write-Host -ForegroundColor Yellow "Setting Azure DevOps Service Connection Name secret..."
az keyvault secret set --vault-name $backend_kv --name $backend_AZDOSrvConnName_kv_sc --value $backend_AZDOSrvConnName

Write-Host -ForegroundColor Yellow "Setting Resource Group Name secret..."
az keyvault secret set --vault-name $backend_kv --name $backend_RGName_kv_sc --value $backend_rg

Write-Host -ForegroundColor Yellow "Setting Storage Account Password secret..."
az keyvault secret set --vault-name $backend_kv --name $backend_STGPass_Name_kv_sc --value $backend_stg

Write-Host -ForegroundColor Yellow "Setting Container Name secret..."
az keyvault secret set --vault-name $backend_kv --name $backend_ContName_kv_sc --value $backend_cont

Write-Host -ForegroundColor Yellow "Setting Azure Resource Manager Key secret..."
az keyvault secret set --vault-name $backend_kv --name $backendAzureRmKey_kv_sc --value $backendAzureRmKey

Write-Host -ForegroundColor Yellow "Setting Subscription ID secret..."
az keyvault secret set --vault-name $backend_kv --name $backend_SUBid_Name_kv_sc --value $backend_SUBid

Write-Host -ForegroundColor Yellow "Setting Tenant ID secret..."
az keyvault secret set --vault-name $backend_kv --name $backend_TNTid_Name_kv_sc --value $backend_TNTid

Write-Host -ForegroundColor Yellow "Adding the Storage Account Access Key to Key Vault..."
az keyvault secret set --vault-name $backend_kv --name $backend_STGPass_Name_kv_sc --value $backend_STGPass

Write-Host -ForegroundColor Yellow "Adding the Service Principal Password to Key Vault..."
az keyvault secret set --vault-name $backend_kv --name $backend_SPNPass_Name_kv_sc --value $backend_SPNPass

################################################################################

# Set Service Principal Secret as an Environment Variable for creating Azure DevOps Service Connection
$env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY = $backend_SPNPass

# Set PAT as an environment variable for DevOps Login
$env:AZURE_DEVOPS_EXT_PAT = $backend_pat

Write-Host "Creating Azure DevOps service endpoint..." -ForegroundColor Yellow

# Set Default DevOps Organisation and Project
az devops configure --defaults organization=$backend_org --verbose
az devops configure --defaults project=$backend_project --verbose

# Create DevOps Service Connection
az devops service-endpoint azurerm create --azure-rm-service-principal-id $backend_SPNAppID --azure-rm-subscription-id $backend_SUBid --azure-rm-subscription-name $backend_SUBName --azure-rm-tenant-id $backend_TNTid --name $backend_AZDOSrvConnName --org $backend_org --project $backend_project

Start-Sleep -Seconds 5

Write-Host "Creating the variable group..." -ForegroundColor Yellow

az pipelines variable-group create --organization $backend_org --project $backend_project --name $backend_VBGroup --description $description --variables foo=bar
$backend_VBGroupID = $(az pipelines variable-group list --organization $backend_org --project $backend_project --query "[?name=='$backend_VBGroup'].id" -o tsv)

# Update the variable group to link it to Azure Key Vault
az pipelines variable-group update --id $backend_VBGroupID --org $backend_org --project $backend_project --reference-name $backend_kv --reference-type "azureKeyVault" --authorize true

Start-Sleep -Seconds 5

Write-Host "Linking the Key Vault reference to the variable group..." -ForegroundColor Yellow

az keyvault secret list --vault-name $backend_kv --query "[].{name:name, value:attributes.secretValue}" -o json | ConvertFrom-Json | ForEach-Object {
    $name = $_.name
    $value = $_.value
    az pipelines variable-group variable create --group-id $backend_VBGroupID --name $name --value $value --secret true
}

Write-Host "Creating pipeline for tfazlab project..." -ForegroundColor Yellow
az pipelines create --name 'TFazInfraPipe' --description 'Pipeline for tfazlab project' --detect false --repository $backend_RepoName --branch main --yml-path tfazbuild.yml --repository-type tfsgit --skip-first-run true

Write-Host "Allowing AZDO ACCESS..." -ForegroundColor Yellow
# Grant Access to all Pipelines to the Newly Created DevOps Service Connection

$backend_EndPid = az devops service-endpoint list --query "[?name=='$backend_AZDOSrvConnName'].id" -o tsv
az devops service-endpoint update --detect false --id $backend_EndPid --enable-for-all true --verbose

Write-Host "Done!" -ForegroundColor Green