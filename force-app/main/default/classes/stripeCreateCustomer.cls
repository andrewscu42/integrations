/** 
 * @description       : Use Queueable to create Stripe customers with minimal fields
 *  to reduce payload size. Idempotent check prevents duplicate Stripe customer creation.
 *
 * @author            : Andrew Scullion
**/

public class stripeCreateCustomer implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> contactIds;
    
    public stripeCreateCustomer(Set<Id> contactIds) {
        this.contactIds = contactIds;
    }
    
    public void execute(QueueableContext context) {
        List<Contact> contacts = queryContacts(contactIds);
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact contact : contacts) {
            if (contact.Stripe_Customer_ID__c == null && contact.Email != null) {
                String stripeCustomerId = createStripeCustomer(contact);
                if (stripeCustomerId != null) {
                    contact.Stripe_Customer_ID__c = stripeCustomerId;
                    contactsToUpdate.add(contact);
                }
            }
        }
        
        update contactsToUpdate;
    }
    
    private List<Contact> queryContacts(Set<Id> contactIds) {
        return [
            SELECT Id, FirstName, LastName, Email, MailingStreet, MailingPostalCode, Stripe_Customer_ID__c
            FROM Contact
            WHERE Id IN :contactIds
        ];
    }
    
    private String createStripeCustomer(Contact contact) {
        String body = buildRequestBody(contact);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Stripe_API/v1/customers');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('id');
        }
        
        return null;
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
        System.enqueueJob(new stripeCreateCustomer(contactIds));
    }
}

