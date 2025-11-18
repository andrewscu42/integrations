@isTest
public class StripeMock implements HttpCalloutMock {
    private String responseType;
    
    private StripeMock(String responseType) {
        this.responseType = responseType;
    }
    
    public static StripeMock success() {
        return new StripeMock('success');
    }
    
    public static StripeMock failure() {
        return new StripeMock('failure');
    }
    
    public static StripeMock customerExists() {
        return new StripeMock('customerExists');
    }
    
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        if (responseType == 'success') {
            res.setStatusCode(200);
            res.setBody('{"id":"cus_test123","object":"customer","email":"john.doe@example.com"}');
        } else if (responseType == 'failure') {
            res.setStatusCode(400);
            res.setBody('{"error":{"type":"invalid_request_error","message":"Invalid email"}}');
        } else if (responseType == 'customerExists') {
            res.setStatusCode(400);
            res.setBody('{"error":{"type":"invalid_request_error","code":"resource_already_exists","message":"Customer already exists with this email"}}');
        }
        return res;
    }
}

