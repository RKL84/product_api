#!/bin/bash

# Color theming
. <(cat ./theme.sh)

# AZ CLI check
. <(cat ./azure-cli-check.sh)

if [ -f ../../create-acr-exports.txt ]
then
  eval $(cat ../../create-acr-exports.txt)
fi

if [ -z "$BIGPURPLE_REGISTRY" ] || [ -z "$BIGPURPLE_ACRNAME" ]
then
    echo "One or more required environment variables are missing:"
    echo "- BIGPURPLE_REGISTRY.: $BIGPURPLE_REGISTRY"
    echo "- BIGPURPLE_ACRNAME..: $BIGPURPLE_ACRNAME"
    exit 1
fi

while [ "$1" != "" ]; do
    case $1 in
        --services) shift
                    services=$1
                    ;;
             * )    echo "Invalid param: $1"
                    exit 1
    esac
    shift
done

echo
echo "Building and publishing docker images to $BIGPURPLE_REGISTRY"

echo " "

# This is the list of {service}:{image}>{dockerfile} of the application
appServices=$(cat ./build-to-acr.services)

if [ -z "$services" ]
then
    serviceList=$(echo "${appServices}" | sed -e 's/:.*//')
else
    serviceList=${services//,/ }
fi

pushd ../.. >/dev/null

for service in $serviceList
do
    line=$(echo "${appServices}" | grep "$service:")
    tokens=(${line//[:>]/ })
    service=${tokens[0]}
    image=${tokens[1]}
    dockerfile=${tokens[2]}

    echo
    echo "Building image \"$image\" for service \"$service\" with \"$dockerfile.acr\"..."
    serviceCmd="az acr build -r $BIGPURPLE_ACRNAME -t $BIGPURPLE_REGISTRY/$image:linux-net6-coupon -f $dockerfile.acr ."
    echo "${newline} > ${azCliCommandStyle}$serviceCmd${defaultTextStyle}${newline}"
    eval $serviceCmd
done

popd >/dev/null
