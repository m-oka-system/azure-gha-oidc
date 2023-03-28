#!/usr/bin/env bash

appName="githubactions"

# Azure sign in
az login

# Get the current Azure subscription ID
subscriptionId=$(az account show --query 'id' --output tsv)

# Create a new Azure Active Directory application
appId=$(az ad app create --display-name $appName --query appId --output tsv)

# Create a new service principal for the application
assigneeObjectId=$(az ad sp create --id $appId --query id --output tsv)

# Assign the 'Contributor' role to the service principal for the subscription
az role assignment create --role contributor \
  --subscription $subscriptionId \
  --assignee-object-id $assigneeObjectId \
  --assignee-principal-type ServicePrincipal \
  --scope /subscriptions/$subscriptionId

# Get the ID of an existing Azure Active Directory application
# appId=$(az ad app list --query "[?displayName == \`$appName\`]".appId --output tsv)

# Create a federated credential for the application using the parameters from the 'credential.json' file
# https://learn.microsoft.com/ja-jp/azure/active-directory/workload-identities/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azcli
az ad app federated-credential create --id $appId --parameters credential.json

# Delete a federated credential
githubUserName=$(gh api user -q .login)
currentRepoName=$(basename $(git rev-parse --show-toplevel))
federatedCredentialId=$(az ad app federated-credential list --id $appId --query "[?name == \`${githubUserName}-${currentRepoName}-main\`]".id --output tsv)
az ad app federated-credential delete --id $appId --federated-credential-id $federatedCredentialId
