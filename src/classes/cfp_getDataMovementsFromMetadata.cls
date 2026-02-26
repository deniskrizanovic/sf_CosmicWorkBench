/**
 * Created by dkrizanovic on 17/3/2025.
 */

public with sharing class cfp_getDataMovementsFromMetadata {

    static MetadataService.MetadataPort service = createService();
    public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }

    public static List<RelatedListInfo> getRelateListFromPageLayout(String layoutName) {

        MetadataService.Layout layout = (MetadataService.Layout) service.readMetadata('Layout', new String[]{
                layoutName
        }).getRecords()[0];

        //System.debug(layout.relatedLists);

        List<RelatedListInfo> relateds = new List<RelatedListInfo>();


        for (MetadataService.RelatedListItem rli : layout.relatedLists) {
            RelatedListInfo relatedList = new RelatedListInfo(rli.relatedList, rli.relatedList, rli.fields);
            relateds.add(relatedList);

        }

        //System.debug(relateds);

        return relateds;

    }


    public static void getDataMovementsFromFlexiPage(String flexipageName){

        List<RelatedListInfo> relateds = getRelatedListsFromFlexPage(flexipageName);
        getDataMovementsFromRelatedListInfo(relateds);

    }

    public static void getDataMovementsFromPageLayout(String layoutName){

        List<RelatedListInfo> relateds = getRelateListFromPageLayout(layoutName);
        getDataMovementsFromRelatedListInfo(relateds);

    }
    public static void getDataMovementsFromRelatedListInfo( List<RelatedListInfo> relateds) {

        DataMovementsStruct dm = new DataMovementsStruct();

        Integer orderGroupSeed = 1;
        for (RelatedListInfo rli : relateds) {
            //System.debug(rli.label);
            String datagroupName = extractEntityNameFromRelatedList(rli.label);
            dm.dataGroups.put(datagroupName, String.valueOf(rli.fields));

            List<Movement> moves = manufactureListViewMovementsForDataGroup(datagroupName, orderGroupSeed * 100);
            dm.movements.addAll(moves);
            orderGroupSeed++;

        }

        System.debug(dm);

    }

    private static List<cfp_getDataMovementsFromMetadata.Movement> manufactureListViewMovementsForDataGroup(String datagroupName, Integer orderGroup) {

        Movement readList = new Movement(orderGroup + 1, 'Read List of ' + datagroupName, 'R', datagroupName, 'ootb');
        Movement displayList = new Movement(orderGroup + 2, 'Display List of ' + datagroupName, 'X', datagroupName, 'listview');
        Movement clickSpecific = new Movement(orderGroup + 3, 'Click specific  ' + datagroupName, 'E', datagroupName, 'ootb');
        Movement readSpecific = new Movement(orderGroup + 4, 'Read ' + datagroupName + ' Details', 'R', datagroupName, 'ootb');
        Movement displaySpecific = new Movement(orderGroup + 5, 'Display ' + datagroupName + ' Details', 'X', datagroupName, 'Flexipage');

        List<Movement> moves = new List<Movement>();
        moves.add(readList);
        moves.add(displayList);
        moves.add(clickSpecific);
        moves.add(readSpecific);
        moves.add(displaySpecific);
        moves.sort();


        return moves;
    }


    /**
 * Extracts the entity name from a related list API name using regex pattern
 * For example, extracts "Contact" from "RelatedContactList"
 * @param relatedListName The API name of the related list
 * @return The extracted entity name or empty string if no match found
 */
    public static String extractEntityNameFromRelatedList(String relatedListName) {

        System.debug(relatedListName);
        if (String.isBlank(relatedListName)) {
            return 'blank';
        }

        // Pattern to match:
        // 1. Looks for "Related" prefix (case insensitive)
        // 2. Captures one or more word characters (letters, numbers, underscore)
        // 3. Followed by "List" suffix (case insensitive)
        Pattern p = Pattern.compile('(?i)Related(\\w+)List');
        Matcher m = p.matcher(relatedListName);

        if (m.find()) {
            return m.group(1); // Return the captured group (the entity name)
        }

        Pattern p2 = Pattern.compile('(?i)(\\w+)RelatedList');
        Matcher m2 = p2.matcher(relatedListName);

        if (m2.find()) {
            return m2.group(1); // Return the captured group (the entity name)
        }

        return 'noMatchfromRegex'; // Return empty string if no match found
    }

    public static List<RelatedListInfo> getRelatedListsFromFlexPage(String flexiPageName) {
        List<RelatedListInfo> relatedLists = new List<RelatedListInfo>();

        try {

            MetadataService.FlexiPage[] flexiPages =
                    (MetadataService.FlexiPage[]) service.readMetadata('FlexiPage', new List<String>{
                            flexiPageName
                    }).getRecords();

            if (flexiPages != null && flexiPages.size() > 0) {
                for (MetadataService.FlexiPage flexiPage : flexiPages) {
                    if (flexiPage.flexiPageRegions != null) {
                        for (MetadataService.FlexiPageRegion region : flexiPage.flexiPageRegions) {
                            if (region.componentInstances != null) {
                                for (MetadataService.ComponentInstance component : region.componentInstances) {
                                    if (component.componentName == 'lst:dynamicRelatedList' &&
                                            component.componentInstanceProperties != null) {

                                        String relatedListLabel = '';
                                        String relatedListApiName = '';
                                        List<String> fieldNames;

                                        for (MetadataService.ComponentInstanceProperty prop : component.componentInstanceProperties) {
                                            if (prop.name == 'relatedListLabel') {
                                                relatedListLabel = prop.value;
                                            } else if (prop.name == 'relatedListApiName') {
                                                relatedListApiName = prop.value;
                                            } else if (prop.name == 'relatedListFieldAliases') {
                                                //fieldNames = prop.value;
                                                fieldNames = new List<String>();
                                                if (prop.value != null) {
                                                    fieldNames = prop.value.split(',');
                                                    for (Integer i = 0; i < fieldNames.size(); i++) {
                                                        fieldNames[i] = fieldNames[i].trim();
                                                    }
                                                }
                                                //System.debug('fieldNames ' + fieldNames);
                                            }
                                        }

                                        // Add to result if both values are found
                                        if (relatedListLabel != null && relatedListApiName != null) {
                                            relatedLists.add(new RelatedListInfo(relatedListLabel, relatedListApiName, fieldNames));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error retrieving related lists: ' + e.getMessage());
        }

        //System.debug(relatedLists);
        return relatedLists;
    }


// Class to hold ListView field information
    public class ListViewFieldInfo {
        public String objectName;
        public String listViewName;
        public List<String> fields;

        public ListViewFieldInfo(String objectName, String listViewName, List<String> fields) {
            this.objectName = objectName;
            this.listViewName = listViewName;
            this.fields = fields;
        }
    }


    public class RelatedListInfo {
        public String label;
        public String apiName;
        public String[] fields;

        public RelatedListInfo(String label, String apiName, String[] fields) {
            this.label = label;
            this.apiName = apiName;
            this.fields = fields;
        }
    }

    public class DataMovementsStruct {
        public Map<String, String> dataGroups = new Map<String, String>();
        public List<Movement> movements = new List<Movement>();

    }

    public class Movement implements Comparable {
        public Integer order;
        public String name;
        public String movementType;
        public String DataGroup;
        public String implementationType;

        public Movement(Integer order, String name, String movementType, String DataGroup, String implementationType) {
            this.order = order;
            this.name = name;
            this.movementType = movementType;
            this.DataGroup = DataGroup;
            this.implementationType = implementationType;
        }

        public Integer compareTo(Object compareTo) {
            Movement compareToMovement = (Movement) compareTo;
            if (order > compareToMovement.order) return 1;
            if (order < compareToMovement.order) return -1;
            return 0;
        }
    }

}