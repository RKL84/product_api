#!/bin/bash

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

if [ -f ../../create-aks-exports.txt ]
then
  eval $(cat ../../create-aks-exports.txt)
fi

if [ -f ../../create-idtag-exports.txt ]
then
  eval $(cat ../../create-idtag-exports.txt)
fi

if [ -z "$BIGPURPLE_RG" ] || [ -z "$BIGPURPLE_LOCATION" ]
then
    echo "One or more required environment variables are missing:"
    echo "- BIGPURPLE_RG.......: $BIGPURPLE_RG"
    echo "- BIGPURPLE_LOCATION.: $BIGPURPLE_LOCATION"
    exit 1
fi

bigPurpleIdTag=${BIGPURPLE_IDTAG}

# App Config Creation

if [ -z "$bigPurpleIdTag" ]
then
    dateString=$(date "+%Y%m%d%H%M%S")
    random=`head /dev/urandom | tr -dc 0-9 | head -c 3 ; echo ''`

    bigPurpleIdTag="$dateString$random"
fi

cosmosAccountName=bigPurple-ms-$bigPurpleIdTag
cosmosDbName=CouponDb

echo
echo "Creating Azure CosmosDB account \"$cosmosAccountName\" in resource group \"$BIGPURPLE_RG\"..."
acdbCommand="az cosmosdb create --name $cosmosAccountName --resource-group $BIGPURPLE_RG --kind MongoDB --locations regionName=eastus --output none"
echo "${newline} > ${azCliCommandStyle}$acdbCommand${defaultTextStyle}${newline}"
eval $acdbCommand

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}Error creating CosmosDB account!${plainTextStyle}"
    exit 1
fi

echo
echo "Creating MongoDB database \"$cosmosDbName\" in \"$cosmosAccountName\"..."
mdbCommand="az cosmosdb mongodb database create --account-name $cosmosAccountName --name $cosmosDbName --resource-group $BIGPURPLE_RG --output none"
echo "${newline} > ${azCliCommandStyle}$mdbCommand${defaultTextStyle}${newline}"
eval $mdbCommand

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}Error creating MongoDB database!${plainTextStyle}"
    exit 1
fi

echo
echo "Retrieving connection string..."
csCommand="az cosmosdb keys list --type connection-strings --name $cosmosAccountName --resource-group $BIGPURPLE_RG --query connectionStrings[0].connectionString --output tsv"
echo "${newline} > ${azCliCommandStyle}$csCommand${defaultTextStyle}${newline}"
connectionString=$(eval $csCommand)

if [ ! $? -eq 0 ]
then
    echo "${errorStyle}Error retrieving connection string!${defaultTextStyle}"
    exit 1
fi

echo export BIGPURPLE_COSMOSACCTNAME=$cosmosAccountName >> create-azure-cosmosdb-exports.txt
echo export BIGPURPLE_COSMOSDBCONNSTRING=$connectionString >> create-azure-cosmosdb-exports.txt
echo export BIGPURPLE_IDTAG=$bigPurpleIdTag >> create-azure-cosmosdb-exports.txt

echo export BIGPURPLE_IDTAG=$bigPurpleIdTag >> create-idtag-exports.txt

echo "${newline}${headingStyle}Connection String:${defaultTextStyle}${newline}${newline}$connectionString" 
echo 

mv -f create-azure-cosmosdb-exports.txt ../../
mv -f create-idtag-exports.txt ../../
