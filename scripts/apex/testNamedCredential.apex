// Test script for Stripe Named Credential
// Execute this in VS Code by running: SFDX: Execute Anonymous Apex with Editor Contents
// Uses the Stripe_API Named Credential

System.debug('=== Testing Stripe API with Named Credential ===');

// Test 1: Simple GET request to verify connection
// Try to get account information (this is a simple endpoint to test)
HttpRequest req1 = new HttpRequest();
req1.setEndpoint('callout:Stripe_API/v1/account');
req1.setMethod('GET');

Http http1 = new Http();
HttpResponse res1 = http1.send(req1);

System.debug('=== Test 1: GET Account Info ===');
System.debug('Status Code: ' + res1.getStatusCode());
System.debug('Response Body: ' + res1.getBody());

if (res1.getStatusCode() == 200) {
    System.debug('✓ Stripe API connection successful!');
} else {
    System.debug('✗ Connection failed. Status: ' + res1.getStatusCode());
    System.debug('Error: ' + res1.getBody());
}

// Test 2: Create a fake British customer
System.debug('');
System.debug('=== Test 2: Create Fake British Customer ===');

HttpRequest req2 = new HttpRequest();
req2.setEndpoint('callout:Stripe_API/v1/customers');
req2.setMethod('POST');
req2.setHeader('Content-Type', 'application/x-www-form-urlencoded');

// Build British customer data with UK address format
// Reference: https://docs.stripe.com/api/customers
List<String> params = new List<String>();
params.add('email=james.smith@example.co.uk');
params.add('name=James+Smith');
params.add('phone=+442071234567');
params.add('description=Test+British+Customer');
params.add('address[line1]=10+Downing+Street');
params.add('address[city]=London');
params.add('address[postal_code]=SW1A+2AA');
params.add('address[country]=GB');

String body = String.join(params, '&');
req2.setBody(body);

Http http2 = new Http();
HttpResponse res2 = http2.send(req2);

System.debug('Status Code: ' + res2.getStatusCode());
System.debug('Response Body: ' + res2.getBody());

if (res2.getStatusCode() == 200) {
    System.debug('✓ British customer created successfully!');
    System.debug('Customer Details:');
    System.debug('  Name: James Smith');
    System.debug('  Email: james.smith@example.co.uk');
    System.debug('  Phone: +44 20 7123 4567');
    System.debug('  Address: 10 Downing Street, London, SW1A 2AA, GB');
} else {
    System.debug('✗ Failed to create customer. Status: ' + res2.getStatusCode());
    System.debug('Error: ' + res2.getBody());
}

System.debug('');
System.debug('=== Test Complete ===');
System.debug('Check your Stripe Dashboard at https://dashboard.stripe.com/test/customers');

