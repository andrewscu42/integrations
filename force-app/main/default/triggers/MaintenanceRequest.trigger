trigger MaintenanceRequest on Case (after update) {
    List<Id> closedCaseIds = new List<Id>();
    for (Case c : Trigger.new) {
        if (c.Status == 'Closed' && (c.Type == 'Repair' || c.Type == 'Routine Maintenance') &&
            (Trigger.oldMap.get(c.Id).Status != 'Closed')) {
            closedCaseIds.add(c.Id);
        }
    }
    if (!closedCaseIds.isEmpty()) {
        MaintenanceRequestHelper.processMaintenanceRequests(closedCaseIds);
    }
}