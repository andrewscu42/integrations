public with sharing class PaymentLinkCallout {
    public final static String GET_METHOD = 'GET';

    public String generateLink(Contact contact) {
        HttpRequest request = new HttpRequest();
        request.setMethod(GET_METHOD);
        request.setEndpoint('callout:Stripe_API/v1/payment_links');

        Http http = new Http();
        HttpResponse response = http.send(request);

        Map<String, Object> parsedBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> parsedPayer = (Map<String, Object>) parsedBody.get('payer');
        String paymentLink = (String) parsedPayer.get('link');

        return paymentLink;
    }
}

