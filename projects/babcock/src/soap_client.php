<?php
header('Content-type: text/plain');
//header('Content-type: text/xml');
//header('Content-type: text/html; charset=utf-8');

$params["arg0"] = getHallService("15/1353");
$params["arg1"] = "test123";

$client = new SoapClient("http://umis.babcock.edu.ng/babcock/webservice?wsdl");

try{
	if ($client->_soap_version == 1){
		//echo "version 1";
		$params = array($params);
	}
	$response = $client->__soapCall('getWsData',$params);
	print_r($response);
} catch(SoapFault $exception) {
	echo 'ERROR ::: ' . $exception->getMessage();
} catch(Exception $ex) {
	echo 'PHP ERROR ::: ' . $ex->getMessage();
}

function getStudentRequest($studentId) {	
	$xml = "<QUERY>\n";
	$xml .= "<GRID name=\"student\" keyfield=\"studentid\" table=\"ws_students\" where=\"studentid = '" . $studentId . "'\">\n";
	$xml .= "	<TEXTFIELD>studentid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>firstname</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>othernames</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>surname</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>birthdate</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>mobile</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>email</TEXTFIELD>\n";
	$xml .= "</GRID>\n";
	$xml .= "</QUERY>\n";
	
	return $xml;
}

function getHallService($studentId) {	
	$xml = "<QUERY>\n";
	$xml .= "<GRID name=\"Hall Service\" keyfield=\"studentid\" table=\"ws_hall_service\" where=\"studentid = '" . $studentId . "'\">\n";
	$xml .= "	<TEXTFIELD>studentid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>studentname</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>quarterid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>schoolid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>departmentid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>studylevel</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>majorid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>majorname</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>residenceid</TEXTFIELD>\n";
	$xml .= "	<TEXTFIELD>finaceapproval</TEXTFIELD>\n";
	$xml .= "</GRID>\n";
	$xml .= "</QUERY>\n";
		
	return $xml;
}

?>
