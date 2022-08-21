#!/bin/bash
defaultLocation="eastus"
defaultRg="bigpurple-ms-rg"

# Color theming
. <(cat ../../../../infrastructure/scripts/theme.sh)

# AZ CLI check
. <(cat ../../../../infrastructure/scripts/azure-cli-check.sh)

bigPurpleSubs=${BIGPURPLE_SUBS}
bigPurpleRg=${BIGPURPLE_RG}
bigPurpleLocation=${BIGPURPLE_LOCATION}
bigPurpleRegistry=bigPurple

while [ "$1" != "" ]; do
    case $1 in
        -s | --subscription)            shift
                                        bigPurpleSubs=$1
                                        ;;
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

if [ -z "$bigPurpleLocation" ]
then
    echo "Using the default location: $defaultLocation"
    bigPurpleLocation=$defaultLocation
fi

if [ -z "$bigPurpleRg" ]
then
    echo "Using the default resource group: $defaultRg"
    bigPurpleRg=$defaultRg
fi
echo "${bold}Note: You can change the default location and resource group by modifying the variables at the top of quickstart.sh.${defaultTextStyle}"

if [ ! -z "$bigPurpleSubs" ]
then
    echo "Switching to subscription $bigPurpleSubs..."
    az account set -s $bigPurpleSubs
fi

if [ ! $? -eq 0 ]
then
    echo "${newline}${errorStyle}ERROR: Can't switch to subscription $bigPurpleSubs.${defaultTextStyle}${newline}"
    exit 1
fi

export BIGPURPLE_SUBS=$bigPurpleSubs
export BIGPURPLE_RG=$bigPurpleRg
export BIGPURPLE_LOCATION=$bigPurpleLocation
export BIGPURPLE_REGISTRY=$bigPurpleRegistry
export BIGPURPLE_QUICKSTART=true

# AKS Cluster creation
. <(cat ./create-aks.sh)

eval $(cat ../../create-aks-exports.txt)

. <(cat ./deploy-application.sh)

. <(cat ./create-acr.sh)

cat ../../deployment-urls.txt
