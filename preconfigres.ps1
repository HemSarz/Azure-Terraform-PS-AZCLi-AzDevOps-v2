# Set the resource variables
$backend_spn = "tfazinfra"
$backend_spn_role = "Contributor"
$backend_rg = "backend-tf-rg"
$backend_stg = "backendstgtf"
$backend_stg_sku = "Standard_LRS"
$backend_cont = "backendcont"
$backend_location = "norwayeast"
$backendAzureRmKey = "terraform.tfstate"

# SPN | Permissions VB
$MSGraphApi = "00000003-0000-0000-c000-000000000000" # MS Graph API Id
$appDirRoleId = "19dbc75e-c2e2-444c-a770-ec69d8559fc7=Role" # Directory.ReadWrite.All | Not allowed in delete Users
$appUsrRoleId = "df021288-bdef-4463-88db-98f22de89214=Role" # User.Read.All | Allowed in delete Users [Terraform Destroy]
#$scope = "Directory.ReadWrite.All"

# Key Vault variables | Generate a random number between 1 and 999
$randomNumber = Get-Random -Minimum 1 -Maximum 999
# Create the backend_kv variable with a random name
$backend_kv = "backend-tfaz-kv$('{0:D3}' -f $randomNumber)"

# Key Vault Secret Names
$backend_AZDOSrvConnName_kv_sc = "AZDOName"
$backend_RGName_kv_sc = "RGName"
$backend_STGName_kv_sc = "STGName"
$backend_ContName_kv_sc = "ContName"
$backendAzureRmKey_kv_sc = "TFStatefileName"
$backend_SUBid_Name_kv_sc = "SUBidName"
$backend_TNTid_Name_kv_sc = "TNTidName"
$backend_STGPass_Name_kv_sc = "STGPass"
$backend_SPNPass_Name_kv_sc = "SPNPass"

# Set the Azure DevOps organization and project details
$backend_org = "https://dev.azure.com/tfazlab"
$backend_project = "tfazlab"

# Set the variable group details
$backend_VBGroup = "hawaVB"
$description = "backendVB"

# Azure DevOps Connection variables
$backend_AZDOSrvConnName = 'azdo-tfaz-conn'

# Repository variables
$backend_RepoName = "tfazlab"

# Pipeline variables
$backend_PipeName = "TFazInfraPipe"
$backend_PipeDesc = "Pipeline for tfazlab project"
$backend_PipeBuild_Name = "TFaz-Build-Pipe"
$backend_PipeDest_Name = "Tfaz-Destroy-Pipe"
$backend_tfdest_yml = "tfaz_destroy.yml"
$backend_tfaz_build_yml = "tfazbuild.yml"

# [

Write-Host "Retrieving Azure Ids..." -ForegroundColor Green
# Retrieve AZ IDs
$backend_SUBid = $(az account show --query 'id' -o tsv)
$backend_SUBName = $(az account show --query 'name' -o tsv)
$backend_TNTid = $(az account show --query 'tenantId' -o tsv)

# ]

Start-Sleep -Seconds 5

# [ 

Write-Host "Creating service principal..." -ForegroundColor Yellow
$backend_SPNPass = $(az ad sp create-for-rbac --name $backend_spn --role $backend_spn_role --scope /subscriptions/$backend_SUBid --query 'password' -o tsv)

# ]

Start-Sleep -Seconds 5

# [ 

# Set the SPN password as an environment variable: used by the Azdo Service Connection
$env:AZURE_DEVOPS_EXT_AZURE_RM_SERVICE_PRINCIPAL_KEY=$backend_SPNPass

# [

Start-Sleep -Seconds 5

# ]

Write-Host "Creating resource group..." -ForegroundColor Yellow
az group create --name $backend_rg --location $backend_location

Write-Host "Creating storage account..." -ForegroundColor Yellow
az storage account create --resource-group $backend_rg --name $backend_stg --sku $backend_stg_sku --encryption-services blob

$backend_STGPass = $(az storage account keys list --resource-group $backend_rg --account-name $backend_stg --query "[0].value" -o tsv)

Start-Sleep -Seconds 5

Write-Host "Creating storage container..." -ForegroundColor Yellow
az storage container create --name $backend_cont --account-name $backend_stg --account-key $backend_STGPass

Start-Sleep -Seconds 5

Write-Host "Creating the Key Vault..." -ForegroundColor Yellow
az keyvault create --resource-group $backend_rg --name $backend_kv --location $backend_location

Start-Sleep -Seconds 5

Write-Host "Allowing the Service Principal Access in Key Vault..." -ForegroundColor Yellow

$backend_SPNappId = $(az ad sp list --display-name $backend_spn --query '[0].appId' -o tsv)
$backend_SPNid = $(az ad sp show --id $backend_SPNappId --query id -o tsv)

Start-Sleep -Seconds 5

az keyvault set-policy --name $backend_kv --object-id $backend_SPNid --secret-permissions get list set delete purge

#[

Start-Sleep -Seconds 10

# [

Write-Host "Assign SPN AD Permissions..." -ForegroundColor Yellow

Write-Host 'Assign permission appDir...' -ForegroundColor Green
az ad app permission add --id $backend_SPNappId --api $MSGraphApi --api-permissions $appDirRoleId
Start-Sleep -Seconds 20
Write-Host 'Assign permission appUsr...' -ForegroundColor Green
az ad app permission add --id $backend_SPNappId --api $MSGraphApi --api-permissions $appUsrRoleId
Start-Sleep -Seconds 20
Write-Host 'Add Permission grant..' -ForegroundColor Green 
# Ignore error "the following arguments are required: --scope" | 'scope' adds permission in Type: "Delegated"
az ad app permission grant --id $backend_SPNappId --api $MSGraphApi #-scope $scope
Start-Sleep -Seconds 20
Write-host 'Add admin-consent' -ForegroundColor Green
az ad app permission admin-consent --id $backend_SPNappId

# ]

Start-Sleep -Seconds 5

# [

Write-Host "Storing Azure DevOps Service Connection Name in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_AZDOSrvConnName_kv_sc --value $backend_AZDOSrvConnName

Start-Sleep -Seconds 5

Write-Host "Storing Resource Group Name in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_RGName_kv_sc --value $backend_rg

Start-Sleep -Seconds 5

Write-Host "Storing Storage Account Password in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_STGPass_Name_kv_sc --value $backend_stg

Start-Sleep -Seconds 5

Write-Host "Storing Container Name in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_ContName_kv_sc --value $backend_cont

Start-Sleep -Seconds 5

Write-Host "Storing Azure Resource Manager Key in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backendAzureRmKey_kv_sc --value $backendAzureRmKey

Start-Sleep -Seconds 5

Write-Host "Storing Subscription ID in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_SUBid_Name_kv_sc --value $backend_SUBid

Start-Sleep -Seconds 5

Write-Host "Storing Tenant ID in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_TNTid_Name_kv_sc --value $backend_TNTid

Start-Sleep -Seconds 5

Write-Host "Storing the Storage Account Access Key in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_STGPass_Name_kv_sc --value $backend_STGPass

Start-Sleep -Seconds 5

Write-Host "Storing the Storage Account Name in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_STGName_kv_sc --value $backend_stg

Start-Sleep -Seconds 5

Write-Host "Storing SPN Password in Key Vault..." -ForegroundColor Yellow
az keyvault secret set --vault-name $backend_kv --name $backend_SPNPass_Name_kv_sc --value $backend_SPNPass

# ]

Start-Sleep -Seconds 5

# [

# Set Default DevOps Organisation and Project # [$env:AZURE_DEVOPS_EXT_PAT = Run in cli or add in script]
az devops configure --defaults organization=$backend_org
az devops configure --defaults project=$backend_project

# ]

Start-Sleep -Seconds 5

# [

Write-Host "Creating Azure DevOps service endpoint..." -ForegroundColor Yellow
# Create DevOps Service Connection
az devops service-endpoint azurerm create --azure-rm-service-principal-id $backend_SPNappId --azure-rm-subscription-id $backend_SUBid --azure-rm-subscription-name $backend_SUBName --azure-rm-tenant-id $backend_TNTid --name $backend_AZDOSrvConnName --org $backend_org --project $backend_project

# ]

Start-Sleep -Seconds 5

# [


Write-Host "Creating the variable group..." -ForegroundColor Yellow
az pipelines variable-group create --organization $backend_org --project $backend_project --name $backend_VBGroup --description $description --variables foo=bar --authorize true

$backend_VBGroupID = $(az pipelines variable-group list --organization $backend_org --project $backend_project --query "[?name=='$backend_VBGroup'].id" -o tsv)

# Update the variable group in link it in Authorize
az pipelines variable-group update --id $backend_VBGroupID --org $backend_org --project $backend_project --authorize true


# ]

Start-Sleep -Seconds 5

# [

Write-Host "Creating pipeline for tfazlab project..." -ForegroundColor Yellow
az pipelines create --name $backend_PipeBuild_Name --description $backend_PipeDesc --detect false --repository $backend_RepoName --branch main --yml-path $backend_tfaz_build_yml --repository-type tfsgit --skip-first-run true

Start-Sleep -Seconds 10

Write-Host "Create TF Destroy pipeline for tfazlab project" -ForegroundColor Yellow
az pipelines create --name $backend_PipeDest_Name --description $backend_PipeDesc --detect false --repository $backend_RepoName --branch main --yml-path $backend_tfdest_yml --repository-type tfsgit --skip-first-run true

# ]

Start-Sleep -Seconds 10

# [


Write-Host "Allowing AZDO ACCESS..." -ForegroundColor Yellow
# Grant Access in all Pipelines in the Newly Created DevOps Service Connection
$backend_EndPid = az devops service-endpoint list --query "[?name=='$backend_AZDOSrvConnName'].id" -o tsv
az devops service-endpoint update --detect false --id $backend_EndPid --enable-for-all true

# ]

Write-Host "Done!" -ForegroundColor Green