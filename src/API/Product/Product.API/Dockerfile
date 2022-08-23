#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Create this "restore-solution" section by running ./Create-DockerfileSolutionRestore.ps1, to optimize build cache reuse
COPY ["Common/EventBus/EventBus/EventBus.csproj", "Common/EventBus/EventBus/"]
COPY ["Common/EventBus/EventBusRabbitMQ/EventBusRabbitMQ.csproj", "Common/EventBus/EventBusRabbitMQ/"]
COPY ["Common/EventBus/EventBusServiceBus/EventBusServiceBus.csproj", "Common/EventBus/EventBusServiceBus/"]
COPY ["Common/EventBus/IntegrationEventLogEF/IntegrationEventLogEF.csproj", "Common/EventBus/IntegrationEventLogEF/"]
COPY ["API/Product/Product.API/Product.API.csproj", "API/Product/Product.API/"]
COPY ["./BigPurpleBank.sln", "./"]
#COPY ["NuGet.config", "./"]
COPY ["docker-compose.dcproj", "./"]
RUN dotnet restore "BigPurpleBank.sln"

COPY . .
WORKDIR "/src/src/API/Product/Product.API"
#RUN dotnet build "Product.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish --no-restore "Product.API.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Product.API.dll"]