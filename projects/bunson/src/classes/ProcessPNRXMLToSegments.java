import java.io.IOException;
import java.io.PrintWriter;

import java.sql.ResultSet;
import java.sql.SQLException;

import javax.servlet.annotation.WebServlet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import java.util.Map;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.baraza.xml.BXML;
import org.baraza.xml.BElement;
import org.baraza.DB.BDB;
import org.baraza.DB.BQuery;

import org.json.simple.JSONArray;
import org.json.simple.JSONObject;

//@WebServlet("/processpnrtosegments") dont use this dew to tomcat version : only from servlet API of tomcat 7
public class ProcessPNRXMLToSegments extends HttpServlet{
	static Logger log = Logger.getLogger(ProcessPNRXMLToSegments.class.getName());
	public static final String KEY_NO_MATCH = "NO_MATCH_FOUND";
	@SuppressWarnings("unchecked")
	@Override
	public void doPost(HttpServletRequest req, HttpServletResponse rsp)	throws ServletException, IOException {
		//HttpSession session = req.getSession(false);
		String xml_string = null , fare_xml_string = null;
		xml_string = req.getParameter("pnr_xml");
		//fare_xml_string = req.getParameter("fare_xml");
        
        //xml_string = "<AgencyPNRBFDisplay_7_9><PNRBFRetrieve><ErrorCode>0003</ErrorCode><Control><KLRCnt>45</KLRCnt><KlrAry><Klr><ID>BP10</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP12</ID><NumOccur>1</NumOccur></Klr><Klr><ID>IT01</ID><NumOccur>2</NumOccur></Klr><Klr><ID>IT09</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP21</ID><NumOccur>2</NumOccur></Klr><Klr><ID>BP22</ID><NumOccur>2</NumOccur></Klr><Klr><ID>BP20</ID><NumOccur>0</NumOccur></Klr><Klr><ID>BP19</ID><NumOccur>3</NumOccur></Klr><Klr><ID>ST01</ID><NumOccur>2</NumOccur></Klr><Klr><ID>ST02</ID><NumOccur>2</NumOccur></Klr><Klr><ID>BP14</ID><NumOccur>2</NumOccur></Klr><Klr><ID>BP46</ID><NumOccur>2</NumOccur></Klr><Klr><ID>BP16</ID><NumOccur>3</NumOccur></Klr><Klr><ID>BP18</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP17</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP32</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP26</ID><NumOccur>5</NumOccur></Klr><Klr><ID>BP48</ID><NumOccur>5</NumOccur></Klr><Klr><ID>DPIR</ID><NumOccur>4</NumOccur></Klr><Klr><ID>BP28</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP27</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP24</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP25</ID><NumOccur>1</NumOccur></Klr><Klr><ID>BP08</ID><NumOccur>1</NumOccur></Klr></KlrAry></Control><LNameInfo><LNameNum>1</LNameNum><NumPsgrs>1</NumPsgrs><NameType/><LName>AKIRI</LName></LNameInfo><FNameInfo><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum><FName>MORRISMR</FName></FNameInfo><AirSeg><SegNum>1</SegNum><Status>HK</Status><Dt>20160210</Dt><DayChg>01</DayChg><AirV>KQ</AirV><NumPsgrs>1</NumPsgrs><StartAirp>NBO</StartAirp><EndAirp>LUN</EndAirp><StartTm>2210</StartTm><EndTm>1</EndTm><BIC>L</BIC><FltNum>720</FltNum><OpSuf/><COG>N</COG><TklessInd>Y</TklessInd><ConxInd>N</ConxInd><FltFlownInd>N</FltFlownInd><MarriageNum/><SellType>O</SellType><StopoverIgnoreInd/><TDSValidateInd>N</TDSValidateInd><NonBillingInd/><PrevStatusCode>NN</PrevStatusCode><ScheduleValidationInd/><VndLocInd>*</VndLocInd></AirSeg><AirSeg><SegNum>2</SegNum><Status>HK</Status><Dt>20160212</Dt><DayChg>00</DayChg><AirV>KQ</AirV><NumPsgrs>1</NumPsgrs><StartAirp>LUN</StartAirp><EndAirp>NBO</EndAirp><StartTm>1640</StartTm><EndTm>2025</EndTm><BIC>E</BIC><FltNum>726</FltNum><OpSuf/><COG>N</COG><TklessInd>Y</TklessInd><ConxInd>N</ConxInd><FltFlownInd>N</FltFlownInd><MarriageNum/><SellType>O</SellType><StopoverIgnoreInd/><TDSValidateInd>N</TDSValidateInd><NonBillingInd/><PrevStatusCode>NN</PrevStatusCode><ScheduleValidationInd/><VndLocInd>*</VndLocInd></AirSeg><DuePaidInfo><SegNum>3</SegNum><Type>A</Type><Dt>20160830</Dt><DuePaidTextInd>T</DuePaidTextInd><Price>0</Price><Currency/><DecPos/><Text>**PNR ALIVE**</Text></DuePaidInfo><ProgramaticSSR><GFAXNum>1</GFAXNum><SSRCode>TKNE</SSRCode><Status>HK</Status><SegNum>1</SegNum><AppliesToAry><AppliesTo><LNameNum>1</LNameNum><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum></AppliesTo></AppliesToAry></ProgramaticSSR><ProgramaticSSRText><Text>7069394654578C1</Text></ProgramaticSSRText><ProgramaticSSR><GFAXNum>2</GFAXNum><SSRCode>TKNE</SSRCode><Status>HK</Status><SegNum>2</SegNum><AppliesToAry><AppliesTo><LNameNum>1</LNameNum><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum></AppliesTo></AppliesToAry></ProgramaticSSR><ProgramaticSSRText><Text>7069394654578C2</Text></ProgramaticSSRText><OSI><GFAXNum>1</GFAXNum><OSIV>YY</OSIV><OSIMsg>OIN KE01579</OSIMsg></OSI><OSI><GFAXNum>2</GFAXNum><OSIV>YY</OSIV><OSIMsg>PCTC 254734925662</OSIMsg></OSI><OSI><GFAXNum>3</GFAXNum><OSIV>YY</OSIV><OSIMsg>CTCM</OSIMsg></OSI><SeatSeg><FltNum>720</FltNum><OpSuf/><AirV>KQ</AirV><StartDt>20160210</StartDt><BIC>L</BIC><StartAirp>NBO</StartAirp><EndAirp>LUN</EndAirp><FltSegNum>1</FltSegNum><NumPsgrs>1</NumPsgrs><COGNum/></SeatSeg><SeatAssignment><LNameNum>1</LNameNum><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum><Status>HK</Status><Locn>017J</Locn><AttribAry><Attrib>N</Attrib></AttribAry></SeatAssignment><SeatSeg><FltNum>726</FltNum><OpSuf/><AirV>KQ</AirV><StartDt>20160212</StartDt><BIC>E</BIC><StartAirp>LUN</StartAirp><EndAirp>NBO</EndAirp><FltSegNum>2</FltSegNum><NumPsgrs>1</NumPsgrs><COGNum/></SeatSeg><SeatAssignment><LNameNum>1</LNameNum><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum><Status>HK</Status><Locn>020A</Locn><AttribAry><Attrib>N</Attrib></AttribAry></SeatAssignment><FreqCustInfoEx><LNameNum>1</LNameNum><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum><FreqCustV>KL</FreqCustV><FreqCustStatus/><FreqPriorityCD>2</FreqPriorityCD><FreqValidateInd>J</FreqValidateInd><FreqTierLevel>G</FreqTierLevel><Spare/><FreqNumLen/><FreqCustNum>8415493401</FreqCustNum></FreqCustInfoEx><FreqCustInfo><LNameNum>1</LNameNum><PsgrNum>1</PsgrNum><AbsNameNum>1</AbsNameNum><FreqCustV>KL</FreqCustV><FreqCustStatus/><FreqCustNum>8415493401</FreqCustNum></FreqCustInfo><PhoneInfo><PhoneFldNum>1</PhoneFldNum><Pt>NBO</Pt><Type>A</Type><Phone>BUNSON TRAVEL VILLAGE TEL.7122080/7121235</Phone></PhoneInfo><PhoneInfo><PhoneFldNum>2</PhoneFldNum><Pt>NBO</Pt><Type>B</Type><Phone>TEL 254 7224450</Phone></PhoneInfo><PhoneInfo><PhoneFldNum>3</PhoneFldNum><Pt>NBO</Pt><Type>B</Type><Phone>TEL 254 7224462</Phone></PhoneInfo><DeliveryAddrInfo><DeliveryAddr>WORLD AGROFORESTRY CENTER</DeliveryAddr></DeliveryAddrInfo><AddrInfo><Addr>P.O.BOX 633@P/000621 NAIROBI KENYA</Addr></AddrInfo><TkArrangement><Text>NBO 28JAN1334Z IB AG</Text></TkArrangement><GenRmkInfo><GenRmkNum>1</GenRmkNum><CreationDt>20160127</CreationDt><CreationTm>1312</CreationTm><GenlRmkQual/><GenRmk>ALWAYS REQ ~</GenRmk></GenRmkInfo><GenRmkInfo><GenRmkNum>2</GenRmkNum><CreationDt>20160127</CreationDt><CreationTm>1312</CreationTm><GenlRmkQual>TT</GenlRmkQual><GenRmk>VIP</GenRmk></GenRmkInfo><GenRmkInfo><GenRmkNum>3</GenRmkNum><CreationDt>20160127</CreationDt><CreationTm>1312</CreationTm><GenlRmkQual/><GenRmk><![CDATA[~                                )I]]></GenRmk></GenRmkInfo><GenRmkInfo><GenRmkNum>4</GenRmkNum><CreationDt>20160127</CreationDt><CreationTm>1312</CreationTm><GenlRmkQual/><GenRmk>CM/</GenRmk></GenRmkInfo><GenRmkInfo><GenRmkNum>5</GenRmkNum><CreationDt>20160128</CreationDt><CreationTm>1335</CreationTm><GenlRmkQual/><GenRmk>USD723.00 EQU KES76170 4215TU 2635JI 530QJ 1055RM TAX 430YQ TAX 18970YR TOT KES104005</GenRmk></GenRmkInfo><InvoiceRmk><ItemNum>1</ItemNum><Keyword>3010</Keyword><Rmk>CN/000000C001</Rmk></InvoiceRmk><InvoiceRmk><ItemNum>2</ItemNum><Keyword>3010</Keyword><Rmk>PO/</Rmk></InvoiceRmk><InvoiceRmk><ItemNum>3</ItemNum><Keyword>3010</Keyword><Rmk>RF/KES</Rmk></InvoiceRmk><InvoiceRmk><ItemNum>4</ItemNum><Keyword>3010</Keyword><Rmk>LF/KES</Rmk></InvoiceRmk><VndRmk><RmkNum>1</RmkNum><TmStamp>1326</TmStamp><DtStamp>20160127</DtStamp><RmkType>I</RmkType><VType>A</VType><Vnd>KQ</Vnd><Rmk>ADTK1GTOKQ BY 03FEB16/1600Z OTHERWISE WILL BE XXLD</Rmk></VndRmk><ProfileClientFileAssoc><ItemNum>1</ItemNum><CRSID>1G</CRSID><MAR>7YC2</MAR><BAR>CABI</BAR><PAR>AKIRI M</PAR><ActiveInd>Y</ActiveInd><PrefsInd>N</PrefsInd></ProfileClientFileAssoc><GenPNRInfo><FileAddr>E6910AAD</FileAddr><CodeCheck>87</CodeCheck><RecLoc>9XL88Q</RecLoc><Ver>13</Ver><OwningCRS>1G</OwningCRS><OwningAgncyName>BUNSON TRAVEL SERVICES L</OwningAgncyName><OwningAgncyPCC>74TP</OwningAgncyPCC><CreationDt>20160127</CreationDt><CreatingAgntSignOn>74TPIB</CreatingAgntSignOn><CreatingAgntDuty>AG</CreatingAgntDuty><CreatingAgncyIATANum>41226684</CreatingAgncyIATANum><OrigBkLocn>NBOOU</OrigBkLocn><SATONum/><PTAInd>N</PTAInd><InUseInd>N</InUseInd><SimultaneousUpdInd/><BorrowedInd>N</BorrowedInd><GlobInd>N</GlobInd><ReadOnlyInd>N</ReadOnlyInd><FareDataExistsInd>Y</FareDataExistsInd><PastDtQuickInd>N</PastDtQuickInd><CurAgncyPCC>74TP</CurAgncyPCC><QInd>N</QInd><TkNumExistInd>Y</TkNumExistInd><IMUdataexists>N</IMUdataexists><ETkDataExistInd>Y</ETkDataExistInd><CurDtStamp>20160129</CurDtStamp><CurTmStamp>084726</CurTmStamp><CurAgntSONID>74TPDC</CurAgntSONID><TravInsuranceInd/><PNRBFTicketedInd>Y</PNRBFTicketedInd><ZeppelinAgncyInd>N</ZeppelinAgncyInd><AgncyAutoServiceInd>N</AgncyAutoServiceInd><AgncyAutoNotifyInd>N</AgncyAutoNotifyInd><ZeppelinPNRInd>N</ZeppelinPNRInd><PNRAutoServiceInd>N</PNRAutoServiceInd><PNRNotifyInd>N</PNRNotifyInd><SuperPNRInd>N</SuperPNRInd><PNRBFPurgeDt>20160901</PNRBFPurgeDt><PNRBFChangeInd>N</PNRBFChangeInd><MCODataExists>N</MCODataExists><OrigRcvdField>IB</OrigRcvdField><IntContExists>N</IntContExists><AllDataAllTime>N</AllDataAllTime></GenPNRInfo><CustomCheckRules><RuleAry><Rule><PCC>74TP</PCC><RuleName>BTS</RuleName><StatusInd/></Rule></RuleAry></CustomCheckRules><VndRecLocs><RecLocInfoAry><RecLocInfo><TmStamp>1341</TmStamp><DtStamp>20160128</DtStamp><Vnd>1A</Vnd><RecLoc>YOS9MD</RecLoc></RecLocInfo></RecLocInfoAry></VndRecLocs></PNRBFRetrieve><SessionInfo><ErrorCode>0003</ErrorCode><AreaInfoResp><Sys>1G</Sys><Processor>A</Processor><GrpModeActivatedInd>N</GrpModeActivatedInd><AAAAreaAry><AAAAreaInfo><AAAArea>A</AAAArea><ActiveInd>Y</ActiveInd><AAACity>NBO</AAACity><AAADept>OU</AAADept><SONCity>74TP</SONCity><SONDept/><AgntID>ZDC</AgntID><ChkDigit/><AgntInitials>DC</AgntInitials><Duty>AG</Duty><AgncyPCC/><DomMode/><IntlMode/><PNRDataInd>Y</PNRDataInd><PNRName>AKIRI/MORRISMR</PNRName><GrpModeActiveInd/><GrpModeDutyCode/><GrpModePCC/><GrpModeDataInd/><GrpModeName/></AAAAreaInfo><AAAAreaInfo><AAAArea>B</AAAArea><ActiveInd>A</ActiveInd><AAACity>NBO</AAACity><AAADept>OU</AAADept><SONCity>74TP</SONCity><SONDept/><AgntID>ZDC</AgntID><ChkDigit/><AgntInitials/><Duty/><AgncyPCC/><DomMode/><IntlMode/><PNRDataInd>N</PNRDataInd><PNRName/><GrpModeActiveInd/><GrpModeDutyCode/><GrpModePCC/><GrpModeDataInd/><GrpModeName/></AAAAreaInfo><AAAAreaInfo><AAAArea>C</AAAArea><ActiveInd>A</ActiveInd><AAACity>NBO</AAACity><AAADept>OU</AAADept><SONCity>74TP</SONCity><SONDept/><AgntID>ZDC</AgntID><ChkDigit/><AgntInitials/><Duty/><AgncyPCC/><DomMode/><IntlMode/><PNRDataInd>N</PNRDataInd><PNRName/><GrpModeActiveInd/><GrpModeDutyCode/><GrpModePCC/><GrpModeDataInd/><GrpModeName/></AAAAreaInfo><AAAAreaInfo><AAAArea>D</AAAArea><ActiveInd>A</ActiveInd><AAACity>NBO</AAACity><AAADept>OU</AAADept><SONCity>74TP</SONCity><SONDept/><AgntID>ZDC</AgntID><ChkDigit/><AgntInitials/><Duty/><AgncyPCC/><DomMode/><IntlMode/><PNRDataInd>N</PNRDataInd><PNRName/><GrpModeActiveInd/><GrpModeDutyCode/><GrpModePCC/><GrpModeDataInd/><GrpModeName/></AAAAreaInfo><AAAAreaInfo><AAAArea>E</AAAArea><ActiveInd>A</ActiveInd><AAACity>NBO</AAACity><AAADept>OU</AAADept><SONCity>74TP</SONCity><SONDept/><AgntID>ZDC</AgntID><ChkDigit/><AgntInitials/><Duty/><AgncyPCC/><DomMode/><IntlMode/><PNRDataInd>N</PNRDataInd><PNRName/><GrpModeActiveInd/><GrpModeDutyCode/><GrpModePCC/><GrpModeDataInd/><GrpModeName/></AAAAreaInfo></AAAAreaAry></AreaInfoResp></SessionInfo><CorporateDataStore><ErrorCode>0003</ErrorCode><ErrText><Err><![CDATA[  001006]]></Err><KlrInErr/><InsertedTextAry></InsertedTextAry><Text>TDS ERROR-INVALID USER</Text></ErrText></CorporateDataStore></AgencyPNRBFDisplay_7_9>";
		
		log.info("\n======================================================================\nPNR XML : " + xml_string + "\n======================================================================");
		//log.info("FARE PARAM fare_xml : " + fare_xml_string + "\n\n------------------------------------------------");
		
		Map<String, String> lName = new HashMap<String, String>(); 
		Map<String, String> fName = new HashMap<String, String>();
		Map<String, String> phonInfo = new HashMap<String, String>();
        Map<String, String> email = new HashMap<String, String>();
		
		//list for all segments
		JSONArray airSegments = new JSONArray();
		JSONArray tickets = new JSONArray();
		String RecLoc = "";
        JSONArray VendoRecLoc = new JSONArray();
		
		if(!xml_string.isEmpty() && xml_string != null){
            
            
            
			BElement root = new BXML(xml_string, true).getRoot().getElementByName("PNRBFRetrieve");
			//int ticket_count = 1;
			try{
                for(BElement el : root.getElements()) {
                    String elName = el.getName();
                    if(elName == null) elName = "";

                    System.out.println("EL NAME : " + elName);
                    if(elName.equals("GenPNRInfo")) {
                        RecLoc = el.getElementByName("RecLoc").getValue();
                    }

                    if(elName.equals("VndRecLocs")) {
                        for(BElement vrlRoot : el.getElements()) {
                            if(vrlRoot.getName().equals("RecLocInfoAry")){
                                for(BElement rlIRoot : vrlRoot.getElements()) {
                                    if(rlIRoot.getName().equals("RecLocInfo")){
                                        String num = rlIRoot.getElementByName("Vnd").getValue() + "*" + rlIRoot.getElementByName("RecLoc").getValue();
                                        JSONObject rec = new JSONObject();
                                        rec.put("locator", num);
                                        VendoRecLoc.add(rec);
                                    }
                                }
                            }
                        }
                    }

                    if(elName.equals("LNameInfo")) {
                        lName.put(el.getElementByName("LNameNum").getValue(), el.getElementByName("LName").getValue());
                    }


                    if(elName.equals("FNameInfo")) {
                        fName.put(el.getElementByName("AbsNameNum").getValue(), el.getElementByName("FName").getValue());
                    }
                    //+++++++++++++++++++++++++++++++++++++++++++++++++++++
                    if(elName.equals("PhoneInfo")) {// incomplete
                        String pt = (el.getElementByName("Pt").getValue()).trim();
                        String type = el.getElementByName("Type").getValue();

                        boolean sph = true;//Boolean.parseBoolean(String.valueOf(session.getAttribute("ph")));
                        boolean spa = true;//Boolean.parseBoolean(String.valueOf(session.getAttribute("pa")));
                        boolean spb = true;//Boolean.parseBoolean(String.valueOf(session.getAttribute("pb")));
                        boolean spt = true;//Boolean.parseBoolean(String.valueOf(session.getAttribute("pt")));

                        log.info("FON :: pt : " + pt + " type : " + type + "\n");

                        if(pt != null && type != null){
                            if(pt.equals("NBO")){
                                //&& ( type.equals("R") || type.equals("PAX") || type.equals("H") || type.equals("R") )){//use give number types
                                String pn = getPhoneFromString(el.getElementByName("Phone").getValue());

                                if(!pn.equals(KEY_NO_MATCH)) {
                                    //boolean add = false;

                                    if(sph == true && type.equals("R")){//P.H*
                                        phonInfo.put(el.getElementByName("PhoneFldNum").getValue(), pn);
                                    }
                                    if(spa == true && type.equals("H")){//P.A
                                        phonInfo.put(el.getElementByName("PhoneFldNum").getValue(), pn);
                                    }
                                    if(spb == true && type.equals("B")){//P.B
                                        phonInfo.put(el.getElementByName("PhoneFldNum").getValue(), pn);
                                    }
                                    if(spt == true && type.equals("A")){//P.T
                                        phonInfo.put(el.getElementByName("PhoneFldNum").getValue(), pn);
                                    }

                                }
                                //phonInfo.put(el.getElementByName("PhoneFldNum").getValue(), el.getElementByName("Phone").getValue());
                            }
                        }
                    }


                    if(elName.equals("Email")) {
                        String et = (el.getElementByName("Type").getValue()).trim();
                        if(et!=null){
                            if(et.equals("T")){
                                email.put(el.getElementByName("ItemNum").getValue(), el.getElementByName("Data").getValue());
                            }
                        }
                    }
                    //+++++++++++++++++++++++++++++++++++++++++++++++++++++

                    if(elName.equals("AirSeg")) {
                        //HashMap<String, String> airSeg = new HashMap<String, String>();
                        JSONObject airSeg = new JSONObject();

                        airSeg.put("SegNum", el.getElementByName("SegNum").getValue());					
                        airSeg.put("AirV", el.getElementByName("AirV").getValue());
                        airSeg.put("FltNum", el.getElementByName("FltNum").getValue());
                        airSeg.put("StartAirp", el.getElementByName("StartAirp").getValue());
                        airSeg.put("EndAirp", el.getElementByName("EndAirp").getValue());
                        airSeg.put("StartTm", formatTime(el.getElementByName("StartTm").getValue()));
                        airSeg.put("EndTm", formatTime(el.getElementByName("EndTm").getValue()));
                        airSeg.put("Dt", formatDate(el.getElementByName("Dt").getValue()));

                        airSegments.add(airSeg);
                    }

                    if(elName.equals("ProgramaticSSRText")){
                        JSONObject ticket = new JSONObject();
                        ticket.put("ticket" , el.getElementByName("Text").getValue());
                        //ticket_count += 1;
                        tickets.add(ticket);
                    }
                }
            }catch(Exception ef){
                log.severe("Exception : " + ef.toString());
            }
			
			JSONArray names = new JSONArray();
			
			
			for (String nKey : lName.keySet()) {
				JSONObject name = new JSONObject();
				name.put("key", nKey);
				name.put("name", lName.get(nKey) + " " + fName.get(nKey) );
                name.put("email", email.get(nKey));
				//add phone number to match key
                
                
                try{
                    int phonenKey = Integer.parseInt(nKey) + 1;
				    String p = phonInfo.get(nKey);
                    log.info("names > phone :: Phone in Key : " + p + "\n");
                    name.put("phone", formatPhonenumber(p));    
                }catch(NumberFormatException nfe){
                    log.severe("NumberFormatException : " + nfe.toString());
                }catch(NullPointerException npe){
                    log.severe("NullPointerException : " + npe.toString());
                }catch(Exception ex){
                    log.severe("Exception : " + ex.toString());
                }
				 
				names.add(name);
			}
			
			
			//JSONArray phones = new JSONArray();;
			
			/*for (String nKey : phonInfo.keySet()) {
				JSONObject phone = new JSONObject();
				String p = phonInfo.get(nKey);
				phone.put("key", nKey);
				//phone.put("phone", formatPhonenumber(p.substring((p.indexOf("*")) + 1)));
				phone.put("phone", formatPhonenumber(p)); // after regex is used
				phones.add(phone);
			}*/
			
			//=======================================================================
			
			
			rsp.setContentType("application/json");
			PrintWriter out = rsp.getWriter();
			JSONObject jobj=new JSONObject();
			jobj.put("success", 1);
			jobj.put("RecLoc", RecLoc);
            jobj.put("VndRecLocs", VendoRecLoc);
            jobj.put("segments", airSegments);
            //jobj.put("phones", phones);
            jobj.put("names", names);
            jobj.put("tickets", tickets);
            //jobj.put("show_fare", session.getAttribute( "show_fare" ));
           // jobj.put("gds_free_field", session.getAttribute( "gds_free_field" ));
            jobj.put("message", "PNR Processed Successfully");
            
            /*if(req.getParameter("fare_xml") == null ){
				jobj.put("fare", 0 );
            }else if(req.getParameter("fare_xml").equals("No fares")){
				jobj.put("fare", 00 );
            }else{
				jobj.put("fares", getFare(fare_xml_string));
            }*/
            
            out.print(jobj);
            System.out.println("\n\nJSON ALL : " + jobj.toString());
           
		}
        
        
        //--cat
        else{
			rsp.setContentType("application/json");
			PrintWriter out = rsp.getWriter();
			JSONObject jobj=new JSONObject();
			jobj.put("success", 0);
			jobj.put("message", "PNR Sent Was Empty");
			out.print(jobj);
		} 
	}
	
	private String formatDate(String s){
		String d = s.substring(6,8) + "/" + s.substring(4,6) + "/" + s.substring(0,4);
		return d;
	}
    
	private String formatTime(String s){
        String d = "";
		try{
            if(s.length() == 3){
                s = "0" + s;
            }else if(s.length() == 2){
                s = "00" + s;
            }else if(s.length() == 1){
                s = "000" + s;
            }
            
            d = s.substring(0,2) + "" + s.substring(2,4); //String d = s.substring(0,2) + ":" + s.substring(2,4);
        
        }catch(Exception ex){
            log.severe("Exception : " + ex.toString());
        }
		return d;
	}
	
	public  String getPhoneFromString(String string){
		String r = "";
		String pt1 = "07\\d{8}"; // 0725987342
		String pt2 = "2547\\d{8}"; //254725987342
		String pt3 = "\\+2547\\d{8}"; //+254725987342
		String [] patterns = {pt1, pt2, pt3 };
		
		String [] toremove = {" ", "-", "\t"}; // remove posible characters in between numbers
		
		for(String s : toremove){
			string = string.replaceAll(s, "");
		}
		
		for(String pt : patterns){
			Pattern pattern = Pattern.compile(pt);
			Matcher matcher = pattern.matcher(string);
			
			if (matcher.find()) {
			    r = matcher.group(0);
			    break;
			}else{
				r = KEY_NO_MATCH;
			}
		}		
		return r;
	}
	
	private String formatPhonenumber(String s){
        log.info("formatPhonenumber :: Phone in : " + s + "\n");
		String d = "";
        try{
            if(s.substring(0,1).equals("0")){
                d = "254" + s.substring(1);
            }else{
                d = s;
            }
        }catch(NullPointerException e){
            log.severe("NullPointerException : " + e.toString());
        }
		
		return d;
	}
	public String nullChecker(String s){
		String r = "";
		if(s.equals("") || s == null){
			r = "null";
		}else{
			r = s;
		}
		return r;
	}
	//==================================================================================================

	
}
