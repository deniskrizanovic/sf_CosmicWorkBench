/**
 * Tests for cfp_addDefaultDMsToFuncProcess flow.
 * Flow creates 5 default Data Movements when a Functional Process is created.
 * DataGroups are looked up by Name under System Context "Salesforce Platform Features".
 */
@IsTest
private class cfp_addDefaultDMsToFuncProcessTest {

    private static Map<String, Id> createDefaultDataGroupsSetup() {
        cfp_System_Context__c sysCtx = new cfp_System_Context__c(
            Name = 'Salesforce Platform Features'
        );
        insert sysCtx;

        List<cfp_DataGroups__c> dgs = new List<cfp_DataGroups__c>{
            new cfp_DataGroups__c(Name = 'trigger', cfp_System_Context__c = sysCtx.Id),
            new cfp_DataGroups__c(Name = 'Full Text Search', cfp_System_Context__c = sysCtx.Id),
            new cfp_DataGroups__c(Name = 'Field History', cfp_System_Context__c = sysCtx.Id),
            new cfp_DataGroups__c(Name = 'Event Monitoring Logs', cfp_System_Context__c = sysCtx.Id),
            new cfp_DataGroups__c(Name = 'status/errors/etc', cfp_System_Context__c = sysCtx.Id)
        };
        insert dgs;

        Map<String, Id> nameToId = new Map<String, Id>();
        for (cfp_DataGroups__c dg : dgs) {
            nameToId.put(dg.Name, dg.Id);
        }
        return nameToId;
    }

    @IsTest
    static void testDefaultDMsCreatedWithCorrectDataGroups() {
        Map<String, Id> dataGroupIds = createDefaultDataGroupsSetup();

        cfp_FunctionalProcess__c fp = new cfp_FunctionalProcess__c(Name = 'Flow Test FP');
        Test.startTest();
        insert fp;
        Test.stopTest();

        List<cfp_Data_Movements__c> dms = [
            SELECT Name, cfp_order__c, cfp_DataGroups__c, cfp_DataGroups__r.Name
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
            ORDER BY cfp_order__c ASC
        ];

        System.assertEquals(5, dms.size(), 'Expected 5 default DMs');

        Map<String, Id> expectedDataGroupByDmName = new Map<String, Id>{
            'Enter description of triggering Event' => dataGroupIds.get('trigger'),
            'write to Full Text Index' => dataGroupIds.get('Full Text Search'),
            'write to Field History' => dataGroupIds.get('Field History'),
            'write to Event Monitoring Logs' => dataGroupIds.get('Event Monitoring Logs'),
            'status/errors/etc' => dataGroupIds.get('status/errors/etc')
        };

        for (cfp_Data_Movements__c dm : dms) {
            Id expectedId = expectedDataGroupByDmName.get(dm.Name);
            System.assertEquals(expectedId, dm.cfp_DataGroups__c,
                'DM ' + dm.Name + ' should reference DataGroup ' + dm.cfp_DataGroups__r.Name);
        }
    }

    @IsTest
    static void testDefaultDMsHaveCorrectNamesAndOrder() {
        createDefaultDataGroupsSetup();

        cfp_FunctionalProcess__c fp = new cfp_FunctionalProcess__c(Name = 'Order Test FP');
        insert fp;

        List<cfp_Data_Movements__c> dms = [
            SELECT Name, cfp_order__c
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
            ORDER BY cfp_order__c ASC
        ];

        System.assertEquals(5, dms.size(), 'Expected 5 default DMs');

        List<Map<String, Object>> expected = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Name' => 'Enter description of triggering Event', 'Order' => 1 },
            new Map<String, Object>{ 'Name' => 'write to Full Text Index', 'Order' => 96 },
            new Map<String, Object>{ 'Name' => 'write to Field History', 'Order' => 97 },
            new Map<String, Object>{ 'Name' => 'write to Event Monitoring Logs', 'Order' => 98 },
            new Map<String, Object>{ 'Name' => 'status/errors/etc', 'Order' => 99 }
        };

        for (Integer i = 0; i < expected.size(); i++) {
            System.assertEquals(expected[i].get('Name'), dms[i].Name, 'DM name at index ' + i);
            System.assertEquals(expected[i].get('Order'), dms[i].cfp_order__c, 'DM order at index ' + i);
        }
    }

    @IsTest
    static void testDefaultDMsHaveCorrectMovementTypesAndImplementation() {
        createDefaultDataGroupsSetup();

        cfp_FunctionalProcess__c fp = new cfp_FunctionalProcess__c(Name = 'Types Test FP');
        insert fp;

        List<cfp_Data_Movements__c> dms = [
            SELECT Name, cfp_movementtype__c, cfp_implementationtype__c
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
            ORDER BY cfp_order__c ASC
        ];

        Map<String, Map<String, String>> expected = new Map<String, Map<String, String>>{
            'Enter description of triggering Event' => new Map<String, String>{ 'movement' => 'E', 'impl' => 'tbd' },
            'write to Full Text Index' => new Map<String, String>{ 'movement' => 'W', 'impl' => 'ootb' },
            'write to Field History' => new Map<String, String>{ 'movement' => 'W', 'impl' => 'ootb' },
            'write to Event Monitoring Logs' => new Map<String, String>{ 'movement' => 'W', 'impl' => 'ootb' },
            'status/errors/etc' => new Map<String, String>{ 'movement' => 'X', 'impl' => 'tbd' }
        };

        for (cfp_Data_Movements__c dm : dms) {
            Map<String, String> exp = expected.get(dm.Name);
            System.assertEquals(exp.get('movement'), dm.cfp_movementtype__c, 'Movement type for ' + dm.Name);
            System.assertEquals(exp.get('impl'), dm.cfp_implementationtype__c, 'Implementation for ' + dm.Name);
        }
    }

    @IsTest
    static void testDefaultDMsLinkedToFunctionalProcess() {
        createDefaultDataGroupsSetup();

        cfp_FunctionalProcess__c fp = new cfp_FunctionalProcess__c(Name = 'Link Test FP');
        insert fp;

        List<cfp_Data_Movements__c> dms = [
            SELECT cfp_FunctionalProcess__c
            FROM cfp_Data_Movements__c
            WHERE cfp_FunctionalProcess__c = :fp.Id
        ];

        System.assertEquals(5, dms.size(), 'Expected 5 default DMs');
        for (cfp_Data_Movements__c dm : dms) {
            System.assertEquals(fp.Id, dm.cfp_FunctionalProcess__c, 'DM should link to FP');
        }
    }
}
