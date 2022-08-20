namespace BigPurpleBank.Product.API.Infrastructure.Filters
{
    public partial class HttpGlobalExceptionFilter
    {
        private class JsonErrorResponse
        {
            public string[] Messages { get; set; }
            public object DeveloperMessage { get; set; }
        }
    }
}
