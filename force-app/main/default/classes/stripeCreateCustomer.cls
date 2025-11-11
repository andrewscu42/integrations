/** 
 * @description       : Use Queueable to create Stripe customers with minimal fields
 *  to reduce payload size. 
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
                String stripeCustomerId = stripeCreateCustomer.createStripeCustomer(contact);
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
    
    private static String createStripeCustomer(Contact contact) {
        String body = buildRequestBody(contact);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Stripe_API/v1/customers');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (isSuccessStatusCode(res.getStatusCode())) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('id');
        }
        
        return null;
    }
    
    private static String buildRequestBody(Contact contact) {
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
    
    private static Boolean isSuccessStatusCode(Integer statusCode) {
        return statusCode >= 200 && statusCode < 300;
    }
    
    public static void createCustomersFromContacts(Set<Id> contactIds) {
        System.enqueueJob(new stripeCreateCustomer(contactIds));
    }
    
    public static void processContacts(List<Contact> contacts) {
        if (contacts == null || contacts.isEmpty()) {
            throw new EmptyContactListException('The contact list cannot be null or empty.');
        }
        
        for (Contact contact : contacts) {
            if (String.isBlank(contact.Email)) {
                throw new MissingRequiredFieldException(
                    'Contact with Id ' + contact.Id + ' is missing required field: Email'
                );
            }
        }
        
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact contact : contacts) {
            String stripeCustomerId = findStripeCustomerIdByEmail(contact.Email);
            
            if (stripeCustomerId == null) {
                stripeCustomerId = createStripeCustomer(contact);
        
            } else {
                updateStripeCustomer(stripeCustomerId, contact);
            }
            contact.Stripe_Customer_ID__c = stripeCustomerId;
            contactsToUpdate.add(contact);
        }
        update contactsToUpdate;
    }

    private static String findStripeCustomerIdByEmail(String email) {
        HttpRequest req = new HttpRequest();
        String query = 'email:\'' + email + '\'';
        req.setEndpoint('callout:Stripe_API/v1/customers/search?query=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(req);
        if (!isSuccessStatusCode(res.getStatusCode())) {
            return null;
        }
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> data = (List<Object>) responseMap.get('data');
        if (data == null || data.isEmpty()) {
            return null;
        }
        Map<String, Object> customer = (Map<String, Object>) data[0];
        return (String) customer.get('id');
    }
    
    private static String updateStripeCustomerId(String stripeCustomerId, Contact contact) {
        String body = buildRequestBody(contact);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Stripe_API/v1/customers/' + stripeCustomerId);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (isSuccessStatusCode(res.getStatusCode())) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) responseMap.get('id');
        }
        
        return null;
    }
}

