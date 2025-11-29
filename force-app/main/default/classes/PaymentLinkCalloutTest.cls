@isTest
private class PaymentLinkCalloutTest {

    @isTest
    static void testGenerateLinkSuccess() {
        // Create a test Contact with all required data
        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;

        // Set mock for Stripe success payment link callout
        Test.setMock(HttpCalloutMock.class, StripeMock.success());
        Test.startTest();
        PaymentLinkCallout callout = new PaymentLinkCallout();
        String paymentLink = callout.generateLink(testContact);
        Test.stopTest();

        System.assertEquals('https://buy.stripe.com/test_link_123', paymentLink, 'Should return Stripe payment link');
    }

    @isTest
    static void testGenerateLinkFailure() {
        // Create a test Contact with all required data
        Contact testContact = new Contact(
            FirstName = 'Mark',
            LastName = 'Failure',
            Email = 'mark.failure@example.com',
            Stripe_Customer_ID__c = 'cus_test123'
        );
        insert testContact;

        // Set mock for Stripe failed payment link callout
        Test.setMock(HttpCalloutMock.class, StripeMock.failure());
        Test.startTest();
        PaymentLinkCallout callout = new PaymentLinkCallout();
        Boolean exceptionThrown = false;
        try {
            callout.generateLink(testContact);
        } catch (Exception e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Failed to create payment link'), 'Exception should be payment link error');
        }
        Test.stopTest();
        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for failed payment link');
    }
}