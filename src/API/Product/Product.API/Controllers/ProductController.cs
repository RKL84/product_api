using BigPurpleBank.Product.API.Controllers.Infrastructure;
using BigPurpleBank.Product.API.IntegrationEvents;
using BigPurpleBank.Product.API.IntegrationEvents.Events;
using BigPurpleBank.Product.API.Model;
using BigPurpleBank.Product.API.ViewModel;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using System.Net;

namespace BigPurpleBank.Product.API.Controllers
{
    [Route("api/v1/[controller]")]
    [ApiController]
    public class ProductController : ControllerBase
    {
        private readonly ProductContext _productContext;
        private readonly ProductSettings _settings;
        private readonly IProductIntegrationEventService _productIntegrationEventService;

        public ProductController(ProductContext context,
            IOptionsSnapshot<ProductSettings> settings,
            IProductIntegrationEventService productIntegrationEventService)
        {
            _productContext = context ?? throw new ArgumentNullException(nameof(context));
            _productIntegrationEventService = productIntegrationEventService ??
                throw new ArgumentNullException(nameof(productIntegrationEventService));
            _settings = settings.Value;
            context.ChangeTracker.QueryTrackingBehavior = QueryTrackingBehavior.NoTracking;
        }

        // GET api/v1/[controller]/items[?pageSize=3&pageIndex=10]
        [HttpGet]
        [Route("items")]
        [ProducesResponseType(typeof(PaginatedItemsViewModel<ProductItem>), (int)HttpStatusCode.OK)]
        [ProducesResponseType(typeof(IEnumerable<ProductItem>), (int)HttpStatusCode.OK)]
        [ProducesResponseType((int)HttpStatusCode.BadRequest)]
        public async Task<IActionResult> ItemsAsync
            ([FromQuery] int pageSize = 10, [FromQuery] int pageIndex = 0)
        {
            var totalItems = await _productContext.ProductItem
                .LongCountAsync();

            var itemsOnPage = await _productContext.ProductItem
                .OrderBy(c => c.Name)
                .Skip(pageSize * pageIndex)
                .Take(pageSize)
                .ToListAsync();
            var model = new PaginatedItemsViewModel<ProductItem>
                (pageIndex, pageSize, totalItems, itemsOnPage);
            return Ok(model);
        }

        [HttpGet]
        [Route("items/{id:int}")]
        [ProducesResponseType((int)HttpStatusCode.NotFound)]
        [ProducesResponseType((int)HttpStatusCode.BadRequest)]
        [ProducesResponseType(typeof(ProductItem), (int)HttpStatusCode.OK)]
        public async Task<ActionResult<ProductItem>> ItemByIdAsync(int id)
        {
            if (id <= 0)
                return BadRequest();

            var item = await _productContext.ProductItem.SingleOrDefaultAsync(ci => ci.Id == id);
            if (item != null)
                return item;
            return NotFound();
        }


        ////POST api/v1/[controller]/items
        //[Route("items")]
        //[HttpPost]
        //[ProducesResponseType((int)HttpStatusCode.Created)]
        //public async Task<ActionResult> CreateProductAsync([FromBody] ProductItem product)
        //{
        //    var item = new ProductItem
        //    {
        //    };

        //    _productContext.ProductItem.Add(item);
        //    var productAddedEvent = new ProductAddedIntegrationEvent(product.Name);
        //    await _productIntegrationEventService.SaveEventAndProductContextChangesAsync(productAddedEvent);
        //    await _productIntegrationEventService.PublishThroughEventBusAsync(productAddedEvent);
        //    return CreatedAtAction(nameof(ItemByIdAsync), new { id = item.Id }, null);
        //}
    }
}
