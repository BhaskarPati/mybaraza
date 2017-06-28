<?php
header('Content-type: text/plain');
$params["arg0"] = postGrades();
$params["arg1"] = "babcockWB12345";

$client = new SoapClient("http://umis.babcock.edu.ng/babcock/webservice?wsdl");
try{
	if ($client->_soap_version == 1){
		//echo "version 1";
		$params = array($params);
	}
	$response = $client->__soapCall('addWsData',$params);

	print_r($response);
	
} catch(SoapFault $exception) {
	echo 'ERROR ::: ' . $exception->getMessage();
} catch(Exception $ex) {
	
	echo 'PHP ERROR ::: ' . $ex->getMessage();
}


function postGrades(){
		$xml = "<TRANSFERS>\n";
		$xml .= " <TRANSFER name=\"Citizenship Grade\" keyfield=\"import_grade_id\" table=\"import_grades\">\n";
		$xml .=	"<import_grade_id>102</import_grade_id>\n";
		$xml .=	"<course_id>GEDS001</course_id>\n";
		$xml .=	"<session_id>2016/2017.1</session_id>\n";
		$xml .=	"<student_id>12/1234</student_id>\n";
		$xml .=	"<score>87</score>\n";
		$xml .=	"</TRANSFER>\n";
		$xml .=	"</TRANSFERS>\n";
		return $xml;
}
	
?>