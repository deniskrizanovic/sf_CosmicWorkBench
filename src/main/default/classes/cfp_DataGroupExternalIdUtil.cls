public with sharing class cfp_DataGroupExternalIdUtil {
    public static String buildExternalId(String systemContextToken, String objectName) {
        String contextPart = normalizeToken(systemContextToken);
        String namePart = normalizeToken(objectName);
        if (String.isBlank(contextPart) || String.isBlank(namePart)) {
            return null;
        }
        return contextPart + '|' + namePart;
    }

    public static String buildExternalIdFromDataGroup(cfp_DataGroups__c dg) {
        if (dg == null) {
            return null;
        }
        String contextName = dg.cfp_System_Context__r != null ? dg.cfp_System_Context__r.Name : null;
        return buildExternalId(contextName, dg.cfp_Object_Name__c);
    }

    public static String buildExternalIdFromDataGroupRef(String systemContextToken, String dataGroupRef) {
        return buildExternalId(systemContextToken, dataGroupRef);
    }

    public static String normalizeToken(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        String normalized = value.trim().toLowerCase();
        normalized = normalized.replaceAll('\\s+', ' ');
        return normalized;
    }
}
