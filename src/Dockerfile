#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src
COPY ["product_api/product_api.csproj", "product_api/"]
RUN dotnet restore "product_api/product_api.csproj"
COPY . .
WORKDIR "/src/product_api"
RUN dotnet build "product_api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "product_api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "product_api.dll"]