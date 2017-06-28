<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tm="http://microsoft.com/wsdl/mime/textMatching/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:tns="http://tempuri.org/" xmlns:s="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" targetNamespace="http://tempuri.org/" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="http://tempuri.org/">
      <s:element name="GetPersonal">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="_RequestRefID" type="s:string"/>
            <s:element minOccurs="0" maxOccurs="1" name="_RequestProductCode" type="s:string"/>
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="GetPersonalResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="GetPersonalResult" type="s:string"/>
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="GetPersonalProcessedReport">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="_RequestParams" type="tns:ProductRequestParam"/>
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:complexType name="ProductRequestParam">
        <s:sequence>
          <s:element minOccurs="0" maxOccurs="1" name="ProductName" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="AccessPurpose" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="PrimaryIDType" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="BankCode" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="CompanyName" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="UserName" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="ProductCode" type="s:string"/>
          <s:element minOccurs="0" maxOccurs="1" name="PrimaryID" type="s:string"/>
        </s:sequence>
      </s:complexType>
      <s:element name="GetPersonalProcessedReportResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="GetPersonalProcessedReportResult"/>
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="GetCorporateProcessedReport">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="_RequestParams" type="tns:ProductRequestParam"/>
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="GetCorporateProcessedReportResponse">
        <s:complexType>
          <s:sequence>
            <s:element minOccurs="0" maxOccurs="1" name="GetCorporateProcessedReportResult"/>
          </s:sequence>
        </s:complexType>
      </s:element>
      <s:element name="string" nillable="true" type="s:string"/>
    </s:schema>
  </wsdl:types>
  <wsdl:message name="GetPersonalSoapIn">
    <wsdl:part name="parameters" element="tns:GetPersonal"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalSoapOut">
    <wsdl:part name="parameters" element="tns:GetPersonalResponse"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalProcessedReportSoapIn">
    <wsdl:part name="parameters" element="tns:GetPersonalProcessedReport"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalProcessedReportSoapOut">
    <wsdl:part name="parameters" element="tns:GetPersonalProcessedReportResponse"/>
  </wsdl:message>
  <wsdl:message name="GetCorporateProcessedReportSoapIn">
    <wsdl:part name="parameters" element="tns:GetCorporateProcessedReport"/>
  </wsdl:message>
  <wsdl:message name="GetCorporateProcessedReportSoapOut">
    <wsdl:part name="parameters" element="tns:GetCorporateProcessedReportResponse"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalHttpGetIn">
    <wsdl:part name="_RequestRefID" type="s:string"/>
    <wsdl:part name="_RequestProductCode" type="s:string"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalHttpGetOut">
    <wsdl:part name="Body" element="tns:string"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalHttpPostIn">
    <wsdl:part name="_RequestRefID" type="s:string"/>
    <wsdl:part name="_RequestProductCode" type="s:string"/>
  </wsdl:message>
  <wsdl:message name="GetPersonalHttpPostOut">
    <wsdl:part name="Body" element="tns:string"/>
  </wsdl:message>
  <wsdl:portType name="GetProductSoap">
    <wsdl:operation name="GetPersonal">
      <wsdl:input message="tns:GetPersonalSoapIn"/>
      <wsdl:output message="tns:GetPersonalSoapOut"/>
    </wsdl:operation>
    <wsdl:operation name="GetPersonalProcessedReport">
      <wsdl:input message="tns:GetPersonalProcessedReportSoapIn"/>
      <wsdl:output message="tns:GetPersonalProcessedReportSoapOut"/>
    </wsdl:operation>
    <wsdl:operation name="GetCorporateProcessedReport">
      <wsdl:input message="tns:GetCorporateProcessedReportSoapIn"/>
      <wsdl:output message="tns:GetCorporateProcessedReportSoapOut"/>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:portType name="GetProductHttpGet">
    <wsdl:operation name="GetPersonal">
      <wsdl:input message="tns:GetPersonalHttpGetIn"/>
      <wsdl:output message="tns:GetPersonalHttpGetOut"/>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:portType name="GetProductHttpPost">
    <wsdl:operation name="GetPersonal">
      <wsdl:input message="tns:GetPersonalHttpPostIn"/>
      <wsdl:output message="tns:GetPersonalHttpPostOut"/>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="GetProductSoap" type="tns:GetProductSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="GetPersonal">
      <soap:operation soapAction="http://tempuri.org/GetPersonal" style="document"/>
      <wsdl:input>
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="GetPersonalProcessedReport">
      <soap:operation soapAction="http://tempuri.org/GetPersonalProcessedReport" style="document"/>
      <wsdl:input>
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="GetCorporateProcessedReport">
      <soap:operation soapAction="http://tempuri.org/GetCorporateProcessedReport" style="document"/>
      <wsdl:input>
        <soap:body use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="GetProductSoap12" type="tns:GetProductSoap">
    <soap12:binding transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="GetPersonal">
      <soap12:operation soapAction="http://tempuri.org/GetPersonal" style="document"/>
      <wsdl:input>
        <soap12:body use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="GetPersonalProcessedReport">
      <soap12:operation soapAction="http://tempuri.org/GetPersonalProcessedReport" style="document"/>
      <wsdl:input>
        <soap12:body use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
    <wsdl:operation name="GetCorporateProcessedReport">
      <soap12:operation soapAction="http://tempuri.org/GetCorporateProcessedReport" style="document"/>
      <wsdl:input>
        <soap12:body use="literal"/>
      </wsdl:input>
      <wsdl:output>
        <soap12:body use="literal"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="GetProductHttpGet" type="tns:GetProductHttpGet">
    <http:binding verb="GET"/>
    <wsdl:operation name="GetPersonal">
      <http:operation location="/GetPersonal"/>
      <wsdl:input>
        <http:urlEncoded/>
      </wsdl:input>
      <wsdl:output>
        <mime:mimeXml part="Body"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:binding name="GetProductHttpPost" type="tns:GetProductHttpPost">
    <http:binding verb="POST"/>
    <wsdl:operation name="GetPersonal">
      <http:operation location="/GetPersonal"/>
      <wsdl:input>
        <mime:content type="application/x-www-form-urlencoded"/>
      </wsdl:input>
      <wsdl:output>
        <mime:mimeXml part="Body"/>
      </wsdl:output>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="GetProduct">
    <wsdl:port name="GetProductSoap" binding="tns:GetProductSoap">
      <soap:address location="https://mcrb.metropol.co.ke/Services/GetProduct.asmx"/>
    </wsdl:port>
    <wsdl:port name="GetProductSoap12" binding="tns:GetProductSoap12">
      <soap12:address location="https://mcrb.metropol.co.ke/Services/GetProduct.asmx"/>
    </wsdl:port>
    <wsdl:port name="GetProductHttpGet" binding="tns:GetProductHttpGet">
      <http:address location="https://mcrb.metropol.co.ke/Services/GetProduct.asmx"/>
    </wsdl:port>
    <wsdl:port name="GetProductHttpPost" binding="tns:GetProductHttpPost">
      <http:address location="https://mcrb.metropol.co.ke/Services/GetProduct.asmx"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>