@isTest
public class StripeFailureMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        res.setBody('{"error":{"type":"invalid_request_error","message":"Invalid email"}}');
        return res;
    }
}

