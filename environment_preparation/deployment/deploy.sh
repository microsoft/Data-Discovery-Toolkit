if [ ! -f .env ]
then
  export $(cat vars.env | xargs)
fi

echo "Reading environment variables from .env file"

az group create --name $SynapseResourceGroup --location $Region --tags ProjectName=SynapseResourceGroup

echo "Created Resource Group" $SynapseResourceGroup

# Register the SQL provider on the subscription 
az provider register --namespace Microsoft.Sql

echo "Registered SQL provider"

az synapse workspace create \
  --name $SynapseWorkspaceName \
  --resource-group $SynapseResourceGroup \
  --storage-account $StorageAccountName \
  --file-system $FileShareName \
  --sql-admin-login-user $SqlUser \
  --sql-admin-login-password $SqlPassword \
  --location $Region \
  --tags ProjectName=SynapseResourceGroup 

echo "Created Synapse Workspace" $SynapseWorkspaceName

WorkspaceWeb=$(az synapse workspace show --name $SynapseWorkspaceName --resource-group $SynapseResourceGroup | jq -r '.connectivityEndpoints | .web')

WorkspaceDev=$(az synapse workspace show --name $SynapseWorkspaceName --resource-group $SynapseResourceGroup | jq -r '.connectivityEndpoints | .dev')

ClientIP=$(curl -sb -H "Accept: application/json" "$WorkspaceDev" | jq -r '.message')
ClientIP=${ClientIP##'Client Ip address : '}

echo "Creating a firewall rule to enable access for IP address: $ClientIP"

az synapse workspace firewall-rule create \
  --end-ip-address $ClientIP \
  --start-ip-address $ClientIP \
  --name "Allow Client IP" \
  --resource-group $SynapseResourceGroup \
  --workspace-name $SynapseWorkspaceName

echo "Open your Azure Synapse Workspace Web URL in the browser: $WorkspaceWeb"

spID=$(az resource list -n $SynapseWorkspaceName --query [*].identity.principalId --out tsv)

echo "Storage Account SP ID: $spID"

az role assignment create \
    --assignee $spID \
    --role 'Storage Account Contributor' \
    --scope /subscriptions/$SubscriptionId/resourceGroups/$StorageAccountResourceGroup/providers/Microsoft.Storage/storageAccounts/$StorageAccountName

echo "Assigned Workspace role to Storage Account"

userID=$(az ad signed-in-user show --query id --out tsv)

echo "User ID: $userID"

az role assignment create \
    --assignee $userID \
    --role 'Storage Account Contributor' \
    --scope /subscriptions/$SubscriptionId/resourceGroups/$StorageAccountResourceGroup/providers/Microsoft.Storage/storageAccounts/$StorageAccountName

echo "Assigned User as Storage Account Contributor for Workspace"

az synapse spark pool create \
  --name "DataDiscovery" \
  --node-count 10 \
  --node-size 'Small' \
  --resource-group $SynapseResourceGroup \
  --spark-version "3.3" \
  --workspace-name $SynapseWorkspaceName \
  --enable-auto-pause true \
  --enable-auto-scale true \
  --min-node-count 3 \
  --max-node-count 10 \
  --delay 15 \
  --tags ProjectName=$SynapseResourceGroup

echo "Created spark pool DataDiscovery"

az synapse spark pool update \
  --name "DataDiscovery" \
  --workspace-name $SynapseWorkspaceName \
  --resource-group $SynapseResourceGroup \
  --library-requirements "../../Synapse/config/environment.yml"

echo "Updated spark pool DataDiscovery"

echo "Downloading spaCy model"
curl -J -L https://github.com/explosion/spacy-models/releases/download/en_core_web_lg-3.4.0/en_core_web_lg-3.4.0-py3-none-any.whl \
  --output en_core_web_lg-3.4.0-py3-none-any.whl && az synapse workspace-package upload \
  --workspace-name $SynapseWorkspaceName \
  --package "en_core_web_lg-3.4.0-py3-none-any.whl"

echo "Uploaded spaCy model workspace package"

az synapse workspace-package upload \
  --workspace-name $SynapseWorkspaceName \
  --package "graphframes-0.8.2-spark3.2-s_2.12.jar"

echo "Uploaded graphframes workspace package"

az synapse spark pool update \
  --name "DataDiscovery" \
  --workspace-name $SynapseWorkspaceName \
  --resource-group $SynapseResourceGroup \
  --package "en_core_web_lg-3.4.0-py3-none-any.whl" \
  --package-action "Add"

  echo "Updated spark pool with spaCy workspace package"

  az synapse spark pool update \
  --name "DataDiscovery" \
  --workspace-name $SynapseWorkspaceName \
  --resource-group $SynapseResourceGroup \
  --package "graphframes-0.8.2-spark3.2-s_2.12.jar" \
  --package-action "Add"

echo "Updated spark pool with graphframes workspace package"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name coalesce \
  --file @"../../Synapse/notebooks/coalesce.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported coalesce notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_image_captioning \
  --file @"../../Synapse/notebooks/image_captioning/standalone_image_captioning.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_image_captioning notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_image_clustering \
  --file @"../../Synapse/notebooks/image_clustering/standalone_image_clustering.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_image_clustering notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_text_clustering_TF_IDF \
  --file @"../../Synapse/notebooks/text_clustering/standalone_text_clustering.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_text_clustering notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_text_summarisation \
  --file @"../../Synapse/notebooks/text_summarisation/standalone_text_summarisation.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_text_summarisation notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_text_clustering_OpenAI \
  --file @"../../Synapse/notebooks/text_clustering/standalone_text_clustering_OpenAI.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_text_clustering_OpenAI notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_text_clustering_spaCy \
  --file @"../../Synapse/notebooks/text_clustering/standalone_text_clustering_spaCy.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_text_clustering_spaCy notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_text_clustering_BERT \
  --file @"../../Synapse/notebooks/text_clustering/standalone_text_clustering_BERT.ipynb" \
  --folder-path 'DataDiscovery' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_text_clustering_BERT notebook"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name graph_similarity.ipynb \
  --file @"../../walkthroughs/bbc/graph_similarity.ipynb" \
  --folder-path 'Walkthroughs' \
  --spark-pool-name "DataDiscovery"

echo "Imported graph_similarity walkthrough"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name standalone_text_heuristics.ipynb \
  --file @"../../walkthroughs/heuristics/standalone_text_heuristics.ipynb" \
  --folder-path 'Walkthroughs' \
  --spark-pool-name "DataDiscovery"

echo "Imported standalone_text_heuristics walkthrough"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name create_sample.ipynb \
  --file @"../../walkthroughs/imsitu/create_sample.ipynb" \
  --folder-path 'Walkthroughs' \
  --spark-pool-name "DataDiscovery"

echo "Imported ImSitu create_sample walkthrough"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name imSitu.ipynb \
  --file @"../../walkthroughs/imsitu/imSitu.ipynb" \
  --folder-path 'Walkthroughs' \
  --spark-pool-name "DataDiscovery"

echo "Imported imSitu walkthrough"

az synapse notebook import \
  --workspace-name $SynapseWorkspaceName \
  --name imSitu.ipynb \
  --file @"../../walkthroughs/OpenAi-classification/OpenAI-Classification.ipynb" \
  --folder-path 'Walkthroughs' \
  --spark-pool-name "DataDiscovery"

echo "Imported OpenAI-Classification walkthrough"
