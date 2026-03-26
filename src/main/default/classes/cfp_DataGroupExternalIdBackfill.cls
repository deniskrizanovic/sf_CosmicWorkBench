public with sharing class cfp_DataGroupExternalIdBackfill {
    public class Result {
        public Integer scannedCount = 0;
        public Integer candidateUpdateCount = 0;
        public Integer updatedCount = 0;
        public Integer collisionCount = 0;
        public List<String> collisionKeys = new List<String>();
    }

    public static Result runBackfill(Boolean doUpdate) {
        List<cfp_DataGroups__c> dataGroups = [
            SELECT Id, Name, cfp_Object_Name__c, cfp_System_Context__c, cfp_System_Context__r.Name, cfp_External_Id__c
            FROM cfp_DataGroups__c
        ];

        Result result = new Result();
        result.scannedCount = dataGroups.size();

        Map<String, Integer> keyCounts = new Map<String, Integer>();
        Map<Id, String> expectedById = new Map<Id, String>();
        for (cfp_DataGroups__c dg : dataGroups) {
            String expected = cfp_DataGroupExternalIdUtil.buildExternalIdFromDataGroup(dg);
            expectedById.put(dg.Id, expected);
            if (!String.isBlank(expected)) {
                Integer current = keyCounts.containsKey(expected) ? keyCounts.get(expected) : 0;
                keyCounts.put(expected, current + 1);
            }
        }

        Set<String> collisionKeySet = new Set<String>();
        for (String key : keyCounts.keySet()) {
            if (keyCounts.get(key) > 1) {
                collisionKeySet.add(key);
            }
        }
        result.collisionCount = collisionKeySet.size();
        result.collisionKeys.addAll(collisionKeySet);
        result.collisionKeys.sort();

        List<cfp_DataGroups__c> updates = new List<cfp_DataGroups__c>();
        for (cfp_DataGroups__c dg : dataGroups) {
            String expected = expectedById.get(dg.Id);
            if (String.isBlank(expected) || collisionKeySet.contains(expected)) {
                continue;
            }
            if (dg.cfp_External_Id__c != expected) {
                result.candidateUpdateCount++;
                if (doUpdate == true) {
                    updates.add(new cfp_DataGroups__c(
                        Id = dg.Id,
                        cfp_External_Id__c = expected
                    ));
                }
            }
        }

        if (doUpdate == true && !updates.isEmpty()) {
            update updates;
            result.updatedCount = updates.size();
        }

        return result;
    }
}
