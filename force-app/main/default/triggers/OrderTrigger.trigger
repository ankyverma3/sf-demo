/**
 * @description Trigger for Order__c object to handle business logic
 * @author Salesforce Demo
 * @date 2024
 */
trigger OrderTrigger on Order__c (before insert, before update, after insert, after update, after delete) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            OrderTriggerHandler.handleBeforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            OrderTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OrderTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            OrderTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isDelete) {
            OrderTriggerHandler.handleAfterDelete(Trigger.old);
        }
    }
}
