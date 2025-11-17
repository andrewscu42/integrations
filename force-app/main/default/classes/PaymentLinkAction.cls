public class PaymentLinkAction {
    @AuraEnabled
    public static String generatePaymentLink(Id contactId) {
        try {
            Set<Id> contactIds = new Set<Id>{ contactId };
            ContactTriggerHandler.generatePaymentLinks(contactIds);
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
            ContactTriggerHandler.generatePaymentLinks(new Set<Id>(contactIds));
            return 'Payment link generation queued for ' + contactIds.size() + ' contact(s)';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }
}

