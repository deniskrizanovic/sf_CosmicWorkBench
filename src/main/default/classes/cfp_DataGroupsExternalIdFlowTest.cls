@IsTest
private class cfp_DataGroupsExternalIdFlowTest {
    private static cfp_System_Context__c createSystemContext(String name) {
        cfp_System_Context__c sysCtx = new cfp_System_Context__c(Name = name);
        insert sysCtx;
        return sysCtx;
    }

    @IsTest
    static void testInsertPopulatesExternalId() {
        cfp_System_Context__c sysCtx = createSystemContext('Flow Insert Context');
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'WorkOrder',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = sysCtx.Id
        );
        insert dg;

        cfp_DataGroups__c insertedDg = [
            SELECT cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE Id = :dg.Id
        ];
        System.assertEquals(sysCtx.Name.toLowerCase() + '|workorder', insertedDg.cfp_External_Id__c,
            'Before-save flow should populate canonical external id on insert.');
    }

    @IsTest
    static void testUpdateRecomputesExternalId() {
        cfp_System_Context__c sysCtx = createSystemContext('Flow Update Context');
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'WorkOrder',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = sysCtx.Id
        );
        insert dg;

        dg.Name = 'Case';
        dg.cfp_Object_Name__c = 'Case';
        update dg;

        cfp_DataGroups__c updatedDg = [
            SELECT cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE Id = :dg.Id
        ];
        System.assertEquals(sysCtx.Name.toLowerCase() + '|case', updatedDg.cfp_External_Id__c,
            'Before-save flow should recompute external id when key fields change.');
    }

    @IsTest
    static void testExternalIdUsesObjectNameNotRecordName() {
        cfp_System_Context__c sysCtx = createSystemContext('Flow ObjectName Context');
        cfp_DataGroups__c dg = new cfp_DataGroups__c(
            Name = 'Work Orders (Custom Label)',
            cfp_Object_Name__c = 'WorkOrder',
            cfp_System_Context__c = sysCtx.Id
        );
        insert dg;

        cfp_DataGroups__c inserted = [
            SELECT cfp_External_Id__c
            FROM cfp_DataGroups__c
            WHERE Id = :dg.Id
        ];
        System.assertEquals(
            sysCtx.Name.toLowerCase() + '|workorder',
            inserted.cfp_External_Id__c,
            'External id should be keyed on cfp_Object_Name__c, not Name.'
        );
    }
}
