/** 
 * @description       : Use Queueable to create Stripe customers with minimal fields
 *  to reduce payload size. 
 *
 * @author            : Andrew Scullion
**/

public class StripeCreateCustomerQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> contactIds;
    
    public StripeCreateCustomerQueueable(Set<Id> contactIds) {
        this.contactIds = contactIds;
    }
    
    public void execute(QueueableContext context) {
        ContactQueries contactQueries = new ContactQueries();
        List<Contact> contacts = contactQueries.queryContactsByIds(contactIds);
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact contact : contacts) {
            if (contact.Stripe_Customer_ID__c == null && contact.Email != null) {
                String stripeCustomerId = createStripeCustomer(contact);
                contact.Stripe_Customer_ID__c = stripeCustomerId;
                contactsToUpdate.add(contact);
            }
        }
        
        update contactsToUpdate;
    }
    
    public String createStripeCustomer(Contact contact) {
        String body = buildRequestBody(contact);
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Stripe_API/v1/customers');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(request);
        
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        
        return (String) responseMap.get('id');
    }
    
    private String findStripeCustomerIdByEmail(String email) {
        HttpRequest request = new HttpRequest();
        String query = 'email:\'' + email + '\'';
        request.setEndpoint('callout:Stripe_API/v1/customers/search?query=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        request.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(request);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> data = (List<Object>) responseMap.get('data');
        if (data == null || data.isEmpty()) {
            return null;
        }
        Map<String, Object> customer = (Map<String, Object>) data.get(0);
        return (String) customer.get('id');
    }
    
    private String updateStripeCustomer(String stripeCustomerId, Contact contact) {
        String body = buildRequestBody(contact);
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:Stripe_API/v1/customers/' + stripeCustomerId);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(request);
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) responseMap.get('id');
    }
    
    private String extractErrorMessage(Map<String, Object> responseMap, Integer statusCode) {
        Map<String, Object> error = (Map<String, Object>) responseMap.get('error');
        if (error != null) {
            String message = (String) error.get('message');
            String type = (String) error.get('type');
            return String.format('Status {0}: {1} ({2})', new List<Object>{statusCode, message, type});
        }
        return 'Status ' + statusCode;
    }
    
    private String buildRequestBody(Contact contact) {
        List<String> params = new List<String>();
        params.add('email=' + EncodingUtil.urlEncode(contact.Email, 'UTF-8'));
        
        String fullName = String.join(
            new List<String>{contact.FirstName, contact.LastName},
            ' '
        ).trim();
        
        if (fullName != '') {
            params.add('name=' + EncodingUtil.urlEncode(fullName, 'UTF-8'));
        }
        
        if (contact.MailingStreet != null) {
            params.add('address[line1]=' + EncodingUtil.urlEncode(contact.MailingStreet, 'UTF-8'));
        }
        
        if (contact.MailingPostalCode != null) {
            params.add('address[postal_code]=' + EncodingUtil.urlEncode(contact.MailingPostalCode, 'UTF-8'));
        }
        
        return String.join(params, '&');
    }
    
    public static void createCustomersFromContacts(Set<Id> contactIds) {
        System.enqueueJob(new StripeCreateCustomerQueueable(contactIds));
    }
}