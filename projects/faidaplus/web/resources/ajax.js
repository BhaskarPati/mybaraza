function makeRequest(url) {
	var httpRequest;

	if (window.XMLHttpRequest) { // Mozilla, Safari, ...
		httpRequest = new XMLHttpRequest();
	} else if (window.ActiveXObject) { // IE
		try {
			httpRequest = new ActiveXObject("Msxml2.XMLHTTP");
		} catch (e) {
			try {
				httpRequest = new ActiveXObject("Microsoft.XMLHTTP");
			} catch (e) {}
		}
	}

	if (!httpRequest) {
		alert('Giving up : Cannot create an XMLHTTP instance');
		return false;
	}

	httpRequest.onreadystatechange = function() { processReq(httpRequest); };
	httpRequest.open('GET', url, true);
	httpRequest.send('');
}

function processReq(httpRequest) {
	var xmlDoc;

	if (httpRequest.readyState == 4) {
		if (httpRequest.status == 200) {
			var xml = httpRequest.responseXML;
			var response = xml.getElementsByTagName("response").item(0);
			var callmethod = response.getElementsByTagName("method").item(0).firstChild.data;
			var results = response.getElementsByTagName("result").item(0);

			//parent.clientfile.document.frmGalileoScript.clientfile.value = httpRequest.responseText;

			eval(callmethod + '(results)');
		} else {
			alert('There was a problem with the request : ' + httpRequest.statusText);
		}
	}
}

function updateProfile(myinput) {
	var url = 'general?viewnocache=yes&view=101&filtervalue=' + myinput;
	makeRequest(url);
}

function updatePassanger(myinput) {
	var url = 'general?viewnocache=yes&view=102&filtervalue=' + myinput;
	makeRequest(url);
}

function loadProfile(xmldata) {
	for(var i = 0; i < xmldata.childNodes.length; i++) {		
		if (xmldata.childNodes[i].nodeType == 1) {
			parent.clientfile.document.getElementById(xmldata.childNodes[i].nodeName).value = readValue(xmldata.childNodes[i]);
		}
	}
	updateClientName();
}

function readValue(xmldata) {
	var mystr = "";
	for(var i = 0; i < xmldata.childNodes.length; i++) {
		if(xmldata.childNodes[i].nodeType == 3) {
			mystr = xmldata.childNodes[i].nodeValue;
		} else if (xmldata.childNodes[i].nodeType == 1) {
			mystr = readXML(xmldata.childNodes[i]);
		}
	}	

	return mystr;
}

function dtrim(myval) {
	return myval.replace(/^\s+|\s+$/g,"");
}