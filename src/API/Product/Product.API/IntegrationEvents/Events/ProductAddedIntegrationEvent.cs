using BigPurpleBank.Common.EventBus.Events;

namespace BigPurpleBank.Product.API.IntegrationEvents.Events
{
    public class ProductAddedIntegrationEvent : IntegrationEvent
    {
        public string Name { get; set; }
        public ProductAddedIntegrationEvent(string productName)
        {
            Name = productName;
        }
    }
}