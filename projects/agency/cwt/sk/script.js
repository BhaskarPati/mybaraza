var objTerminalEmulation;
var allCommands='';
var concatChar;
var allErrors = new Array();

//To retrieve mapping character
function getMappingChar() {
	var objFile;
	var objLM;
	concatChar='+';

	try {
		objFile= new ActiveXObject("File.FileObj");
		objLM= new ActiveXObject("LOCATIONMGR.Dirs");
		var filePath= objLM.MachineDir+'dat32com.ini'; 
		if(objFile.Exists( filePath)) {
			var fileData= objFile.ReadFileText(filePath);
			if(/\[DefaultConnection\](.|\n)*?UsesSpecialCharacters\s*=\s*1/.test(fileData))
				concatChar='|';
			return concatChar;
		}
	} catch(e) {
		alert('Get Mapping character: '+e.message);
	}
	finally {
		delete objFile;
		delete objLM;
	}
}

//concatChar = getMappingChar();	// Get mapping character
concatChar =  '+';
  
  //Adds current command to global string
function addCommand(strCommand) {
	allCommands += concatChar + strCommand;
	return allCommands;
}

//Checks the validity of command string. If the string exceeds max length (1024) or total commands exceed max. length (29), the command is broken into left and right string and left is executed while right goes as argument to same function i recursion.
//The left part is executed as terminal command.
function fireCrypticCommand(strCrypticCommand,concatChar) {
		allCommands='';

		if(concatChar=='+') 
			strCrypticCommand=strCrypticCommand.replace(/^\+/,'') 	//Replace the + in front
		else
			strCrypticCommand=strCrypticCommand.replace(/^\|/,'') 	//Replace the | in front
			
        var returnValue;

        var endItemPos;
        var strLeftEntry = "";
        var strRightEntry = "";

        if (strCrypticCommand.length >1024) {
            endItemPos= strCrypticCommand.substr(0,1024).lastIndexOf(concatChar);
            strLeftEntry= strCrypticCommand.substring(0,endItemPos);
            strRightEntry= strCrypticCommand.substring(endItemPos);
        } else
            strLeftEntry = strCrypticCommand
        
        var arTmp=strLeftEntry.split(concatChar);

        if(arTmp.length>29) {
			var newArray=arTmp.slice(29);
			arTmp=arTmp.slice(0,29);
			strRightEntry= newArray.join(concatChar) + strRightEntry; 
        }

        returnValue= sendTECommandToHost(arTmp.join(concatChar));

		if (strRightEntry.length>0) {
			fireCrypticCommand(strRightEntry,concatChar);
		}		
        return returnValue;
}

//Fires the actual command
function sendTECommandToHost(strCommand) {

	if(objTerminalEmulation==null) {
		objTerminalEmulation = new ActiveXObject("Dat32Com.TerminalEmulation");			 					
	}

	try {
		objTerminalEmulation.Open();
		strCommand='<FORMAT>'+strCommand+'</FORMAT>';
		objTerminalEmulation.MakeEntry(strCommand);

		//In case success is not returned then gather the return in array
		if(!objTerminalEmulation.ResponseLine(0).match(/^\s\*<CARRIAGE_RETURN/)) {
			gatherErrors(objTerminalEmulation);
		}

		return objTerminalEmulation.ResponseXML;
	} catch(e) {
		return e.message;
	} finally {
		if(objTerminalEmulation!=null) objTerminalEmulation.Close();  //close after usage
	}	
}

//In case of errors the response is gathered in an array;
function gatherErrors(objTE) {
	for(i=0;i<objTE.NumResponseLines;i++) {
		var strLine=objTE.ResponseLine(i).replace('<CARRIAGE_RETURN/>','').replace('<SOM/>','')
		if(strLine!='') {
			allErrors.push(strLine);
		}
	} 
	allErrors.push('--------------------------------------') ; // Separater between errors
	allErrors.push('--------------------------------------') ; // Separater between errors
}

//Loads the Dropdown values from XML file
function fillDropDownValuesFromXml() {
	var xmlDom;

	try {
		if (window.ActiveXObject) { // IE
		  xmlDom = new ActiveXObject("Microsoft.XMLDOM");
		} else {
		  xmlDom = document.implementation.createDocument("","",null);
		}

		xmlDom.async = false;
		xmlDom.load('cwtvalues.xml');

		var xmlNodeList = xmlDom.documentElement.childNodes;
		var dropDownName;
		var nodeName;
		var innerList;

		for(i=0; i<xmlNodeList.length ;i++) {
			nodeName = xmlNodeList[i].nodeName;
			if(nodeName=='SupplierCode')
				dropDownName = frmCwtCorpScrpt.cboSupplierCode; 
			else if(nodeName=='PredominantClass')
				dropDownName = frmCwtCorpScrpt.cboPredominantClass; 
			else if(nodeName=='RealisedSavingCode')
				dropDownName = frmCwtCorpScrpt.cboRealisedSavingCode; 
			else if(nodeName=='MissedSavingCode')
				dropDownName = frmCwtCorpScrpt.cboMissedSavingCode; 

			if (nodeName != '#text') {
				innerList = xmlNodeList[i].getElementsByTagName('OPTION');

				for(j=0; j<innerList.length; j++) {
					dropDownName.options[dropDownName.options.length] = new Option(innerList[j].getAttribute("display"), innerList[j].getAttribute("value")); 
				}
			}
		}
	} catch(e) {
		alert('Loading dropdowns: ' + e.message);
	} finally {
		delete xmlDom;

		xmlDom = null;
	}
}

function refreshVP() {
	var objVP= new ActiveXObject("Viewpoint.ViewpointSrv");
	objVP.RetrieveCurrentPNR();
	delete objVP;
}

//make a cleanup when window is being closed
window.onunload = function() {
	if(objTerminalEmulation!=null)objTerminalEmulation.Close(); //close Terminal Emulation before destroying
	delete objTerminalEmulation;
	objTerminalEmulation=null;				
}

function setPrefTextStatus(checkBox) {
	try	{
		if(checkBox != null) {
			var textBoxIdPrefix = 'txtRef';
			var index = checkBox.name.slice(-2);
			var textBox = document.frmCwtCorpScrpt.elements[textBoxIdPrefix+index];
			
			if(checkBox.checked) {
				textBox.disabled = false;
				textBox.focus();
				textBox.createTextRange().select();
			} else {
				textBox.disabled = true;
			}
		}	
	} catch(ex) {
		textBox.disabled = false;
	}
}

function upperCaseOnly(txt) {
	/* This function allows only characters matching with this regular expression
	[A-Z0-9\s\.\/\-\$\*\(\):#\?\+] : Characters supported in case of + sign
    to be typed into an input box and converts to uppercase if there are any lowercase alphabets. */

	if (/[^A-Z0-9\s\.\/\-\$\*\(\):#\?']/g.test(txt.value)) {
        txt.value=txt.value.toUpperCase().replace(/([^A-Za-z0-9\s\.\/\-\$\*\(\):#\?'])/g,"");
        
    }
}

  //Adds current command to global string
function addCommand(strCommand, strFunction) {
	if(frmCwtCorpScrpt.txtTicketNumber.value=='') {
		allCommands += concatChar + strCommand + strFunction;
	} else if (frmCwtCorpScrpt.txtTicketNumber.value=='1') {
		allCommands += concatChar + strCommand + strFunction;
	} else {
		allCommands += concatChar + strCommand + '*' + frmCwtCorpScrpt.txtTicketNumber.value + '/' + strFunction;
	}
}

function ExecuteScript() {
		allCommands = '';
		allErrors = null;
		allErrors = new Array();	//Reinitilize the array to hold response in case of errors
	
		if(frmCwtCorpScrpt.txtCustomHiearchy.value!='')
			addCommand('DI.FT-FF2/', 'BTS  ' + frmCwtCorpScrpt.txtCustomHiearchy.value);

		if(frmCwtCorpScrpt.txtTravellerID.value!='')
			addCommand('DI.FT-FF99/', frmCwtCorpScrpt.txtTravellerID.value);
		
		if(frmCwtCorpScrpt.cboPredominantClass.value!='')
			addCommand('DI.FT-FF8/', frmCwtCorpScrpt.cboPredominantClass.value);
		
		if(frmCwtCorpScrpt.cboRealisedSavingCode.value!='')
			addCommand('DI.FT-FF3/', frmCwtCorpScrpt.cboRealisedSavingCode.value);
		
		if(frmCwtCorpScrpt.txtLpoAuthorization.value!='')
			addCommand('DI.FT-FF4/', frmCwtCorpScrpt.txtLpoAuthorization.value );
		
		if(frmCwtCorpScrpt.txtReferenceFare.value !='')
			addCommand('DI.FT-RF/', frmCwtCorpScrpt.txtReferenceFare.value)			
		
		if(frmCwtCorpScrpt.txtLowFare.value !='')
			addCommand('DI.FT-LF/', frmCwtCorpScrpt.txtLowFare.value);
		
		if(frmCwtCorpScrpt.cboMissedSavingCode.value!='')
			addCommand('DI.FT-EC/', frmCwtCorpScrpt.cboMissedSavingCode.value);				
						
		if(frmCwtCorpScrpt.cboSupplierCode.value !='')
			addCommand('DI.FT-FF22/', frmCwtCorpScrpt.cboSupplierCode.value);
		else
			addCommand('DI.FT-FF22/', 'SCODE');

		// For sending the DI lines for the reference fields where the check box is checked
		for(i=0;i<frmCwtCorpScrpt.elements.length;i++) {
			var ctr = frmCwtCorpScrpt.elements[i];

			if(ctr.name.match(/^chkRef[0-9]+$/) && ctr.checked) {
				var index=ctr.name.match(/\d+/);
				ctr = frmCwtCorpScrpt.elements['txtRef'+index];
				addCommand('DI.FT-FF'+index+'/', ctr.value);		
			}
		}

		addCommand('DI.FT-FF38/', 'G');
		addCommand('DI.FT-FF39/', 'GAL');
		addCommand('DI.FT-FF40/', 'AB');

		document.frmCwtCorpScrpt.resultarea.value = allCommands;
		fireCrypticCommand(allCommands,concatChar);		
		if(allErrors.length!=0)
			alert('Error while executing script:- \n\n' +allErrors.join('\n'));
		else
			alert('Script executed successfully ...');
		refreshVP();
}


function ExecuteTestScript() {
		allCommands = '';
		allErrors = null;
		allErrors = new Array();	//Reinitilize the array to hold response in case of errors
	
		if(frmCwtCorpScrpt.txtCustomHiearchy.value!='')
			addCommand('DI.FT-FF2/', 'BTS  ' + frmCwtCorpScrpt.txtCustomHiearchy.value);

		if(frmCwtCorpScrpt.txtTravellerID.value!='')
			addCommand('DI.FT-FF99/', frmCwtCorpScrpt.txtTravellerID.value);
		
		if(frmCwtCorpScrpt.cboPredominantClass.value!='')
			addCommand('DI.FT-FF8/', frmCwtCorpScrpt.cboPredominantClass.value);
		
		if(frmCwtCorpScrpt.cboRealisedSavingCode.value!='')
			addCommand('DI.FT-FF3/', frmCwtCorpScrpt.cboRealisedSavingCode.value);
		
		if(frmCwtCorpScrpt.txtLpoAuthorization.value!='')
			addCommand('DI.FT-FF4/', frmCwtCorpScrpt.txtLpoAuthorization.value );
		
		if(frmCwtCorpScrpt.txtReferenceFare.value !='')
			addCommand('DI.FT-RF/', frmCwtCorpScrpt.txtReferenceFare.value)			
		
		if(frmCwtCorpScrpt.txtLowFare.value !='')
			addCommand('DI.FT-LF/', frmCwtCorpScrpt.txtLowFare.value);
		
		if(frmCwtCorpScrpt.cboMissedSavingCode.value!='')
			addCommand('DI.FT-EC/', frmCwtCorpScrpt.cboMissedSavingCode.value);				
						
		if(frmCwtCorpScrpt.cboSupplierCode.value !='')
			addCommand('DI.FT-FF22/', frmCwtCorpScrpt.cboSupplierCode.value);
		else
			addCommand('DI.FT-FF22/', 'SCODE');

		// For sending the DI lines for the reference fields where the check box is checked
		for(i=0;i<frmCwtCorpScrpt.elements.length;i++) {
			var ctr = frmCwtCorpScrpt.elements[i];

			if(ctr.name.match(/^chkRef[0-9]+$/) && ctr.checked) {
				var index=ctr.name.match(/\d+/);
				ctr = frmCwtCorpScrpt.elements['txtRef'+index];
				addCommand('DI.FT-FF'+index+'/', ctr.value);		
			}
		}

		addCommand('DI.FT-FF38/', 'G');
		addCommand('DI.FT-FF39/', 'GAL');
		addCommand('DI.FT-FF40/', 'AB');

		document.frmCwtCorpScrpt.resultarea.value = allCommands;
}