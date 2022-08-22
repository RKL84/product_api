using Microsoft.Extensions.Options;
using BigPurpleBank.Product.API.Model;
using Polly;
using Polly.Retry;
using Microsoft.Data.SqlClient;
using BigPurpleBank.Product.API.Controllers.Infrastructure;

namespace BigPurpleBank.Product.API.Infrastructure
{
    public class ProductContextSeed
    {
        public async Task SeedAsync
            (ProductContext context, IWebHostEnvironment env,
            IOptions<ProductSettings> settings, ILogger<ProductContextSeed> logger)
        {
            var policy = CreatePolicy(logger, nameof(ProductContextSeed));
            await policy.ExecuteAsync(async () =>
            {
                if (!context.ProductItems.Any())
                {
                    await context.ProductItems.AddRangeAsync(GetPreconfiguredItems());
                    await context.SaveChangesAsync();
                }
            });
        }
        private IEnumerable<ProductItem> GetPreconfiguredItems()
        {
            return new List<ProductItem>()
            {
                new ProductItem { Id = 2,  Description = ".NET Bot Black Hoodie", Name = ".NET Bot Black Hoodie", Price = 19.5M  },
                new ProductItem { Id = 1,  Description = ".NET Black & White Mug", Name = ".NET Black & White Mug", Price= 8.50M },
                new ProductItem { Id = 2,  Description = "Prism White T-Shirt", Name = "Prism White T-Shirt", Price = 12  },
                new ProductItem { Id = 2,  Description = ".NET Foundation T-shirt", Name = ".NET Foundation T-shirt", Price = 12  },
                new ProductItem { Id = 3,  Description = "Roslyn Red Pin", Name = "Roslyn Red Pin", Price = 8.5M },
                new ProductItem { Id = 2,   Description = ".NET Blue Hoodie", Name = ".NET Blue Hoodie", Price = 12  },
                new ProductItem { Id = 2,  Description = "Roslyn Red T-Shirt", Name = "Roslyn Red T-Shirt", Price =  11},
                new ProductItem { Id = 2, Description = "Kudu Purple Hoodie", Name = "Kudu Purple Hoodie", Price = 8.5M },
                new ProductItem { Id = 1,   Description = "Cup<T> White Mug", Name = "Cup<T> White Mug", Price = 12 },
                new ProductItem { Id = 3,   Description = ".NET Foundation Pin", Name = ".NET Foundation Pin", Price = 12 },
                new ProductItem { Id = 3,  Description = "Cup<T> Pin", Name = "Cup<T> Pin", Price = 8.5M },
                new ProductItem { Id = 2,  Description = "Cup<T> White TShirt", Name = "Cup<T> White TShirt", Price = 12 },
                new ProductItem { Id = 1,  Description = "Modern .NET Mug", Name = "Modern .NET Mug", Price= 8.50M },
                new ProductItem { Id = 1,  Description = "Modern Cup<T> Mug", Name = "Modern Cup<T> Mug", Price = 12 },
            };
        }

        private AsyncRetryPolicy CreatePolicy(ILogger<ProductContextSeed> logger, string prefix, int retries = 3)
        {
            return Policy.Handle<SqlException>().
                WaitAndRetryAsync(
                    retryCount: retries,
                    sleepDurationProvider: retry => TimeSpan.FromSeconds(5),
                    onRetry: (exception, timeSpan, retry, ctx) =>
                    {
                        logger.LogWarning(exception,
                            "[{prefix}] Exception {ExceptionType} with message {Message} detected on attempt {retry} of {retries}",
                            prefix, exception.GetType().Name, exception.Message, retry, retries);
                    }
                );
        }
    }
}
