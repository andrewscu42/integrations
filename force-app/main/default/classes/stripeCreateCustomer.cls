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
        
        if (res.getStatusCode() == 200) {
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
    
    public static void createCustomersFromContacts(Set<Id> contactIds) {
        System.enqueueJob(new stripeCreateCustomer(contactIds));
    }
    
    /**
     * @description Processes a list of contacts by checking if a Stripe customer exists by email.
     * @param contacts List of Contact records to process (max 100)
     * @throws EmptyContactListException if contacts list is null or empty
     * @throws MissingRequiredFieldException if any contact is missing required fields (Email)
     */
    public static void processContacts(List<Contact> contacts) {
        // Validate contact list
        if (contacts == null || contacts.isEmpty()) {
            throw new EmptyContactListException('The contact list cannot be null or empty.');
        }
        
        // Validate required fields for each contact
        for (Contact contact : contacts) {
            if (String.isBlank(contact.Email)) {
                throw new MissingRequiredFieldException(
                    'Contact with Id ' + contact.Id + ' is missing required field: Email'
                );
            }
        }
        
        List<Contact> contactsToUpdate = new List<Contact>();
        
        for (Contact contact : contacts) {
            String stripeCustomerId = findStripeCustomerByEmail(contact.Email);
            
            if (stripeCustomerId != null) {
                updateStripeCustomer(stripeCustomerId, contact);
                contact.Stripe_Customer_ID__c = stripeCustomerId;
            } else {
                stripeCustomerId = createStripeCustomer(contact);
                if (stripeCustomerId != null) {
                    contact.Stripe_Customer_ID__c = stripeCustomerId;
                }
            }
            if (contact.Stripe_Customer_ID__c != null) {
                contactsToUpdate.add(contact);
            }
        }
        
        update contactsToUpdate;
    }
    
    /**
     * @description Searches for a Stripe customer by email address
     * @param email Email address to search for
     * @return Stripe Customer ID if found, null otherwise
     */
    private static String findStripeCustomerByEmail(String email) {
        HttpRequest req = new HttpRequest();
        // Use Stripe's search API to find customers by email
        String query = 'email:\'' + email + '\'';
        req.setEndpoint('callout:Stripe_API/v1/customers/search?query=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> data = (List<Object>) responseMap.get('data');
            
            // If customers found, return the first one's ID
            if (data != null && !data.isEmpty()) {
                Map<String, Object> customer = (Map<String, Object>) data[0];
                return (String) customer.get('id');
            }
        }
        
        return null;
    }
    
    /**
     * @description Updates an existing Stripe customer with contact data
     * @param stripeCustomerId The Stripe Customer ID to update
     * @param contact Contact record containing data to update
     * @return Updated Stripe Customer ID if successful, null otherwise
     */
    private static String updateStripeCustomer(String stripeCustomerId, Contact contact) {
        String body = buildRequestBody(contact);
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Stripe_API/v1/customers/' + stripeCustomerId);
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
}

