// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 89002 "AZBSA Helper Library"
{
    Access = Internal;

    trigger OnRun()
    begin

    end;

    var
        ResultCollectionEmptyMsg: Label 'The result set is empty';
    //PropertyPlaceholderLbl: Label '%1: %2', Comment = '%1 = Property Name, %2 = Property Value';

    // #region Container-specific Helper
    procedure ContainerNodeListTotempRecord(NodeList: XmlNodeList; var BlobStorageContent: Record "AZBSA Container Content")
    begin
        NodeListToTempRecord(NodeList, './/Name', BlobStorageContent);
    end;

    procedure ContainerNodeListTotempRecord(NodeList: XmlNodeList; var BlobStorageContainer: Record "AZBSA Container")
    begin
        NodeListToTempRecord(NodeList, './/Name', BlobStorageContainer);
    end;

    procedure CreateContainerNodeListFromResponse(ResponseAsText: Text): XmlNodeList
    begin
        exit(CreateXPathNodeListFromResponse(ResponseAsText, '/*/Containers/Container'));
    end;
    // #endregion

    // #region Blob-specific Helper
    procedure CreateBlobNodeListFromResponse(ResponseAsText: Text): XmlNodeList
    begin
        exit(CreateXPathNodeListFromResponse(ResponseAsText, '/*/Blobs/Blob'));
    end;

    procedure BlobNodeListToTempRecord(NodeList: XmlNodeList)
    var
        BlobStorageContent: Record "AZBSA Container Content";
    begin
        BlobNodeListToTempRecord(NodeList, BlobStorageContent);
    end;

    procedure BlobNodeListToTempRecord(NodeList: XmlNodeList; var BlobStorageContent: Record "AZBSA Container Content")
    begin
        NodeListToTempRecord(NodeList, './/Name', BlobStorageContent);
    end;
    // #endregion

    procedure ShowTempRecordLookup(var BlobStorageContent: Record "AZBSA Container Content")
    var
        ContainerContents: Page "AZBSA Container Content";
    begin
        if BlobStorageContent.IsEmpty() then begin
            Message(ResultCollectionEmptyMsg);
            exit;
        end;
        ContainerContents.InitializeFromTempRec(BlobStorageContent);
        ContainerContents.Run();
    end;

    procedure ShowTempRecordLookup(var BlobStorageContainer: Record "AZBSA Container")
    begin
        if BlobStorageContainer.IsEmpty() then begin
            Message(ResultCollectionEmptyMsg);
            exit;
        end;
        Page.Run(0, BlobStorageContainer);
    end;

    procedure LookupContainerContent(var BlobStorageContent: Record "AZBSA Container Content"): Text
    var
        BlobStorageContentReturn: Record "AZBSA Container Content";
        ContainerContent: Page "AZBSA Container Content";
    begin
        if BlobStorageContent.IsEmpty() then
            exit('');

        BlobStorageContent.FindSet(false, false);
        repeat
            ContainerContent.AddEntry(BlobStorageContent);
        until BlobStorageContent.Next() = 0;
        ContainerContent.LookupMode(true);
        if ContainerContent.RunModal() = Action::LookupOK then begin
            ContainerContent.GetRecord(BlobStorageContentReturn);
            exit(BlobStorageContentReturn."Full Name");
        end;
    end;

    // #region XML Helper
    local procedure GetXmlDocumentFromResponse(var Document: XmlDocument; ResponseAsText: Text)
    var
        ReadingAsXmlErr: Label 'Error reading Response as XML.';
    begin
        if not XmlDocument.ReadFrom(ResponseAsText, Document) then
            Error(ReadingAsXmlErr);
    end;

    local procedure CreateXPathNodeListFromResponse(ResponseAsText: Text; XPath: Text): XmlNodeList
    var
        Document: XmlDocument;
        RootNode: XmlElement;
        NodeList: XmlNodeList;
    begin
        GetXmlDocumentFromResponse(Document, ResponseAsText);
        Document.GetRoot(RootNode);
        RootNode.SelectNodes(XPath, NodeList);
        exit(NodeList);
    end;

    procedure GetValueFromNode(Node: XmlNode; XPath: Text): Text
    var
        Node2: XmlNode;
        Value: Text;
    begin
        Node.SelectSingleNode(XPath, Node2);
        Value := Node2.AsXmlElement().InnerText();
        exit(Value);
    end;

    local procedure NodeListToTempRecord(NodeList: XmlNodeList; XPathName: Text; var BlobStorageContent: Record "AZBSA Container Content")
    var
        Node: XmlNode;
    begin
        if not BlobStorageContent.IsTemporary() then
            Error('');
        BlobStorageContent.DeleteAll();

        if NodeList.Count = 0 then
            exit;
        foreach Node in NodeList do
            BlobStorageContent.AddNewEntryFromNode(Node, XPathName);
    end;

    local procedure NodeListToTempRecord(NodeList: XmlNodeList; XPathName: Text; var BlobStorageContainer: Record "AZBSA Container")
    var
        Node: XmlNode;
    begin
        if not BlobStorageContainer.IsTemporary() then
            Error('');
        BlobStorageContainer.DeleteAll();

        if NodeList.Count = 0 then
            exit;
        foreach Node in NodeList do
            BlobStorageContainer.AddNewEntryFromNode(Node, XPathName);
    end;
    // #endregion

    // #region Format Helper
    procedure GetFieldByName(TableNo: Integer; FldName: Text; var FldNo: Integer): Boolean
    var
        Fld: Record Field;
    begin
        Clear(FldNo);
        Fld.Reset();
        Fld.SetRange(TableNo, TableNo);
        Fld.SetRange(FieldName, FldName);
        if Fld.FindFirst() then
            FldNo := Fld."No.";
        exit(FldNo <> 0);
    end;
    // #endregion
}