using System;

namespace BigPurpleBank.Product.API.Infrastructure.Exceptions
{
    /// <summary>
    /// Exception type for app exceptions
    /// </summary>
    public class ProductDomainException : Exception
    {
        public ProductDomainException()
        { }

        public ProductDomainException(string message)
            : base(message)
        { }

        public ProductDomainException(string message, Exception innerException)
            : base(message, innerException)
        { }
    }
}
