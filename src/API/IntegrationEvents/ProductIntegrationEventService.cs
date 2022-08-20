using BigPurpleBank.Common.EventBus.Abstractions;
using BigPurpleBank.Common.EventBus.Events;
using BigPurpleBank.Common.IntegrationEventLogEF.Services;
using BigPurpleBank.Common.IntegrationEventLogEF.Utilities;
using BigPurpleBank.Product.API.Controllers.Infrastructure;
using Microsoft.EntityFrameworkCore;
using System.Data.Common;

namespace BigPurpleBank.Product.API.IntegrationEvents
{
    public class ProductIntegrationEventService : IProductIntegrationEventService
    {
        private readonly Func<DbConnection, IIntegrationEventLogService> _integrationEventLogServiceFactory;
        private readonly IEventBus _eventBus;
        private readonly ProductContext _productContext;
        private readonly IIntegrationEventLogService _eventLogService;
        private readonly ILogger<ProductIntegrationEventService> _logger;

        public ProductIntegrationEventService(
            ILogger<ProductIntegrationEventService> logger,
            IEventBus eventBus,
            ProductContext productContext,
            Func<DbConnection, IIntegrationEventLogService> integrationEventLogServiceFactory)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _productContext = productContext ?? throw new ArgumentNullException(nameof(productContext));
            _integrationEventLogServiceFactory = integrationEventLogServiceFactory ??
                throw new ArgumentNullException(nameof(integrationEventLogServiceFactory));
            _eventBus = eventBus ?? throw new ArgumentNullException(nameof(eventBus));
            _eventLogService = _integrationEventLogServiceFactory(_productContext.Database.GetDbConnection());
        }

        public async Task PublishThroughEventBusAsync(IntegrationEvent evt)
        {
            try
            {
                _logger.LogInformation("----- Publishing integration event: {IntegrationEventId_published} from {AppName} - ({@IntegrationEvent})", evt.Id, Program.AppName, evt);
                await _eventLogService.MarkEventAsInProgressAsync(evt.Id);
                _eventBus.Publish(evt);
                await _eventLogService.MarkEventAsPublishedAsync(evt.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "ERROR Publishing integration event: {IntegrationEventId} from {AppName} - ({@IntegrationEvent})", evt.Id, Program.AppName, evt);
                await _eventLogService.MarkEventAsFailedAsync(evt.Id);
            }
        }

        public async Task SaveEventAndProductContextChangesAsync(IntegrationEvent evt)
        {
            _logger.LogInformation("----- ProductIntegrationEventService - Saving changes and integrationEvent: {IntegrationEventId}", evt.Id);
            //Use of an EF Core resiliency strategy when using multiple DbContexts within an explicit BeginTransaction():
            //See: https://docs.microsoft.com/en-us/ef/core/miscellaneous/connection-resiliency            
            await ResilientTransaction.New(_productContext).ExecuteAsync(async () =>
            {
                // Achieving atomicity between original product database operation and the IntegrationEventLog thanks to a local transaction
                await _productContext.SaveChangesAsync();
                await _eventLogService.SaveEventAsync(evt, _productContext.Database.CurrentTransaction);
            });
        }
    }
}
