public with sharing class PaymentLinkCallout {

    public String generateLink(Contact contact) {
        if (String.isBlank(contact.Stripe_Customer_ID__c)) {
            if (String.isBlank(contact.Email)) {
                throw new MissingRequiredFieldException('Contact must have an email address to create a Stripe payment link.');
            }
            String stripeCustomerId = StripeCreateCustomerQueueable.createStripeCustomer(contact);
            if (String.isBlank(stripeCustomerId)) {
                throw new CalloutException('Failed to create Stripe customer for contact.');
            }
            contact.Stripe_Customer_ID__c = stripeCustomerId;
        }
        
        String existingPaymentLink = findExistingPaymentLink(contact.Stripe_Customer_ID__c);
        if (String.isNotBlank(existingPaymentLink)) {
            return existingPaymentLink;
        }
        
        return createPaymentLink(contact);
    }
    
    private String findExistingPaymentLink(String stripeCustomerId) {
        return null;
    }
    
    private String createPaymentLink(Contact contact) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:Stripe_API/v1/payment_links');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(buildPaymentLinkRequestBody(contact));

        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (!isSuccessStatusCode(response.getStatusCode())) {
            throw new CalloutException('Failed to create payment link. Status: ' + response.getStatusCode() + ', Body: ' + response.getBody());
        }

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String paymentLink = (String) parsedBody.get('url');
        
        if (String.isBlank(paymentLink)) {
            throw new CalloutException('Payment link URL not found in Stripe response.');
        }

        return paymentLink;
    }
    
    private String buildPaymentLinkRequestBody(Contact contact) {
        List<String> params = new List<String>();
        
        params.add('line_items[0][price_data][currency]=usd');
        params.add('line_items[0][price_data][product_data][name]=Payment for ' + EncodingUtil.urlEncode(contact.FirstName + ' ' + contact.LastName, 'UTF-8'));
        params.add('line_items[0][price_data][unit_amount]=1000');
        
        if (String.isNotBlank(contact.Stripe_Customer_ID__c)) {
            params.add('customer=' + EncodingUtil.urlEncode(contact.Stripe_Customer_ID__c, 'UTF-8'));
        }
        
        return String.join(params, '&');
    }
    
    private Boolean isSuccessStatusCode(Integer statusCode) {
        return statusCode >= 200 && statusCode < 300;
    }
}

