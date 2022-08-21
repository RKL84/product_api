#!/bin/bash
vmSize=Standard_D2_v5

# Color theming
if [ -f ../../../../infrastructure/scripts/theme.sh ]
then
  . <(cat ../../../../infrastructure/scripts/theme.sh)
fi

bigPurpleSubs=${BIGPURPLE_SUBS}
bigPurpleRg=${BIGPURPLE_RG}
bigPurpleLocation=${BIGPURPLE_LOCATION}
bigPurpleNodeCount=${BIGPURPLE_NODECOUNT:-1}
bigPurpleAksName=${BIGPURPLE_AKSNAME:-bigPurple-ms-aks}

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
    echo "${newline}${errorStyle}ERROR: Resource group is mandatory. Use -g to set it.${defaultTextStyle}${newline}"
    exit 1
fi

# Swallow STDERR so we don't get red text here from expected error if the RG doesn't exist
exec 3>&2
exec 2> /dev/null

rg=`az group show -g $bigPurpleRg -o json`

# Reset STDERR
exec 2>&3

if [ -z "$rg" ]
then
    if [ -z "$bigPurpleLocation" ]
    then
        echo "${newline}${errorStyle}ERROR: If resource group has to be created, location is mandatory. Use -l to set it.${defaultTextStyle}${newline}"
        exit 1
    fi
    echo "Creating resource group \"$bigPurpleRg\" in location \"$bigPurpleLocation\"..."
    echo "${newline} > ${azCliCommandStyle}az group create -n $bigPurpleRg -l $bigPurpleLocation --output none${defaultTextStyle}${newline}"
    az group create -n $bigPurpleRg -l $bigPurpleLocation --output none
    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}ERROR: Can't create resource group!${defaultTextStyle}${newline}"
        exit 1
    fi
else
    if [ -z "$bigPurpleLocation" ]
    then
        bigPurpleLocation=`az group show -g $bigPurpleRg --query "location" -otsv`
    fi
fi

# AKS Cluster creation
# Swallow STDERR so we don't get red text here from expected error if the RG doesn't exist
exec 3>&2
exec 2> /dev/null

existingAks=`az aks show -n $bigPurpleAksName -g $bigPurpleRg -o json`

# Reset STDERR
exec 2>&3

if [ -z "$existingAks" ]
then
    echo
    echo "Creating AKS cluster \"$bigPurpleAksName\" in resource group \"$bigPurpleRg\" and location \"$bigPurpleLocation\"."
    echo "Using VM size \"$vmSize\". You can change this by modifying the value of the \"vmSize\" variable at the top of \"create-aks.sh\""
    aksCreateCommand="az aks create -n $bigPurpleAksName -g $bigPurpleRg -c $bigPurpleNodeCount --node-vm-size $vmSize --vm-set-type VirtualMachineScaleSets -l $bigPurpleLocation --enable-managed-identity --generate-ssh-keys -o json"
    echo "${newline} > ${azCliCommandStyle}$aksCreateCommand${defaultTextStyle}${newline}"
    retry=5
    aks=`$aksCreateCommand`
    while [ ! $? -eq 0 ]&&[ $retry -gt 0 ]
    do
        echo
        echo "Unable to create AKS cluster. Retrying in 5s..."
        let retry--
        sleep 5
        echo
        echo "Retrying AKS cluster creation..."
        aks=`$aksCreateCommand`
    done

    if [ ! $? -eq 0 ]
    then
        echo "${newline}${errorStyle}Error creating AKS cluster!${defaultTextStyle}${newline}"
        exit 1
    fi

    echo
    echo "AKS cluster created."
else
    echo
    echo "Reusing existing AKS resource."
fi

echo
echo "Getting credentials for AKS..."
az aks get-credentials -n $bigPurpleAksName -g $bigPurpleRg --overwrite-existing

# Ingress controller and load balancer (LB) deployment

echo
echo "Installing Nginx ingress controller..."
kubectl apply -f ingress-controller/nginx-controller.yaml

echo
echo "Getting Load Balancer public IP..."

while [ -z "$bigPurpleLbIp" ]
do
    bigPurpleLbIpCommand="kubectl get svc -n ingress-nginx -o json | jq -r -e '.items[0].status.loadBalancer.ingress[0].ip // empty'"
    echo "${newline} > ${genericCommandStyle}$bigPurpleLbIpCommand${defaultTextStyle}${newline}"
    bigPurpleLbIp=$(eval $bigPurpleLbIpCommand)
    if [ -z "$bigPurpleLbIp" ]
    then
        echo "Load balancer wasn't ready. If this takes more than a minute or two, something is probably wrong. Trying again in 5 seconds..."
        sleep 5
    fi
done

echo "Load balancer IP is $bigPurpleLbIp"

echo
echo "Nginx ingress controller installed."

echo
echo "Wait until ingress is ready to process requests"

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

    echo export BIGPURPLE_RG=$bigPurpleRg > create-aks-exports.txt
    echo export BIGPURPLE_LOCATION=$bigPurpleLocation >> create-aks-exports.txt
    echo export BIGPURPLE_AKSNAME=$bigPurpleAksName >> create-aks-exports.txt
    echo export BIGPURPLE_AKSNODERG=$aksNodeRG >> create-aks-exports.txt
    echo export BIGPURPLE_LBIP=$bigPurpleLbIp >> create-aks-exports.txt

    mv -f create-aks-exports.txt ../../
