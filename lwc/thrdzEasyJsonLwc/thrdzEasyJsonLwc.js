import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import jsoneditor from '@salesforce/resourceUrl/JsonEditorStaticResource';
import { loadStyle,loadScript } from 'lightning/platformResourceLoader';
import GetJsonString from '@salesforce/apex/EasyJsonController.getJSONString';
import GetObjects from '@salesforce/apex/EasyJsonController.getObjects';
import GetFields from '@salesforce/apex/EasyJsonController.getFields';
import GetRecordTypes from '@salesforce/apex/EasyJsonController.getSobjectRecordTypes';
import GetNamespacePrefix from '@salesforce/apex/MembrameMemory.getNamespacePrefix';




import { updateRecord } from 'lightning/uiRecordApi';

export default class ThrdzEasyJsonLwc extends LightningElement {

    @api fieldname;
    @api recordId;
    @api viewonlymode;
    @api savepretty;
    @api ismembrane;

    objects = [];
    fieldsmap = {};


    NAMESPACEPREFIX='';
    data = {};
    editor;
    jsonfields;

    saveJson(){
        //event.preventDefault(); 
        
        //let target ='[data-key="'+this.fieldname+'"]';
        //this.template.querySelector(target).value=JSON.stringify(this.editor.get());
        console.log('Save called:', this.NAMESPACEPREFIX+this.fieldname);

        const fields = {};
        fields['Id'] = this.recordId;

        if(this.savepretty){
            fields[this.NAMESPACEPREFIX+this.fieldname] = JSON.stringify(this.editor.get(),null,3);
        }
        else{
            fields[this.NAMESPACEPREFIX+this.fieldname] = JSON.stringify(this.editor.get());
        }
        console.log('this.data on save:', JSON.stringify(this.editor.get(),null,5));

        
        const recordInput = { fields };
        
        updateRecord(recordInput).then(() => {
                this.dispatchEvent(
                        new ShowToastEvent({
                                title: 'Success',
                                message: 'Record updated',
                                variant: 'success'
                        })
                );
        }).catch(error => {
            console.log('Error:',error);
                this.dispatchEvent(
                        new ShowToastEvent({
                                title: 'Error saving record',
                                message: error.body.message,
                                variant: 'error'
                        })
                );
        });
    }

    connectedCallback(){

        console.log('Connected Call');

        GetNamespacePrefix()
        .then((result) => {
            
            console.log('this.data after namespace fetch:',result);
            if(result!==undefined){
                this.NAMESPACEPREFIX = result;
            }
        }).catch((error) => {
            console.error('Something went wrong while fetching Namespaceprefix. Error:', error);
        });

        console.log('NAMESPACEPREFIX:'+this.NAMESPACEPREFIX);


        //this.fields = [this.fieldname];
        
        GetJsonString({currentRecordId:this.recordId,fieldapiname:this.NAMESPACEPREFIX+this.fieldname})
        .then((result) => {
            this.data = JSON.parse(result);
            console.log('this.data after JSON fetch:', this.data);
            if(this.data.length>0){

                this.currentRecordName = this.data[0].attributes.type;

                this.fieldJson = JSON.parse(decodeURI(this.data[0][this.NAMESPACEPREFIX+this.fieldname]));
                if(this.fieldJson == null) this.fieldJson={};
                console.log('Field JSON after escape:',this.fieldJson);
                //this.editor.updateText(this.fieldJson);
                if(this.ismembrane){
                    GetObjects()
                    .then((objresult) => {
                        
                        if(objresult.length>0){
                            this.objects = objresult;
                        }
                        else{
                            console.log('No objects found');
                            
                        }
                        this.initJsonEditor();

                    })
                    .catch((error) => {
                        console.error('Something went wrong while fetching Objects', error);
                    });
                }
                else{
                    this.initJsonEditor();
                }
            }
            else{
                console.log('No record found');
                
            }

        })
        .catch((error) => {
            console.error('Something went wrong while fetching JSON from:'+this.fieldname+'. Error:', error);
        });


        
        

    }

    /*
    @wire(getRecord, { recordId: '$recordId', fields: '$jsonfields'})
    getJson( {error, data} ) {
        if (error) {
            console.error('Something went wrong while fetching JSON from:'+this.fieldname+'. Error:', error);

        } else if(data){
            console.log('============== data:',data);
            this.data = JSON.parse(data);
            this.fieldJson = JSON.parse(decodeURI(this.data[0][this.fieldname]));
            if(this.fieldJson == null) this.fieldJson={};
            console.log('Field JSON after escape:',this.fieldJson);
            //this.editor.updateText(this.fieldJson);
            this.initJsonEditor();
        }
    }
    */

    

    renderedCallback(){
        console.log('Rendered Call');

        Promise.all([
            loadScript(this, jsoneditor + '/jsoneditor.min.js'),
            loadStyle(this,jsoneditor + '/jsoneditor.min.css')
        ]).then(() => {
            //this.initsvelteJsonEditor();
            
        })
        .catch(error => {
            console.log({message: 'Error onloading JSON Editor',error});
        });

        
    }


    initJsonEditor(){
        const container = this.template.querySelector('[data-id="'+'jsoneditor'+'"]');

        let objectoptions= this.objects;
        let fieldoptionsMap = {};

        let fieldoptions = [];
        let recordtypes = []


        let modes = [];
        let mode = 'view';
        modes.push('view');
        if(!this.viewonlymode){
            modes.push('tree');
            modes.push('code');
            modes.push('text');
            modes.push('form');
            modes.push('preview');

            mode = 'tree';
        }
  
        const options1 = {
            mode: mode,
            modes: modes,
            onModeChange: function (newMode, oldMode) {
                console.log('Mode switched from', oldMode, 'to', newMode)
            },
            autocomplete: {
                applyTo:['value'],
                filter: 'contain',
                trigger: 'focus',
                getOptions: function (text, path, input, editor) {
                    console.log('autocomplete triggered.'+text+'-'+path+'-'+input);
                    if(path.includes('sobject')){
                        return objectoptions;
                    }
                    if(path.includes('fieldapi') || path.includes('externalidfield') ||  path.includes('lookupfield') || path.includes('extrafields')){
                        console.log('fieldoptions:',fieldoptions);
                        return fieldoptions;
                    }
                    if(path.includes('defaultrecordtype')){
                        return recordtypes;
                    }
                    if(path.includes('namefieldtype')){
                        return ['AutoNumber','Text'];
                    }
                    if(path.includes('cartridgetype')){
                        return ['objectasis','text','array','object','number','multiselect'];
                    }
                    if(path.includes('fieldtype')){
                        return ['Lookup','MasterDetail','MetadataRelationship','Checkbox','Currency','Date','DateTime','Email','ExternalId','EncryptedText','ExternalLookup','Number','Percent','Phone','Picklist','MultiselectPicklist','Text','TextArea','LongTextArea','Url','Html','Location','Time'];
                        //'Hierarchy','IndirectLookup','Summary','File'
                    }
                }
            },
            /*
            autocomplete: {
                getOptions: function () {
                    return ['field_api1__c', 'Name', 'field_api2__c', 'Checkbox__c', 'Amount', 'mandarine', 'melon', 'appleton'];
                }
            },*/
            
            onEvent: function(node, event) {

                let runLogic = false;
                /*                
                var keyWhich = event.which;
                var keyCode = event.keyCode; // Detecting keyCode
                // Detecting Ctrl
                var ctrl = event.ctrlKey ? event.ctrlKey : ((keyCode === 17 || keyCode === 91 || keyCode === 93)? true : false);
                console.log("############## MS Copy Paste Check:"+ctrl+"["+event.keyCode+"]["+keyWhich+"]");
                */

                if(node.value !== undefined) {
                    /*
                    if(node.value?.length > 0 && event.type ==='blur' && node.field === 'defaultrecordtype'){
                        let rtresult =node.value;
                        let rtid = rtresult.substring(rtresult.indexOf('[')+1,rtresult.indexOf(']'));
                        console.log('============== RTID:'+rtid);
                        node.updateValue(rtid);
                    }
                    */

                    if(node.value?.length > 0 && event.type ==='blur' && node.field === 'sobject'){

                        if(fieldoptionsMap[node.value] === undefined){
                            console.log('Fetch fields for sobject:'+node.value);
                            fieldoptionsMap[node.value]=[];
                            GetFields({selectedSObject:node.value})
                            .then((fieldresult) => {
                                
                                if(fieldresult.length>0){
                                    console.log('=========== Fields list for:'+node.value+' - '+fieldresult);
                                    fieldoptionsMap[node.value].push(fieldresult);
                                    fieldoptions.push(...fieldresult);
                                }
                                else{
                                    console.log('No fields found');
                                    
                                }
                            })
                            .catch((error) => {
                                console.error('Something went wrong while fetching fields', error);
                            });

                            GetRecordTypes({selectedSObject:node.value})
                            .then((rtresult) => {
                                
                                if(rtresult.length>0){
                                    console.log('=========== Record Type list for:'+node.value+' - '+rtresult);
                                    recordtypes.push(...rtresult);
                                }
                                else{
                                    console.log('No Record Types found');
                                    
                                }
                            })
                            .catch((error) => {
                                console.error('Something went wrong while fetching record types', error);
                            });

                            
                        }
                        
                    }
                }
                
             
                
                if(runLogic){
                    if (node.value !== undefined) {

                        if(node.value?.length > 0 && event.type ==='blur' && node.field === 'sobject'){

                            if(fieldoptionsMap[node.value] === undefined){
                                console.log('Fetch fields for sobject:'+node.value);
                                fieldoptionsMap[node.value]=[];
                                GetFields({selectedSObject:node.value})
                                .then((fieldresult) => {
                                    
                                    if(fieldresult.length>0){
                                        console.log('=========== Fields list for:'+node.value+' - '+fieldresult);
                                        fieldoptionsMap[node.value].push(fieldresult);
                                        fieldoptions.push(...fieldresult);
                                    }
                                    else{
                                        console.log('No fields found');
                                        
                                    }
                                })
                                .catch((error) => {
                                    console.error('Something went wrong while fetching fields', error);
                                });
                            }
                            
                        }


                        
                        if(node.value?.length === 0 && event.type !=='mouseover'){
                            //event.target.innerText = 'Enter value';
                            event.target.classList.remove("jsoneditor-empty");

                            let keycode = event.keyCode;

                        

                            let valid = 
                                (keycode > 47 && keycode < 58)   || // number keys
                                keycode === 32 || keycode === 13 ||// spacebar & return key(s) (if you want to allow carriage returns)
                                (keycode > 64 && keycode < 91)   || // letter keys
                                (keycode > 95 && keycode < 112)  || // numpad keys
                                (keycode > 185 && keycode < 193) || // ;=,-./` (in order)
                                (keycode > 218 && keycode < 223);   // [\]' (in order)
                            if(valid){

                                node.value += event.key;
                                //event.target.innerText = '&#10072;';
                                event.target.innerText += event.key;
        
                                
                                let contentEditableElement = event.target;
                                let range,selection;
                                if(document.createRange)//Firefox, Chrome, Opera, Safari, IE 9+
                                {
                                    range = document.createRange();//Create a range (a range is a like the selection but invisible)
                                    range.selectNodeContents(contentEditableElement);//Select the entire contents of the element with the range
                                    range.collapse(false);//collapse the range to the end point. false means collapse to end rather than the start
                                    selection = window.getSelection();//get the selection object (allows you to change selection)
                                    selection.removeAllRanges();//remove any selections already made
                                    selection.addRange(range);//make the range you have just created the visible selection
                                }
                                else if(document.selection)//IE 8 and lower
                                { 
                                    range = document.body.createTextRange();//Create a range (a range is a like the selection but invisible)
                                    range.moveToElementText(contentEditableElement);//Select the entire contents of the element with the range
                                    range.collapse(false);//collapse the range to the end point. false means collapse to end rather than the start
                                    range.select();//Select the range (make it the visible selection
                                }

                                
                                event.stopPropagation();
                                event.preventDefault();
                            }
                            
                            
                        }
                        /*
                        console.log(event.type + ' event ' +
                            'on value ' + JSON.stringify(node.value) + ' ' +
                            'at path ' + JSON.stringify(node.path)
                        )
                        */
                    }else {


                        if(node.field?.length === 0 && event.type !=='mouseover'){
                            
                            event.target.classList.remove("jsoneditor-empty");

                            if(event.type!=='keyup'){
                                let keycode = event.keyCode;

                                let valid = 
                                    (keycode > 47 && keycode < 58)   || // number keys
                                    keycode === 32 || keycode === 13 || // spacebar & return key(s) (if you want to allow carriage returns)
                                    (keycode > 64 && keycode < 91)   || // letter keys
                                    (keycode > 95 && keycode < 112)  || // numpad keys
                                    (keycode > 185 && keycode < 193) || // ;=,-./` (in order)
                                    (keycode > 218 && keycode < 223);   // [\]' (in order)
                                if(valid){
                                    node.field += event.key;
                                    console.log('Node for event:'+event.type+' is - ',node);

                                    event.target.innerText += event.key;
                                    

                                    let contentEditableElement = event.target;
                                    let range,selection;
                                    if(document.createRange)//Firefox, Chrome, Opera, Safari, IE 9+
                                    {
                                        range = document.createRange();//Create a range (a range is a like the selection but invisible)
                                        range.selectNodeContents(contentEditableElement);//Select the entire contents of the element with the range
                                        range.collapse(false);//collapse the range to the end point. false means collapse to end rather than the start
                                        selection = window.getSelection();//get the selection object (allows you to change selection)
                                        selection.removeAllRanges();//remove any selections already made
                                        selection.addRange(range);//make the range you have just created the visible selection
                                    }
                                    else if(document.selection)//IE 8 and lower
                                    { 
                                        range = document.body.createTextRange();//Create a range (a range is a like the selection but invisible)
                                        range.moveToElementText(contentEditableElement);//Select the entire contents of the element with the range
                                        range.collapse(false);//collapse the range to the end point. false means collapse to end rather than the start
                                        range.select();//Select the range (make it the visible selection
                                    }

                                    event.stopPropagation();
                                    event.preventDefault();
                                    
                                }
                            }
                            
                        }
                        /*
                        console.log('MS Parent is:',node.path[node.path.length-2]);
                        
                        console.log(event.type + ' event ' +
                            'on field ' + JSON.stringify(node.field) + ' ' +
                            'at path ' + JSON.stringify(node.path)
                        )
                        */
                    }
                }
            }
        }
  
        this.editor = new JSONEditor(container, options1)
        
        this.editor.set(this.fieldJson)
  
    }
    

}