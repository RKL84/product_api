#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["src/API/Product/Product.API/Product.API.csproj", "src/API/Product/Product.API/"]
COPY ["src/Common/EventBus/EventBusRabbitMQ/EventBusRabbitMQ.csproj", "src/Common/EventBus/EventBusRabbitMQ/"]
COPY ["src/Common/EventBus/EventBus/EventBus.csproj", "src/Common/EventBus/EventBus/"]
COPY ["src/Common/EventBus/IntegrationEventLogEF/IntegrationEventLogEF.csproj", "src/Common/EventBus/IntegrationEventLogEF/"]
COPY ["src/Common/EventBus/EventBusServiceBus/EventBusServiceBus.csproj", "src/Common/EventBus/EventBusServiceBus/"]
RUN dotnet restore "src/API/Product/Product.API/Product.API.csproj"
COPY . .
WORKDIR "/src/src/API/Product/Product.API"
RUN dotnet build "Product.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Product.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Product.API.dll"]