@isTest
public class StripeCustomerExistsMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        res.setBody('{"error":{"type":"invalid_request_error","code":"resource_already_exists","message":"Customer already exists with this email"}}');
        return res;
    }
}

