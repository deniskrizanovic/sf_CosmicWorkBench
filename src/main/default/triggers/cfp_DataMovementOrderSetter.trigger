/**
 * Created by dkrizanovic on 11/7/2024.
 */

trigger cfp_DataMovementOrderSetter on cfp_Data_Movements__c (before insert, after update, before delete) {

    if(trigger.isInsert) {

        cfp_handleOrderSetting.doReorderForInsert(trigger.new);

    }

    if(trigger.isUpdate){
        cfp_handleOrderSetting.doReorderForUpdate(trigger.new, trigger.oldMap);
    }

}