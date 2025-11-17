public class PaymentLinkAction {
    
    public class PaymentLinkRequest {
        @InvocableVariable(label='Contact ID' description='The ID of the contact to generate a payment link for' required=true)
        public Id contactId;
    }
    
    public class PaymentLinkResponse {
        @InvocableVariable(label='Success Message' description='Message indicating the result of the operation')
        public String message;
        
        @InvocableVariable(label='Is Success' description='Indicates whether the operation was successful')
        public Boolean isSuccess;
    }
    
    @InvocableMethod(label='Generate Payment Link' description='Generates a payment link for a contact via Stripe. Can be used in Flows.')
    public static List<PaymentLinkResponse> generatePaymentLink(List<PaymentLinkRequest> requests) {
        List<PaymentLinkResponse> responses = new List<PaymentLinkResponse>();
        
        for (PaymentLinkRequest request : requests) {
            PaymentLinkResponse response = new PaymentLinkResponse();
            try {
                if (request.contactId == null) {
                    throw new EmptyContactListException('Contact ID is required.');
                }
                
                Set<Id> contactIds = new Set<Id>{ request.contactId };
                new ContactTriggerHandler().generatePaymentLinks(contactIds);
                
                response.message = 'Payment link generation queued successfully';
                response.isSuccess = true;
            } catch (Exception e) {
                response.message = 'Error: ' + e.getMessage();
                response.isSuccess = false;
            }
            responses.add(response);
        }
        
        return responses;
    }
    
    @AuraEnabled
    public static String generatePaymentLink(Id contactId) {
        try {
            Set<Id> contactIds = new Set<Id>{ contactId };
            new ContactTriggerHandler().generatePaymentLinks(contactIds);
            return 'Payment link generation queued successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String generatePaymentLinksForMultiple(List<Id> contactIds) {
        try {
            if (contactIds == null || contactIds.isEmpty()) {
                throw new EmptyContactListException('No contacts selected.');
            }
            new ContactTriggerHandler().generatePaymentLinks(new Set<Id>(contactIds));
            return 'Payment link generation queued for ' + contactIds.size() + ' contact(s)';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
}

