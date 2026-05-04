/**
 * Created by dkrizanovic on 11/7/2024.
 */

public with sharing class cfp_handleOrderSetting {

    //This set stores all the Id's of the steps whose modification is managed by the Salesforce trigger framework
    public static Set<Id> stepsPreviouslyVisitedDuringTransaction = new Set<Id>();
    static Boolean haveIRunBefore = false;
    public static List<cfp_Data_Movements__c> allTriggerContext = new List<cfp_Data_Movements__c>();
    //Suppress recursive trigger work while we are renumbering siblings during an insert.
    public static Boolean isReorderingInProgress = false;


    public static void doReorderForUpdate(List<cfp_Data_Movements__c> updatedStepFromTrigger, Map<Id, cfp_Data_Movements__c> oldStepsMap) {

        if (isReorderingInProgress) {
            return;
        }

        System.debug('starting update');
        Set<Id> debuggingStepsDMLManagedByTriggerFramework = new Set<Id>(stepsPreviouslyVisitedDuringTransaction);
        List<cfp_Data_Movements__c> debuggingAllTriggerContext = new List<cfp_Data_Movements__c>(allTriggerContext);

        System.debug('previoslyModifed-atstart ' + stepsPreviouslyVisitedDuringTransaction);

        if (haveIRunBefore) {
            System.debug('I have run before for update');
            return; //now this is a brute force way to avoid recursion, and I may regret it in the future. But it works.
        }

        if(updateStepsFromTriggerHaveAllPreviouslyBeenVisited(updatedStepFromTrigger)) {
            System.debug('all previously visited, so no need to do anything');
            return;
        }

        List<cfp_Data_Movements__c> listForUpsertion = new List<cfp_Data_Movements__c>();

        Map<Id, List<cfp_Data_Movements__c>> existingStepsMap = createMapFromExistingSteps(updatedStepFromTrigger);

        for (cfp_Data_Movements__c updatedStep : updatedStepFromTrigger) {


            System.debug('currently working on ' + simpleDebug(updatedStep));
            System.debug('has this been previously worked on?' + stepsPreviouslyVisitedDuringTransaction);
            if (stepsPreviouslyVisitedDuringTransaction.contains(updatedStep.Id)) {
                System.debug('found id in previous updates:' + simpleDebug(updatedStep));
                System.debug(stepsPreviouslyVisitedDuringTransaction);
                System.debug('will now skip this step');
                continue;
            }
            List<cfp_Data_Movements__c> existingSteps = existingStepsMap.get(updatedStep.cfp_FunctionalProcess__c);

            cfp_Data_Movements__c oldStep = (cfp_Data_Movements__c) oldStepsMap.get(updatedStep.Id);

            cfp_Data_Movements__c currentStepFromTriggerContext = getCurrentStepFromTriggerContext(updatedStep);

//            if (currentStepFromTriggerContext != null) {
//                System.debug('is updated step in trigger context?' + allTriggerContext.contains(updatedStep) + ':' + simpleDebug(updatedStep));
//                if (updatedStep.cfp_order__c <> currentStepFromTriggerContext.cfp_order__c) {
//                    System.debug('currentStep not same as trigger context - what does this mean?');
//                }
//            } else {

                if (updatedStep.cfp_order__c <> oldStep.cfp_order__c && !stepsPreviouslyVisitedDuringTransaction.contains(updatedStep.Id)) {
                    System.debug('Going to adjust the order of the step because ' + simpleDebug(updatedStep) + 'is different from the old step:' + simpleDebug(oldStep));
                    if(updatedStep.cfp_order__c > oldStep.cfp_order__c) {
                        removeStepFromExistingList(oldStep, existingSteps);
                    }else {
                        removeStepFromExistingList(updatedStep, existingSteps);
                    }
                    System.debug('Just before the adjustment the existing steps are' + simpleDebug(existingSteps));
                    if(existingSteps.size() > updatedStep.cfp_order__c -1) {

                        Decimal indexForInsertion =  updatedStep.cfp_order__c - 1;
                        System.debug('adding to the list at position:' + indexForInsertion + ':' +  simpleDebug(updatedStep));
                        existingSteps.add(Integer.valueOf(updatedStep.cfp_order__c - 1), updatedStep);
                    }
                    else {
                        System.debug('adding to the end of the list' + simpleDebug(updatedStep));
                        existingSteps.add(updatedStep);
                    }

                    stepsPreviouslyVisitedDuringTransaction.add(oldStep.Id);
                    System.debug('adjusted the existing steps and added to previously Visited list:' + simpleDebug(existingSteps));

                }

            //}
        }

        for (Id functionalProcessId : existingStepsMap.keySet()) {
            List<cfp_Data_Movements__c> stepsToBeSortedInAFunctionalProcess = existingStepsMap.get(functionalProcessId);

            System.debug('after addition the size of the list is:' + stepsToBeSortedInAFunctionalProcess.size());

            List<cfp_Data_Movements__c> listToBeInserted = stampNewOrderOnStepsAndReturnOnlyThoseNeedingSaving(stepsToBeSortedInAFunctionalProcess, updatedStepFromTrigger);
            listForUpsertion.addAll(listToBeInserted);
        }

        allTriggerContext.addAll(updatedStepFromTrigger);
        System.debug('justAddedToTriggerContextFromUpdate:' + allTriggerContext.size() + ':' + simpleDebug(allTriggerContext));
        if (listForUpsertion.size() > 0) {
            System.debug('about to upsert and my previous state is' + stepsPreviouslyVisitedDuringTransaction);
            System.debug('about to upsert' + simpleDebug(listForUpsertion));
            upsert listForUpsertion;
            System.debug('after update dml now with Ids' + simpleDebug(listForUpsertion));
        } else {
            System.debug('no steps to upsert');
        }
        haveIRunBefore = true;


    }

    private static Boolean updateStepsFromTriggerHaveAllPreviouslyBeenVisited(List<cfp_Data_Movements__c> stepsFromTrigger) {

        Boolean allPreviousStepsHaveBeenVisited = true;

        for(cfp_Data_Movements__c step : stepsFromTrigger) {
            if(!stepsPreviouslyVisitedDuringTransaction.contains(step.Id)) {
                allPreviousStepsHaveBeenVisited = false;
            }
        }

        return allPreviousStepsHaveBeenVisited;
    }

    private static String simpleDebug(cfp_Data_Movements__c step) {
        return '[' + step.Id + ':' + step.Name + ':' + step.cfp_order__c + ']';
    }

    private static String simpleDebug(List<cfp_Data_Movements__c> steps) {
        String s = '';

        for (cfp_Data_Movements__c step : steps) {
            s += simpleDebug(step);
        }
        return s;
    }

    private static cfp_Data_Movements__c getCurrentStepFromTriggerContext(cfp_Data_Movements__c currentStep) {

        System.debug('getCurrentStepFromTriggerContext for:' + simpleDebug(currentStep));
        System.debug('getCurrentStepFromTriggerContext-> allTriggerContext:' + simpleDebug(allTriggerContext));
        for (cfp_Data_Movements__c step : allTriggerContext) {
            if (step.Id == currentStep.Id) {
                return step;
            }
        }
        return null;
    }

    private static void removeStepFromExistingList(cfp_Data_Movements__c oldStep, List<cfp_Data_Movements__c> existingSteps) {

        List<cfp_Data_Movements__c> listForIteration = new List<cfp_Data_Movements__c>(existingSteps);
        for (cfp_Data_Movements__c s : listForIteration) {
            if (s.Id == oldStep.Id) {
                Integer indexForRemoval = listForIteration.indexOf(s);
                cfp_Data_Movements__c removed = existingSteps.remove(indexForRemoval);
                System.debug('This step was removed from the list - ' + simpleDebug(removed));
                // stepsDMLManagedByTriggerFramework.add(removed.Id);
            }
        }
    }


    public static void doReorderForInsert(List<cfp_Data_Movements__c> newStepsFromTrigger) {

        if (isReorderingInProgress) {
            return;
        }

        allTriggerContext.addAll(newStepsFromTrigger);

        Set<Id> functionalProcessIds = new Set<Id>();
        for (cfp_Data_Movements__c s : newStepsFromTrigger) {
            if (s.cfp_FunctionalProcess__c != null) {
                functionalProcessIds.add(s.cfp_FunctionalProcess__c);
            }
        }

        if (functionalProcessIds.isEmpty()) {
            return;
        }

        Map<Id, List<cfp_Data_Movements__c>> existingByFp = new Map<Id, List<cfp_Data_Movements__c>>();
        for (cfp_Data_Movements__c s : [
                SELECT Id, Name, cfp_order__c, cfp_FunctionalProcess__c
                FROM cfp_Data_Movements__c
                WHERE cfp_FunctionalProcess__c IN :functionalProcessIds
                AND cfp_order__c < 90
                ORDER BY cfp_FunctionalProcess__c, cfp_order__c
        ]) {
            if (!existingByFp.containsKey(s.cfp_FunctionalProcess__c)) {
                existingByFp.put(s.cfp_FunctionalProcess__c, new List<cfp_Data_Movements__c>());
            }
            existingByFp.get(s.cfp_FunctionalProcess__c).add(s);
        }

        Map<Id, List<cfp_Data_Movements__c>> newByFp = new Map<Id, List<cfp_Data_Movements__c>>();
        for (cfp_Data_Movements__c s : newStepsFromTrigger) {
            if (!newByFp.containsKey(s.cfp_FunctionalProcess__c)) {
                newByFp.put(s.cfp_FunctionalProcess__c, new List<cfp_Data_Movements__c>());
            }
            newByFp.get(s.cfp_FunctionalProcess__c).add(s);
        }

        List<cfp_Data_Movements__c> existingNeedingUpdate = new List<cfp_Data_Movements__c>();

        for (Id fpId : newByFp.keySet()) {
            List<cfp_Data_Movements__c> existing = existingByFp.containsKey(fpId)
                    ? existingByFp.get(fpId)
                    : new List<cfp_Data_Movements__c>();

            //Initial creation - no siblings to renumber against.
            if (existing.isEmpty()) {
                continue;
            }

            List<cfp_Data_Movements__c> incoming = newByFp.get(fpId);

            //Stable sort the incoming records: ones with an explicit cfp_order__c first
            //(asc), then any null-order ones at the end. Use a simple selection-style
            //pass since Apex List<SObject>.sort() can't take a comparator without a
            //Comparable wrapper class.
            List<cfp_Data_Movements__c> incomingWithOrder = new List<cfp_Data_Movements__c>();
            List<cfp_Data_Movements__c> incomingWithoutOrder = new List<cfp_Data_Movements__c>();
            for (cfp_Data_Movements__c n : incoming) {
                if (n.cfp_order__c == null) {
                    incomingWithoutOrder.add(n);
                } else {
                    incomingWithOrder.add(n);
                }
            }
            incomingWithOrder = sortByOrderAsc(incomingWithOrder);

            //Build the merged sequence. Because we're in BEFORE INSERT we mutate
            //`incoming` records' cfp_order__c directly so the DB write reflects the
            //renumber without us having to update them ourselves. The existing rows
            //get collected into `existingNeedingUpdate` and persisted via a guarded
            //update at the end.
            List<cfp_Data_Movements__c> merged = new List<cfp_Data_Movements__c>(existing);
            for (cfp_Data_Movements__c n : incomingWithOrder) {
                Integer insertIndex = Integer.valueOf(n.cfp_order__c) - 1;
                if (insertIndex < 0) {
                    insertIndex = 0;
                }
                if (insertIndex > merged.size()) {
                    insertIndex = merged.size();
                }
                merged.add(insertIndex, n);
            }
            for (cfp_Data_Movements__c n : incomingWithoutOrder) {
                merged.add(n);
            }

            //Renumber 1..N. For incoming records mutate in place; for existing
            //records only stage an update if the order actually changed.
            Integer pos = 1;
            for (cfp_Data_Movements__c step : merged) {
                if (step.Id == null) {
                    step.cfp_order__c = pos;
                } else if (step.cfp_order__c != pos) {
                    step.cfp_order__c = pos;
                    existingNeedingUpdate.add(step);
                }
                pos++;
            }
        }

        if (!existingNeedingUpdate.isEmpty()) {
            isReorderingInProgress = true;
            try {
                update existingNeedingUpdate;
            } finally {
                isReorderingInProgress = false;
            }
            for (cfp_Data_Movements__c s : existingNeedingUpdate) {
                stepsPreviouslyVisitedDuringTransaction.add(s.Id);
            }
        }
    }

    private static List<cfp_Data_Movements__c> sortByOrderAsc(List<cfp_Data_Movements__c> input) {
        List<cfp_Data_Movements__c> result = new List<cfp_Data_Movements__c>(input);
        for (Integer i = 1; i < result.size(); i++) {
            cfp_Data_Movements__c key = result[i];
            Integer j = i - 1;
            while (j >= 0 && result[j].cfp_order__c > key.cfp_order__c) {
                result[j + 1] = result[j];
                j--;
            }
            result[j + 1] = key;
        }
        return result;
    }


    private static List<cfp_Data_Movements__c> stampNewOrderOnStepsAndReturnOnlyThoseNeedingSaving(List<cfp_Data_Movements__c> existingSteps, List<cfp_Data_Movements__c> stepsInTrigger) {

        List<cfp_Data_Movements__c> stepsNeedingSavingOutsideOfSalesforceTriggerFramework = new List<cfp_Data_Movements__c>();
        Integer i = 1;

        System.debug('reordering and this is what I have:' + stepsPreviouslyVisitedDuringTransaction);
        System.debug('reordering and this is what I have before the reorder:' + simpleDebug(existingSteps));
        for (cfp_Data_Movements__c step : existingSteps) {


            if(stepsPreviouslyVisitedDuringTransaction.contains(step.Id) && !stepsInTrigger.contains(step)) {
                System.debug('found step in my avoidList:' + step.Id);
                //continue;  this should not be here.. When I'm reordering, I've already skipped them

            }
            if (step.cfp_order__c <> i) {

                if (allTriggerContext.contains(step)) {
                    System.debug('found step in trigger context:' + step.Id);
                    cfp_Data_Movements__c stepInTrigger = allTriggerContext.get(allTriggerContext.indexOf(step));
                    stepInTrigger.cfp_order__c = i;
                } else {
                    System.debug('about to reorder the step to :' + i + ':' + simpleDebug(step));
                    step.cfp_order__c = i;

                    if (!stepsInTrigger.contains(step) || !stepsPreviouslyVisitedDuringTransaction.contains(step.Id)) {
                        System.debug('adding to list of steps needing saving:' + simpleDebug(step));
                        stepsNeedingSavingOutsideOfSalesforceTriggerFramework.add(step);
                        stepsPreviouslyVisitedDuringTransaction.add(step.Id);
                    }
                }
            }
            i++;
        }
        System.debug('my reordered list:' + simpleDebug(existingSteps));
        System.debug('stepsNeedingSaving:' + simpleDebug(stepsNeedingSavingOutsideOfSalesforceTriggerFramework));
        return stepsNeedingSavingOutsideOfSalesforceTriggerFramework;
    }

    private static Boolean newStepExistsInExistingSteps(cfp_Data_Movements__c newStep, List<cfp_Data_Movements__c> existingSteps) {

        for (cfp_Data_Movements__c s : existingSteps) {
            if (s.Id == newStep.Id) {
                return true;
            }
        }

        return false;
    }

    private static Map<Id, List<cfp_Data_Movements__c>> createMapFromExistingSteps(List<cfp_Data_Movements__c> dkFunctionalsteps) {
        Map<Id, List<cfp_Data_Movements__c>> mapOfFunctionalStepsByFunctionalProcess;

        List<Id> functionalProcessIdsList = new List<Id>();
        for (cfp_Data_Movements__c aStep : dkFunctionalsteps) {
            functionalProcessIdsList.add(aStep.cfp_FunctionalProcess__c);
        }

        System.debug('ids we are going to retrieve for building the Map' + functionalProcessIdsList);

        List<cfp_Data_Movements__c> existingSteps = [
                SELECT Id, Name, cfp_order__c, cfp_FunctionalProcess__c
                FROM cfp_Data_Movements__c
                WHERE cfp_FunctionalProcess__c = :functionalProcessIdsList
                AND cfp_order__c < 90 //remove any of the default steps that are at the end, but leave the first to run through this code
                ORDER BY cfp_FunctionalProcess__c, cfp_order__c
        ];

        System.debug('Number of steps in the database' + existingSteps.size());
        if (existingSteps.size() > 0) {
            mapOfFunctionalStepsByFunctionalProcess = new Map<Id, List<cfp_Data_Movements__c>>();
        }

        for (cfp_Data_Movements__c aStep : existingSteps) {
            if (mapOfFunctionalStepsByFunctionalProcess.get(aStep.cfp_FunctionalProcess__c) == null) {
                mapOfFunctionalStepsByFunctionalProcess.put(aStep.cfp_FunctionalProcess__c, new List<cfp_Data_Movements__c>());
            }
            mapOfFunctionalStepsByFunctionalProcess.get(aStep.cfp_FunctionalProcess__c).add(aStep);

        }
        return mapOfFunctionalStepsByFunctionalProcess;
    }
}