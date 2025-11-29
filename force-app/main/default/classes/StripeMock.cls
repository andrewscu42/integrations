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
    
    public static StripeMock longUrl() {
        return new StripeMock('long_url');
    }
    
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        String endpoint = req.getEndpoint();
        
        if (endpoint.contains('/customers/search')) {
            if (responseType == 'customerExists') {
                res.setStatusCode(200);
                res.setBody('{"object":"search_result","data":[{"id":"cus_existing123","object":"customer","email":"john.doe@example.com"}],"has_more":false}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"object":"search_result","data":[],"has_more":false}');
            }
            return res;
        }
        
        if (endpoint.contains('/payment_links')) {
            if (responseType == 'success') {
                res.setStatusCode(200);
                res.setBody('{"id":"plink_test123","object":"payment_link","url":"https://buy.stripe.com/test_link_123","active":true}');
            } else if (responseType == 'failure') {
                res.setStatusCode(400);
                res.setBody('{"error":{"type":"invalid_request_error","message":"Failed to create payment link"}}');
            } else if (responseType == 'long_url') {
                res.setStatusCode(200);
                String longUrl = 'https://example.com/' + 'x'.leftPad(240, 'x');
                res.setBody('{"id":"plink_long","object":"payment_link","url":"' + longUrl + '","active":true}');
            }
            return res;
        }
        
        if (endpoint.contains('/v1/customers') && !endpoint.contains('/customers/search')) {
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
        
        // Default fallback
        res.setStatusCode(200);
        res.setBody('{"id":"cus_test123","object":"customer","email":"john.doe@example.com"}');
        return res;
    }
}

