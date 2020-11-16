// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 89001 "AZBSA Container"
{
    DataClassification = CustomerContent;
    TableType = Temporary;
    LookupPageId = "AZBSA Container";
    DrillDownPageId = "AZBSA Container";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(10; Name; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(11; "Last-Modified"; DateTime)
        {
            DataClassification = CustomerContent;
        }
        field(12; LeaseStatus; Text[15])
        {
            DataClassification = CustomerContent;
        }
        field(13; LeaseState; Text[15])
        {
            DataClassification = CustomerContent;
        }
        field(14; DefaultEncryptionScope; Text[50])
        {
            DataClassification = CustomerContent;
        }
        field(15; DenyEncryptionScopeOverride; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(16; HasImmutabilityPolicy; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(17; HasLegalHold; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(100; "XML Value"; Blob)
        {
            DataClassification = CustomerContent;
        }
        field(110; URI; Text[250])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
    var
        RequestObject: Codeunit "AZBSA Request Object";
        StorageAccountName: Text;
        ContainerName: Text;

    procedure SetBaseInfos(NewStorageAccountName: Text; NewContainerName: Text; NewRequestObject: Codeunit "AZBSA Request Object")
    begin
        StorageAccountName := NewStorageAccountName;
        ContainerName := NewContainerName;
        RequestObject := NewRequestObject;
    end;

    procedure AddNewEntryFromNode(var Node: XmlNode; XPathName: Text)
    var
        HelperLibrary: Codeunit "AZBSA Helper Library";
        NameFromXml: Text;
        OuterXml: Text;
        ChildNodes: XmlNodeList;
        PropertiesNode: XmlNode;
    begin
        NameFromXml := HelperLibrary.GetValueFromNode(Node, XPathName);
        Node.WriteTo(OuterXml);
        Node.SelectSingleNode('.//Properties', PropertiesNode);
        ChildNodes := PropertiesNode.AsXmlElement().GetChildNodes();
        if ChildNodes.Count = 0 then
            Rec.AddNewEntry(NameFromXml, OuterXml)
        else
            Rec.AddNewEntry(NameFromXml, OuterXml, ChildNodes);
    end;

    procedure AddNewEntry(NameFromXml: Text; OuterXml: Text)
    var
        ChildNodes: XmlNodeList;
    begin
        AddNewEntry(NameFromXml, OuterXml, ChildNodes);
    end;

    procedure AddNewEntry(NameFromXml: Text; OuterXml: Text; ChildNodes: XmlNodeList)
    var
        NextEntryNo: Integer;
        Outstr: OutStream;
    begin
        NextEntryNo := GetNextEntryNo();

        Rec.Init();
        Rec."Entry No." := NextEntryNo;
        Rec.Name := CopyStr(NameFromXml, 1, 250);
        SetPropertyFields(ChildNodes);
        Rec."XML Value".CreateOutStream(Outstr);
        Outstr.Write(OuterXml);
        //Rec.URI := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::ListContainerContents, ContainerName, NameFromXml);
        Rec.Insert(true);
    end;

    local procedure GetNextEntryNo(): Integer
    begin
        if Rec.FindLast() then
            exit(Rec."Entry No." + 1)
        else
            exit(1);
    end;

    local procedure SetPropertyFields(ChildNodes: XmlNodeList)
    var
        FormatHelper: Codeunit "AZBSA Format Helper";
        HelperLibrary: Codeunit "AZBSA Helper Library";
        RecRef: RecordRef;
        FldRef: FieldRef;
        ChildNode: XmlNode;
        PropertyName: Text;
        PropertyValue: Text;
        FldNo: Integer;
    begin
        foreach ChildNode in ChildNodes do begin
            PropertyName := ChildNode.AsXmlElement().Name;
            PropertyValue := ChildNode.AsXmlElement().InnerText;
            if PropertyValue <> '' then begin
                RecRef.GetTable(Rec);
                if HelperLibrary.GetFieldByName(Database::"AZBSA Container", PropertyName, FldNo) then begin
                    FldRef := RecRef.Field(FldNo);
                    case FldRef.Type of
                        FldRef.Type::DateTime:
                            FldRef.Value := FormatHelper.ConvertToDateTime(PropertyValue);
                        FldRef.Type::Integer:
                            FldRef.Value := FormatHelper.ConvertToInteger(PropertyValue);
                        FldRef.Type::Boolean:
                            FldRef.Value := FormatHelper.ConvertToBoolean(PropertyValue);
                        else
                            FldRef.Value := PropertyValue;
                    end;
                end;
            end;
            RecRef.SetTable(Rec);
        end;
    end;
}