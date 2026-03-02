/**
 * Created by dkrizanovic on 10/7/2024.
 */

@IsTest
private class cfp_DataMovementsOrderingTest {


    @TestSetup
    static void setup() {
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

        cfp_FunctionalProcess__c fp = new cfp_FunctionalProcess__c(Name = 'Test FP');
        insert fp;
    }

    @IsTest
    static void testCreationOfDefaultDataMovements() {

        cfp_FunctionalProcess__c fp = [select Id, Name,cfp_Total_Function_Points__c, cfp_incompleteSteps__c from cfp_FunctionalProcess__c where Name = 'Test FP'];

        List<cfp_Data_Movements__c> steps =  [select Name, cfp_order__c from cfp_Data_Movements__c where cfp_FunctionalProcess__c = :fp.Id];
        System.debug(steps);

        Assert.isTrue(fp <> null, 'there is an FP');
        Assert.isTrue(fp.cfp_Total_Function_Points__c == 3, 'there should only be 3 FP but was ' + fp.cfp_Total_Function_Points__c);
        Assert.isTrue(fp.cfp_incompleteSteps__c <> 0, 'the FP is not complete');

    }

    @IsTest
    static void testSingleInsertWithNoOrder() {
        cfp_FunctionalProcess__c fp = [SELECT Id, Name, cfp_Total_Function_Points__c FROM cfp_FunctionalProcess__c WHERE Name = 'Test FP'];

        cfp_Data_Movements__c step1 = new cfp_Data_Movements__c();
        step1.cfp_FunctionalProcess__c = fp.Id;
        step1.Name = 'Step 1';
        step1.cfp_implementationtype__c = 'Apex';

        insert step1;

        List<cfp_Data_Movements__c> stepsUpdated = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id AND cfp_order__c = 2];
        System.debug('order should be 2' + stepsUpdated);
        Assert.isTrue(stepsUpdated.size() == 1, 'there should only be one step with order 2');

        List<cfp_Data_Movements__c> allSteps = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id];
        System.debug('all steps' + allSteps);
        Assert.isTrue(allSteps.size() == 6, 'there should be 5 steps, but there was ' + allSteps.size());


    }


    @IsTest
    static void testMultiInsertWithNoOrder(){
        cfp_FunctionalProcess__c fp = [select Id, Name,cfp_Total_Function_Points__c from cfp_FunctionalProcess__c where Name = 'Test FP'];

        cfp_Data_Movements__c step1 = new cfp_Data_Movements__c();
        step1.cfp_FunctionalProcess__c = fp.Id;
        step1.Name = 'Step 1';
        step1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2 = new cfp_Data_Movements__c();
        step2.cfp_FunctionalProcess__c = fp.Id;
        step2.Name = 'Step 2';
        step2.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step3 = new cfp_Data_Movements__c();
        step3.cfp_FunctionalProcess__c = fp.Id;
        step3.Name = 'Step 3';
        step3.cfp_implementationtype__c = 'Apex';


        List<cfp_Data_Movements__c> stepsList = new List<cfp_Data_Movements__c>();
        stepsList.add(step1);
        stepsList.add(step2);
        stepsList.add(step3);

        insert stepsList;

        List<cfp_Data_Movements__c> steps = [select Name, cfp_order__c from cfp_Data_Movements__c where cfp_FunctionalProcess__c = :fp.Id and cfp_order__c < 90 order by cfp_order__c asc];
        System.debug('order should be 2' + steps);
        Assert.isTrue(steps.size() == 4, 'there should only be 3 steps created');

        Integer stepNumber = 1;
        for(cfp_Data_Movements__c step : steps) {
            if(step.cfp_order__c != stepNumber) {
                Assert.fail('order number should have been ' + stepNumber + 'for step' + step.Name + ' but was ' + step.cfp_order__c);
            }
            stepNumber++;
        }

        List<cfp_Data_Movements__c> allSteps = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id];
        System.debug('all steps' + allSteps);
        Assert.isTrue(allSteps.size() == 8, 'there should be 8 steps, but there was ' + allSteps.size());

    }


    @IsTest
    static void testChangingTheOrderDuringAnInsert(){
        cfp_FunctionalProcess__c fp = [select Id, Name,cfp_Total_Function_Points__c from cfp_FunctionalProcess__c where Name = 'Test FP'];

        cfp_Data_Movements__c step1 = new cfp_Data_Movements__c();
        step1.cfp_FunctionalProcess__c = fp.Id;
        step1.Name = 'Step 1';
        step1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2 = new cfp_Data_Movements__c();
        step2.cfp_FunctionalProcess__c = fp.Id;
        step2.Name = 'Step 2';
        step2.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step3 = new cfp_Data_Movements__c();
        step3.cfp_FunctionalProcess__c = fp.Id;
        step3.Name = 'Step 3';
        step3.cfp_implementationtype__c = 'Apex';


        List<cfp_Data_Movements__c> stepsList = new List<cfp_Data_Movements__c>();
        stepsList.add(step1);
        stepsList.add(step2);
        stepsList.add(step3);

        insert stepsList;

        List<cfp_Data_Movements__c> stepsBeforeInsertion = [select Name, cfp_order__c from cfp_Data_Movements__c where cfp_FunctionalProcess__c = :fp.Id and cfp_order__c < 90 order by cfp_order__c asc];
        System.debug('stepsBeforeInsertion' + stepsBeforeInsertion);

        cfp_Data_Movements__c insertAtStep = new cfp_Data_Movements__c();
        insertAtStep.cfp_FunctionalProcess__c = fp.Id;
        insertAtStep.Name = 'inserted at Step 2';
        insertAtStep.cfp_implementationtype__c = 'Apex';
        insertAtStep.cfp_order__c = 2;

        Test.startTest();
        insert insertAtStep;
        Test.stopTest();


        List<cfp_Data_Movements__c> steps = [select Name, cfp_order__c from cfp_Data_Movements__c where cfp_FunctionalProcess__c = :fp.Id and cfp_order__c < 90 order by cfp_order__c asc];
        System.debug('StepsAfterInsertion' + steps);
        Assert.isTrue(steps.size() == 5, 'there should only be 5 steps that are not default steps, except the triggering one');

        Integer stepNumber = 1;
        for(cfp_Data_Movements__c step : steps) {
            if(step.cfp_order__c != stepNumber) {
                Assert.fail('order number should have been ' + stepNumber + 'for step' + step.Name + ' but was ' + step.cfp_order__c);
            }
            stepNumber++;
        }

        List<cfp_Data_Movements__c> allSteps = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id];
        System.debug('all steps' + allSteps);
        Assert.isTrue(allSteps.size() == 9, 'there should be 9 steps, but there was ' + allSteps.size());

    }


    @IsTest
    static void testChangingTheOrderAtMultiplePointsDuringAnInsert(){
        cfp_FunctionalProcess__c fp = [SELECT Id, Name,cfp_Total_Function_Points__c FROM cfp_FunctionalProcess__c WHERE Name = 'Test FP'];

        cfp_Data_Movements__c step1 = new cfp_Data_Movements__c();
        step1.cfp_FunctionalProcess__c = fp.Id;
        step1.Name = 'Step 1';
        step1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2 = new cfp_Data_Movements__c();
        step2.cfp_FunctionalProcess__c = fp.Id;
        step2.Name = 'Step 2';
        step2.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step3 = new cfp_Data_Movements__c();
        step3.cfp_FunctionalProcess__c = fp.Id;
        step3.Name = 'Step 3';
        step3.cfp_implementationtype__c = 'Apex';


        List<cfp_Data_Movements__c> stepsList = new List<cfp_Data_Movements__c>();
        stepsList.add(step1);
        stepsList.add(step2);
        stepsList.add(step3);

        insert stepsList;

        List<cfp_Data_Movements__c> stepsBeforeInsertion = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id AND cfp_order__c < 90];
        System.debug('stepsBeforeInsertion' + stepsBeforeInsertion);

        cfp_Data_Movements__c insertAtStep2 = new cfp_Data_Movements__c();
        insertAtStep2.cfp_FunctionalProcess__c = fp.Id;
        insertAtStep2.Name = 'inserted at Step 2';
        insertAtStep2.cfp_implementationtype__c = 'Apex';
        insertAtStep2.cfp_order__c = 2;

        insert insertAtStep2;

        cfp_Data_Movements__c insertAtStep4 = new cfp_Data_Movements__c();
        insertAtStep4.cfp_FunctionalProcess__c = fp.Id;
        insertAtStep4.Name = 'inserted at Step 4';
        insertAtStep4.cfp_implementationtype__c = 'Apex';
        insertAtStep4.cfp_order__c = 4;

        insert insertAtStep4;

        List<cfp_Data_Movements__c> steps = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id AND cfp_order__c < 90 order by cfp_order__c asc];
        System.debug('StepsAfterInsertion' + steps);
        Assert.isTrue(steps.size() == 6, 'there should only be one 6 steps');

        Integer stepNumber = 1;
        for(cfp_Data_Movements__c step : steps) {
            if(step.cfp_order__c != stepNumber) {
                Assert.fail('order number should have been ' + stepNumber + 'for step' + step.Name + ' but was ' + step.cfp_order__c);
            }
            stepNumber++;
        }

        List<cfp_Data_Movements__c> allSteps = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id];
        System.debug('all steps' + allSteps);
        Assert.isTrue(allSteps.size() == 10, 'there should be 10 steps, but there was ' + allSteps.size());
    }


    @IsTest
    static void testInsertingMultipleProcessWithMultipleSteps() {
        cfp_FunctionalProcess__c fp1 = [SELECT Id, Name, cfp_Total_Function_Points__c FROM cfp_FunctionalProcess__c WHERE Name = 'Test FP' limit 1];

        cfp_Data_Movements__c step1fp1 = new cfp_Data_Movements__c();
        step1fp1.cfp_FunctionalProcess__c = fp1.Id;
        step1fp1.Name = 'FP1 - Step 1';
        step1fp1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2fp1 = new cfp_Data_Movements__c();
        step2fp1.cfp_FunctionalProcess__c = fp1.Id;
        step2fp1.Name = 'FP1 - Step 2';
        step2fp1.cfp_implementationtype__c = 'Apex';

        cfp_FunctionalProcess__c fp2 = new cfp_FunctionalProcess__c();
        fp2.Name = 'Test FP2';
        insert fp2;

        cfp_Data_Movements__c step1fp2 = new cfp_Data_Movements__c();
        step1fp2.cfp_FunctionalProcess__c = fp2.Id;
        step1fp2.Name = 'FP2 - Step 1';
        step1fp2.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2fp2 = new cfp_Data_Movements__c();
        step2fp2.cfp_FunctionalProcess__c = fp2.Id;
        step2fp2.Name = 'FP2 - Step 2';
        step2fp2.cfp_implementationtype__c = 'Apex';


        List<cfp_Data_Movements__c> multiSteps = new List<cfp_Data_Movements__c>();
        multiSteps.add(step1fp1);
        multiSteps.add(step2fp1);
        multiSteps.add(step1fp2);
        multiSteps.add(step2fp2);
        insert multiSteps;

        List<cfp_Data_Movements__c> stepsForFP1 = [SELECT Name, cfp_order__c, cfp_FunctionalProcess__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp1.Id AND cfp_order__c < 90 order by cfp_order__c asc];
        System.debug('StepsAfterInsertion for stepsForFP1' + stepsForFP1);
        Assert.isTrue(stepsForFP1.size() == 3, 'there should only be 3 steps');


        List<cfp_Data_Movements__c> stepsforFP2 = [SELECT Name, cfp_order__c, cfp_FunctionalProcess__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp2.Id AND cfp_order__c < 90 order by cfp_order__c asc];
        System.debug('StepsAfterInsertion fro stepsforFP2' + stepsforFP2);
        Assert.isTrue(stepsforFP2.size() == 3, 'there should only be 3 steps');

    }

    @IsTest
    static void testSingleUpdateToOrder() {
        cfp_FunctionalProcess__c fp = [SELECT Id, Name, cfp_Total_Function_Points__c FROM cfp_FunctionalProcess__c WHERE Name = 'Test FP' limit 1];

        cfp_Data_Movements__c step1fp1 = new cfp_Data_Movements__c();
        step1fp1.cfp_FunctionalProcess__c = fp.Id;
        step1fp1.Name = 'FP1 - Step 1';
        step1fp1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2fp1 = new cfp_Data_Movements__c();
        step2fp1.cfp_FunctionalProcess__c = fp.Id;
        step2fp1.Name = 'FP1 - Step 2';
        step2fp1.cfp_implementationtype__c = 'Apex';


        insert step1fp1;
        insert step2fp1;

        List<cfp_Data_Movements__c> steps = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id AND cfp_order__c < 90 order by cfp_order__c asc];

        System.debug(steps);

        //it's at index 2, because the first step is inserted by the default data movemement flow.
        cfp_Data_Movements__c step2 = steps.get(2);
        System.debug(step2.cfp_order__c);

        step2.cfp_order__c = 2;
        step2.Name = 'Step 2 Updated';

        update step2;

        List<cfp_Data_Movements__c> stepsAfterUpdate = [SELECT Name, cfp_order__c FROM cfp_Data_Movements__c WHERE cfp_FunctionalProcess__c = :fp.Id AND cfp_order__c < 90 order by cfp_order__c asc];

        System.debug(stepsAfterUpdate);

    }


    @IsTest
    static void testChangingTheOrderWithAnUpdateByMovingAStepUpTheOrder() {

        cfp_FunctionalProcess__c fp = [SELECT Id, Name, cfp_Total_Function_Points__c FROM cfp_FunctionalProcess__c WHERE Name = 'Test FP' limit 1];

        cfp_Data_Movements__c step1 = new cfp_Data_Movements__c();
        step1.cfp_FunctionalProcess__c = fp.Id;
        step1.Name = 'Step 1';
        step1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2 = new cfp_Data_Movements__c();
        step2.cfp_FunctionalProcess__c = fp.Id;
        step2.Name = 'Step 2';
        step2.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step3 = new cfp_Data_Movements__c();
        step3.cfp_FunctionalProcess__c = fp.Id;
        step3.Name = 'Step 3';
        step3.cfp_implementationtype__c = 'Apex';


        List<cfp_Data_Movements__c> stepsList = new List<cfp_Data_Movements__c>();
        stepsList.add(step1);
        stepsList.add(step2);
        stepsList.add(step3);

        insert stepsList;

        cfp_Data_Movements__c step3ToUpdate = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 3' and cfp_FunctionalProcess__c = :fp.Id];
        cfp_Data_Movements__c step2ToUpdate = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 2' and cfp_FunctionalProcess__c = :fp.Id];

        System.debug('step3 order is' + step3ToUpdate.cfp_order__c);
        System.debug('step2 order is' + step2ToUpdate.cfp_order__c);
        Test.startTest();

        step3ToUpdate.cfp_order__c = 3;
        update step3ToUpdate;

        List<cfp_Data_Movements__c> stepsUpdated = [select Name, cfp_order__c from cfp_Data_Movements__c where cfp_FunctionalProcess__c = :fp.Id];
        System.debug(stepsUpdated);
        Test.stopTest();

        cfp_Data_Movements__c postStep3 = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 3' and cfp_FunctionalProcess__c = :fp.Id];
        cfp_Data_Movements__c postStep2 = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 2' and cfp_FunctionalProcess__c = :fp.Id];

        Assert.isTrue(postStep2.cfp_order__c == 4, 'order of step 2 should be 4 but was ' + postStep2.cfp_order__c);
        Assert.isTrue(postStep3.cfp_order__c == 3, 'order of step 3 should be 3 but was ' + postStep3.cfp_order__c);


    }

    @IsTest
    static void testChangingTheOrderWithAnUpdateByMovingAStepDownTheOrder() {

        cfp_FunctionalProcess__c fp = [SELECT Id, Name, cfp_Total_Function_Points__c FROM cfp_FunctionalProcess__c WHERE Name = 'Test FP' limit 1];

        cfp_Data_Movements__c step1 = new cfp_Data_Movements__c();
        step1.cfp_FunctionalProcess__c = fp.Id;
        step1.Name = 'Step 1';
        step1.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step2 = new cfp_Data_Movements__c();
        step2.cfp_FunctionalProcess__c = fp.Id;
        step2.Name = 'Step 2';
        step2.cfp_implementationtype__c = 'Apex';

        cfp_Data_Movements__c step3 = new cfp_Data_Movements__c();
        step3.cfp_FunctionalProcess__c = fp.Id;
        step3.Name = 'Step 3';
        step3.cfp_implementationtype__c = 'Apex';


        List<cfp_Data_Movements__c> stepsList = new List<cfp_Data_Movements__c>();
        stepsList.add(step1);
        stepsList.add(step2);
        stepsList.add(step3);

        insert stepsList;


        cfp_Data_Movements__c step3toUpdate = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 3' and cfp_FunctionalProcess__c = :fp.Id];
        cfp_Data_Movements__c step2toUpdate = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 2' and cfp_FunctionalProcess__c = :fp.Id];

        System.debug('step3 order is' + step3toUpdate.cfp_order__c);
        System.debug('step2 order is' + step2toUpdate.cfp_order__c);
        Test.startTest();

        step2toUpdate.cfp_order__c = 4;
        update step2toUpdate;

        List<cfp_Data_Movements__c> stepsUpdated = [select Name, cfp_order__c from cfp_Data_Movements__c where cfp_FunctionalProcess__c = :fp.Id];
        System.debug(stepsUpdated);
        Test.stopTest();

        cfp_Data_Movements__c postStep3 = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 3' and cfp_FunctionalProcess__c = :fp.Id];
        cfp_Data_Movements__c postStep2 = [select Id, Name, cfp_order__c from cfp_Data_Movements__c where Name = 'Step 2' and cfp_FunctionalProcess__c = :fp.Id];

        Assert.isTrue(postStep2.cfp_order__c == 4, 'order of step 2 should be 4 but was ' + postStep2.cfp_order__c);
        Assert.isTrue(postStep3.cfp_order__c == 3, 'order of step 3 should be 3 but was ' + postStep3.cfp_order__c);


    }



}