<?php
header('Content-type: text/plain');
//header('Content-type: text/xml');
//header('Content-type: text/html; charset=utf-8');

$params["arg0"] = getStudentRequest("06/0382", "9b16759a62899465ab21e2e79d2ef75c");
$params["arg1"] = "test123";

$client = new SoapClient("http://demo.dewcis.com/babcock/webservice?wsdl");

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

function getStudentRequest($studentId, $studentPass) {	
		$xml = "<QUERY>\n";
		$xml .= "<GRID name=\"student\" keyfield=\"studentid\" table=\"ws_students\" ";
		$xml .= "	where=\"(studentid = '" . $studentId . "') AND (entity_password = '" . $studentPass . "')\" >\n";
		$xml .= "    <TEXTFIELD>studentid</TEXTFIELD>\n";
		$xml .= "    <TEXTFIELD>firstname</TEXTFIELD>\n";
		$xml .= "    <TEXTFIELD>othernames</TEXTFIELD>\n";
		$xml .= "    <TEXTFIELD>surname</TEXTFIELD>\n";
		$xml .= "    <TEXTFIELD>birthdate</TEXTFIELD>\n";
		$xml .= "    <TEXTFIELD>mobile</TEXTFIELD>\n";
		$xml .= "    <TEXTFIELD>email</TEXTFIELD>\n";
		$xml .= "</GRID>\n";
		$xml .= "</QUERY>\n";		
		
		return $xml;
	}

?>
