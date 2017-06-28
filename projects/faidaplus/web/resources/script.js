
function getPCC() {
	var TE = new ActiveXObject("DAT32COM.TERMINALEMULATION");
	var xmldata = Display(TE, "JANBO");
	TE.close();
	return xmldata;
}

function getHMPR(vpcc, vdate, vcurrency) {
	var TE = new ActiveXObject("DAT32COM.TERMINALEMULATION");
	
	var command = "<FORMAT>SEM/" + vpcc + "/AG</FORMAT>";
	TE.MakeEntry(command);

	command = "HMPR*E/" + vdate + "/CU-" + vcurrency;
	var xmldata = Display(TE, command);

	command = "<FORMAT>SEM/AS</FORMAT>";
	TE.MakeEntry(command);

	TE.close();
	
	return xmldata;
}

function getTE(vpcc, vticketList) {
	var TE = new ActiveXObject("DAT32COM.TERMINALEMULATION");
	
	var command = "<FORMAT>SEM/" + vpcc + "/AG</FORMAT>";
	TE.MakeEntry(command);

	var teXml = "";
	var lines = vticketList.split(",");
	var i;
	for (i = 0; i < lines.length; i++) {
		var vLine = lines[i];
		if(vLine) {
			if(vLine.length > 5) {
				var xmldata = Display(TE, "*TE/" + vLine);
				teXml += xmldata + "####";
			}
		}
	}
	
	command = "<FORMAT>SEM/AS</FORMAT>";
	TE.MakeEntry(command);

	TE.close();
	
	return teXml;
}


function pickTickets() {
	var mydates = document.frmGalileoScript.mydates.value;
	var mydts = mydates.split(",");
	for(i = 0; i < mydts.length; i++){
		document.frmGalileoScript.tdate.value = mydts[i];

		DisplayData();
	}
}

function showDate() {
	var mydate = new Date();

	var mymonth = mydate.getMonth();
	var m_names = new Array("JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC");
	var curr_date = mydate.getDate();

	document.frmGalileoScript.mymonth.value = m_names[mymonth];
	if(curr_date<9)
		document.frmGalileoScript.tdate.value =  '0' + curr_date + m_names[mymonth];
	else
		document.frmGalileoScript.tdate.value =  curr_date + m_names[mymonth];
}

function ProcessDate() {
	var i = 0;
	var mymonth = document.frmGalileoScript.mymonth.value;
	var sdate = document.frmGalileoScript.sdate.value;
	var edate = document.frmGalileoScript.edate.value;
	for (i=sdate; i<=edate; i++) {
		if(i<9)
			document.frmGalileoScript.tdate.value =  '0' + i + mymonth;
		else
			document.frmGalileoScript.tdate.value =  i + mymonth;

		DisplayData();
	}
}

function updateRange() {
	var i = 0;
	var lmonth = document.frmGalileoScript.mymonth.value;
	var lsdate = document.frmGalileoScript.sdate.value;
	var ledate = document.frmGalileoScript.edate.value;
	for (i=lsdate; i<=ledate; i++) {
		if(i<9) {
			document.frmGalileoScript.tdate.value =  '0' + i + lmonth;
		} else {
			document.frmGalileoScript.tdate.value =  i + lmonth;
		}

		DisplayData();
	}
}

function DisplayPCC() {
	var TE = new ActiveXObject("DAT32COM.TERMINALEMULATION");
	var xmldata = Display(TE, "JANBO");
	
	document.myapplet.getPcc(xmldata);
	
	document.frmGalileoScript.resultarea.value = document.myapplet.value;
	
	TE.close();
}

function DisplayData() {
	DisplayPCC();		// Display data

	var TA = document.frmGalileoScript.resultarea.value;
	var lines = TA.split("\n");
	
	var i;
	for (i=0; i<lines.length; i++) {
		if(lines[i].length > 2) {
			document.frmGalileoScript.pcc.value = lines[i];
			DisplayHMPR("KES");
			DisplayHMPR("USD");
		}
	}
}

function DisplayHMPR(currency) {
	var TE = new ActiveXObject("DAT32COM.TERMINALEMULATION");
	
	var command = "<FORMAT>SEM/" + document.frmGalileoScript.pcc.value + "/AG</FORMAT>";
	TE.MakeEntry(command);

	tickets.setdate(document.frmGalileoScript.tdate.value);
	tickets.setpcc(document.frmGalileoScript.pcc.value);
	tickets.setcurrency(currency);

	command = "HMPR*E/" + document.frmGalileoScript.tdate.value + "/CU-" + currency;
	var xmldata = Display(TE, command);
	var hmprData = tickets.makehmpr(xmldata);
	document.frmGalileoScript.ticketresult.value = hmprData;

	var TA = document.frmGalileoScript.ticketresult.value;
	var lines = TA.split("\n");
	var i;
	for (i = 0; i < lines.length; i++) {
		if(lines[i].length > 7) {
			document.frmGalileoScript.ticketnum.value = lines[i];
			DisplayAllTE(TE);
		}
	}

	command = "<FORMAT>SEM/AS</FORMAT>";
	TE.MakeEntry(command);

	TE.close();
}

function DisplayAllTE(TE) {
	var command = "*TE/" + document.frmGalileoScript.ticketnum.value;
	var xmldata = Display(TE, command);
	document.myapplet.makete(xmldata);
}

function DisplayTE() {
	var TE = new ActiveXObject("DAT32COM.TERMINALEMULATION");
	
	var command = "<FORMAT>SEM/" + document.frmGalileoScript.pcc.value + "/AG</FORMAT>";
	TE.MakeEntry(command);

	command = "*TE/" + document.frmGalileoScript.ticketnum.value;
	var xmldata = Display(TE, command);
	document.myapplet.makete(xmldata);
	document.frmGalileoScript.resultarea.value = document.myapplet.value;

	command = "<FORMAT>SEM/AS</FORMAT>";
	TE.MakeEntry(command);

	TE.close();
}

function Display(TE, gcmd) {
	var command = "<FORMAT>" + gcmd + "</FORMAT>";
	TE.MakeEntry(command);
	
	while (TE.More == true) {
		TE.GetMore(true, false);
	}
	
	var xmlresult = TE.ResponseXML;
	
	return xmlresult;
}



