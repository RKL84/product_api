using BigPurpleBank.Common.EventBus.Events;

namespace BigPurpleBank.Product.API.IntegrationEvents
{
    public interface IProductIntegrationEventService
    {
        Task SaveEventAndProductContextChangesAsync(IntegrationEvent evt);
        Task PublishThroughEventBusAsync(IntegrationEvent evt);
    }
}
