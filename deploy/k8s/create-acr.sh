#!/bin/bash

# Color theming
if [ -f ./theme.sh ]
then
  . <(cat ./theme.sh)
fi

if [ -f ../../create-aks-exports.txt ]
then
  eval $(cat ../../create-aks-exports.txt)
fi

if [ ../../create-idtag-exports.txt ]
then
  eval $(cat ../../create-idtag-exports.txt)
fi

bigPurpleRg=${BIGPURPLE_RG}
bigPurpleLocation=${BIGPURPLE_LOCATION}
bigPurpleIdTag=${BIGPURPLE_IDTAG}

while [ "$1" != "" ]; do
    case $1 in
        -g | --resource-group)          shift
                                        bigPurpleRg=$1
                                        ;;
        -l | --location)                shift
                                        bigPurpleLocation=$1
                                        ;;
             * )                        echo "Invalid param: $1"
                                        exit 1
    esac
    shift
done

if [ -z "$bigPurpleRg" ]
then
    echo "${newline}${errorStyle}ERROR: Resource group is mandatory. Use -g to set it${defaultTextStyle}${newline}"
    exit 1
fi

rg=`az group show -g $bigPurpleRg -o json`

if [ -z "$rg" ]
then
    if [ -z "$bigPurpleLocation" ]
    then
        echo "${newline}${errorStyle}ERROR: If resource group has to be created, location is mandatory. Use -l to set it.${defaultTextStyle}${newline}"
        exit 1
    fi
    echo "Creating resource group \"$bigPurpleRg\" in location \"$bigPurpleLocation\"..."
    az group create -n $bigPurpleRg -l $bigPurpleLocation
    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}ERROR: Can't create resource group${defaultTextStyle}${newline}"
        exit 1
    fi

    echo "Created resource group \"$bigPurpleRg\" in location \"$bigPurpleLocation\"."

else
    if [ -z "$bigPurpleLocation" ]
    then
        bigPurpleLocation=`az group show -g $bigPurpleRg --query "location" -otsv`
    fi
fi

# ACR Creation

bigPurpleAcrName=${BIGPURPLE_ACRNAME}

if [ -z "$bigPurpleAcrName" ]
then

    if [ -z "$bigPurpleIdTag" ]
    then
        dateString=$(date "+%Y%m%d%H%M%S")
        random=`head /dev/urandom | tr -dc 0-9 | head -c 3 ; echo ''`

        bigPurpleIdTag="$dateString$random"
    fi

    echo
    echo "Creating Azure Container Registry \"bigPurplelearn$bigPurpleIdTag\" in resource group \"$bigPurpleRg\"..."
    acrCommand="az acr create --name bigPurplelearn$bigPurpleIdTag -g $bigPurpleRg -l $bigPurpleLocation -o json --sku basic --admin-enabled --query \"name\" -otsv"
    echo "${newline} > ${azCliCommandStyle}$acrCommand${defaultTextStyle}${newline}"
    bigPurpleAcrName=`$acrCommand`

    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}ERROR creating ACR!${defaultTextStyle}${newline}"
        exit 1
    fi

    echo ACR instance created!
    echo
fi

bigPurpleRegistry=`az acr show -n $bigPurpleAcrName --query "loginServer" -otsv`

if [ -z "$bigPurpleRegistry" ]
then
    echo "${newline}${errorStyle}ERROR! ACR server $bigPurpleAcrName doesn't exist!${defaultTextStyle}${newline}"
    exit 1
fi

bigPurpleAcrCredentials=`az acr credential show -n $bigPurpleAcrName --query "[username,passwords[0].value]" -otsv`
bigPurpleAcrUser=`echo "$bigPurpleAcrCredentials" | head -1`
bigPurpleAcrPassword=`echo "$bigPurpleAcrCredentials" | tail -1`

# Grant permisions to AKS if created
aksIdentityObjectId=$(az aks show -g $bigPurpleRg -n $BIGPURPLE_AKSNAME --query identityProfile.kubeletidentity.objectId -otsv)

if [ ! -z "$aksIdentityObjectId" ]
then
    acrResourceId=$(az acr show -n $bigPurpleAcrName -g $bigPurpleRg --query id -o tsv)

    az role assignment create \
        --role AcrPull \
        --assignee-object-id $aksIdentityObjectId \
        --scope $acrResourceId \
        --output none
fi

echo export BIGPURPLE_RG=$bigPurpleRg >> create-acr-exports.txt
echo export BIGPURPLE_LOCATION=$bigPurpleLocation >> create-acr-exports.txt
echo export BIGPURPLE_AKSNAME=$BIGPURPLE_AKSNAME >> create-acr-exports.txt
echo export BIGPURPLE_LBIP=$BIGPURPLE_LBIP >> create-acr-exports.txt
echo export BIGPURPLE_ACRNAME=$bigPurpleAcrName >> create-acr-exports.txt
echo export BIGPURPLE_REGISTRY=$bigPurpleRegistry >> create-acr-exports.txt
echo export BIGPURPLE_ACRUSER=$bigPurpleAcrUser >> create-acr-exports.txt
echo export BIGPURPLE_ACRPASSWORD=$bigPurpleAcrPassword >> create-acr-exports.txt
echo export BIGPURPLE_IDTAG=$bigPurpleIdTag >> create-acr-exports.txt

echo export BIGPURPLE_IDTAG=$bigPurpleIdTag >> create-idtag-exports.txt

echo 
echo "Created Azure Container Registry \"$bigPurpleAcrName\" in resource group \"$bigPurpleRg\" in location \"$bigPurpleLocation\"." 

mv -f create-acr-exports.txt ../../
mv -f create-idtag-exports.txt ../../

echo "REGISTRY_LOGIN_SERVER: ${headingStyle}$eshopRegistry${defaultTextStyle}" >> ../../config.txt
echo "REGISTRY_PASSWORD: ${headingStyle}$eshopAcrPassword${defaultTextStyle}" >> ../../config.txt
echo "REGISTRY_USERNAME: ${headingStyle}$eshopAcrUser${defaultTextStyle}" >> ../../config.txt
echo "${newline}" >> ../../config.txt

