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

redisName=bigPurple-redis-$bigPurpleId

echo
echo "Creating Azure Cache for Redis \"$redisName\" in resource group \"$BIGPURPLE_RG\"..."
acrCommand="az redis create --location $BIGPURPLE_LOCATION --name $redisName --resource-group $BIGPURPLE_RG --sku Basic --vm-size c0 --output none"
echo "${newline} > ${azCliCommandStyle}$acrCommand${defaultTextStyle}${newline}"
eval $acrCommand

if [ ! $? -eq 0 ]
then
    echo "${newline}${errorStyle}ERROR creating Azure Cache for Redis!${defaultTextStyle}${newline}"
    exit 1
fi

echo
echo "Retrieving Azure Cache for Redis connection string..."

primaryKey=$(az redis list-keys --resource-group $BIGPURPLE_RG --name $redisName --query primaryKey --output tsv)

if [ ! $? -eq 0 ]
then
    echo "ERROR!"
    exit 1
fi

connectionString="$redisName.redis.cache.windows.net:6380,password=$primaryKey,ssl=True,abortConnect=False"

echo export BIGPURPLE_REDISNAME=$redisName >> create-azure-redis-exports.txt
echo export BIGPURPLE_REDISPRIMARYKEY=$primaryKey >> create-azure-redis-exports.txt
echo export BIGPURPLE_REDISCONNSTRING=$connectionString >> create-azure-redis-exports.txt
echo export BIGPURPLE_IDTAG=$bigPurpleIdTag >> create-azure-redis-exports.txt

echo export BIGPURPLE_IDTAG=$bigPurpleIdTag >> create-idtag-exports.txt

echo "${newline}${defaultTextStyle}ConnectionString: ${headingStyle}$connectionString${defaultTextStyle}" 
echo "${newline}${headingStyle}Done! The Azure Cache for Redis resource is provisioned, but it still has startup tasks to do. It will be a few minutes before the resource is ready.${defaultTextStyle}" 
echo "${newline}Check the status of the resource with the following:"
echo "${newline} > ${azCliCommandStyle}az redis show -g $BIGPURPLE_RG -n $redisName --query provisioningState${defaultTextStyle}${newline}"

mv -f create-azure-redis-exports.txt ../../
mv -f create-idtag-exports.txt ../../
