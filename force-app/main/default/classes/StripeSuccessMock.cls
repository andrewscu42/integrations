@isTest
public class StripeSuccessMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"id":"cus_test123","object":"customer","email":"john.doe@example.com"}');
        return res;
    }
}

