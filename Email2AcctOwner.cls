trigger Email2AcctOwner on ccrz__E_Order__c (after insert) {
    
   Email2AcctOwnerHandler.handle(Trigger.New);
    
}