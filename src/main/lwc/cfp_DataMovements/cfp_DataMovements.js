import {LightningElement, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';

const columns = [
    {label: 'Name', fieldName: 'name', editable: true},
    {label: 'Movement Type', fieldName: 'movementType', editable: true},
    {label: 'Data Group', fieldName: 'dataGroup', editable: true},
    {label: 'Implementation Type', fieldName: 'implementationType', editable: true},
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                {label: 'Move Up', name: 'moveUp'},
                {label: 'Move Down', name: 'moveDown'}
            ]
        },
        label: 'Actions',
        fixedWidth: 100
    },
    { label: 'Comments', fieldName: 'comments', type: 'text', editable: true }
];


export default class cfp_DataMovements extends LightningElement {
    @track columns = columns;
    @track data = [];
    @track draftValues = [];

    connectedCallback() {
        // Initialize with some data
        this.data = [
            {
                id: 1,
                name: 'Initial Row',
                movementType: '',
                dataGroup: '',
                implementationType: ''
            }
        ];
    }

    handleAddRow() {
        const newRow = {
            id: this.data.length + 1,
            name: '',
            movementType: '',
            dataGroup: '',
            implementationType: '',
            comments: ''
        };
        this.data = [...this.data, newRow];
    }

    handleSave(event) {
        const updatedFields = event.detail.draftValues;

        let errorsObj = this.isRowValid(updatedFields);
        console.log('errorobj' + JSON.stringify(errorsObj));
        this.errors = errorsObj;



        console.log('updated fields' + JSON.stringify(updatedFields));

        // Create a map of id to updated fields
        const updatedFieldsMap = new Map(updatedFields.map(field => [field.id.toString(), field]));


        // Find the maximum id in the current data
        const maxId = Math.max(...this.data.map(row => parseInt(row.id)), 0);

        // Apply the edited fields to the data array or add new rows
        const updatedData = this.data.map(row => {
            const updatedField = updatedFieldsMap.get(row.id.toString());
            if (updatedField) {
                return {
                    ...row,
                    name: updatedField.name !== undefined ? updatedField.name : row.name,
                    movementType: updatedField.movementType !== undefined ? updatedField.movementType : row.movementType,
                    dataGroup: updatedField.dataGroup !== undefined ? updatedField.dataGroup : row.dataGroup,
                    implementationType: updatedField.implementationType !== undefined ? updatedField.implementationType : row.implementationType,
                    comments: updatedField.comments !== undefined ? updatedField.comments : row.comments
                };
            }
            return row;
        });
        console.log('after the edit map:' + JSON.stringify(updatedData));


        // Update the data in the component with a new array reference
        this.data = [...updatedData];

        console.log('now the data has been set:' + JSON.stringify(this.data));

        // Clear all draft values
        this.draftValues = [];

        // Optionally, you can add a success toast message here
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: JSON.stringify(this.data),
                variant: 'success'
            })
        );

        // return refreshApex(this.data);
    }


    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        const rowIndex = this.data.findIndex(dataRow => dataRow.id === row.id);

        if (actionName === 'moveUp' && rowIndex > 0) {
            this.swapRows(rowIndex, rowIndex - 1);
        } else if (actionName === 'moveDown' && rowIndex < this.data.length - 1) {
            this.swapRows(rowIndex, rowIndex + 1);
        }
    }

    swapRows(index1, index2) {
        const updatedData = [...this.data];
        [updatedData[index1], updatedData[index2]] = [updatedData[index2], updatedData[index1]];
        this.data = updatedData;

        console.log('rows swapped:' + JSON.stringify(this.data));
    }

    isRowValid(updatedFields) {
        const acceptedMovementTypeValues = ['x', 'r', 'w', 'e'];
        const acceptedImplementationValues = ['ootb', 'config', 'low-code', 'pro-code'];

        let hasError = false;

        let errorsObject = {rows: {}};
        updatedFields.forEach(row => {
            let fieldNames = [];
            let errorMessages = [];

            if (row.movementType && !acceptedMovementTypeValues.includes(row.movementType.toLowerCase())) {
                console.log('type error')
                hasError = true;
                fieldNames.push("movementType");
                errorMessages.push("Invalid movement type");
            }
            if (row.implementationType && !acceptedImplementationValues.includes(row.implementationType.toLowerCase())) {
                console.log('implementation error')
                hasError = true;
                fieldNames.push("implementationType");
                errorMessages.push('Invalid implementation type');
            }
            if (hasError) {

                errorsObject.rows = {
                    ...errorsObject.rows,
                    [row.id]: {
                        title: "we found " + errorMessages.length + " errors",
                        messages: errorMessages,
                        fieldNames: fieldNames
                    }
                }

            }
        });
        console.log('errorsobj')
        console.log(errorsObject)  // log the full errors object
        return errorsObject;
    }
}