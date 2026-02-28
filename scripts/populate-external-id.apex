List<SObject> toUpdate = new List<SObject>();
for (cfp_System_Context__c sc : [SELECT Id FROM cfp_System_Context__c WHERE cfp_External_Id__c = NULL]) {
    sc.cfp_External_Id__c = sc.Id;
    toUpdate.add(sc);
}
for (cfp_FunctionalProcess__c fp : [SELECT Id FROM cfp_FunctionalProcess__c WHERE cfp_External_Id__c = NULL]) {
    fp.cfp_External_Id__c = fp.Id;
    toUpdate.add(fp);
}
for (cfp_DataGroups__c dg : [SELECT Id FROM cfp_DataGroups__c WHERE cfp_External_Id__c = NULL]) {
    dg.cfp_External_Id__c = dg.Id;
    toUpdate.add(dg);
}
for (cfp_Data_Movements__c dm : [SELECT Id FROM cfp_Data_Movements__c WHERE cfp_External_Id__c = NULL]) {
    dm.cfp_External_Id__c = dm.Id;
    toUpdate.add(dm);
}
update toUpdate;
System.debug('Updated ' + toUpdate.size() + ' records');
