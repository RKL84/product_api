# Product API

## Architecture Overview

The **Product API** service is a **.NET Core API** which is hosted on Azure Kubernetes. The product data is stored in the sqldata container.  The sqldata container is good for local development. However, Azure managed services should be used when the service is deployed in Azure. 
The Product API exposes the following endpoints - 

```
GET api/v1/product/items
GET api/v1/product/items/{id}
POST api/v1/product/items
```

When a new product is created, a message is added to the Event bus. The event bus is used for asynchronous messaging and event-driven communication.
For local deployment, RabbitMQ container instance is used. In production deployment, Azure Service Bus or other managed service is more appropriate. 


## Steps to run on local machine using **Docker Compose**

1. Install [docker tools](https://docs.docker.com/docker-for-windows/install/)
2. Clone [product_api](https://github.com/RKL84/product_api.git) repository 
3. Run the below command from the **~/src/** directory. This will start Product API, sqldata and RabbitMQ containers. 
```powershell
docker-compose up
```
4. You should be able to browse to the **Product API application** by using the below URL :
```
http://localhost:5900/swagger/index.html
```

5. You can use the following command to extract the Products :
```
curl --location --request GET 'http://localhost:5900/api/v1/Product/items?pageSize=10&pageIndex=0'
```

6. You can use the following command to add a new product. This action will post a message on RabbitMQ event bus. The other microservices can subscribe to this event and process the message. 
```
curl --location --request POST 'http://localhost:5900/api/v1/product/items' \
--header 'Content-Type: application/json' \
--data-raw '{
  "name": "Purple Hoodie",
  "description": "Purple Hoodie",
  "price": 20
}'
```

## Steps to run on Azure (AKS)

1. Install [docker tools](https://docs.docker.com/docker-for-windows/install/)
2. Install [azure cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli)
3. In the new terminal pane, sign in to the Azure CLI. 
```powershell
az login
```
4. Clone [product_api](https://github.com/RKL84/product_api.git) repository 
5. Run the below command from the **~/deploy/k8s** directory.  This command will create Azure Kubernetes service, Azure Container Registry and the required pods using the public docker images. 
```powershell
./initenvironment.sh
```
6. After the app has deployed to AKS, you'll see a variation of the following message in the terminal:
```powershell
The bigPurple-ms application has been deployed to "http://203.0.113.55"
```

6. Run the below command to upload the Product API image to the container registry
```powershell
./build-to-acr.sh
```

7. Copy the IP address of the host from the config.txt file - 
You should be able to browse to the **Product API application** by using the below URL :
```
http://<IPADDRESS>/product-api/swagger/index.html
```

8. You can use the following command to extract the Products :
```
curl --location --request GET 'http://<IPADDRESS>/product-api/api/v1/Product/items?pageSize=10&pageIndex=0'
```

9. You can use the following command to add a new product. This action will post a message on RabbitMQ event bus. The other microservices can subscribe to this event and process the message. 
```
curl --location --request POST 'http://<IPADDRESS>/product-api/api/v1/product/items' \
--header 'Content-Type: application/json' \
--data-raw '{
  "name": "Purple Hoodie",
  "description": "Purple Hoodie",
  "price": 20
}'
```

10. Run the following command to delete all the resources. 
```
cleanup-resource.sh
```


## Setup CI/CD pipelines using GitHub Actions  
GitHub Actions is used to build a container image and deploy to Azure Kubernetes Service. The build and deployment job definitions can be found under the following directory **~/.github/workflow**.