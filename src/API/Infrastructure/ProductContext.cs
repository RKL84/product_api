using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using BigPurpleBank.Product.API.Model;

namespace BigPurpleBank.Product.API.Controllers.Infrastructure
{
    public class ProductContext : DbContext
    {
        public ProductContext(DbContextOptions<ProductContext> options) : base(options)
        {
        }
        public DbSet<ProductItem> ProductItems { get; set; }

        protected override void OnModelCreating(ModelBuilder builder)
        {
            //builder.ApplyConfiguration(new ProductBrandEntityTypeConfiguration());
            //builder.ApplyConfiguration(new ProductTypeEntityTypeConfiguration());
            //builder.ApplyConfiguration(new ProductItemEntityTypeConfiguration());
        }
    }

    public class ProductContextDesignFactory : IDesignTimeDbContextFactory<ProductContext>
    {
        public ProductContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<ProductContext>()
                .UseSqlServer("Server=.;Initial Catalog=BigPurpleBank.Product.API.ProductDb;Integrated Security=true");
            return new ProductContext(optionsBuilder.Options);
        }
    }
}
