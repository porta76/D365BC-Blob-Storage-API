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
    begin
        if BlobStorageContent.IsEmpty() then begin
            Message(ResultCollectionEmptyMsg);
            exit;
        end;
        Page.Run(0, BlobStorageContent);
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

    // #region URL Helper 
    procedure ConstructUrl(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; Operation: Enum "AZBSA Blob Storage Operation"; ContainerName: Text; BlobName: Text): Text
    var
        AuthorizationType: Enum "AZBSA Authorization Type";
        ConstructedUrl: Text;
        BlobStorageBaseUrlLbl: Label 'https://%1.blob.core.windows.net', Comment = '%1 = Storage Account Name';
        SingleContainerLbl: Label '%1/%2?restype=container%3', Comment = '%1 = Base URL; %2 = Container Name ; %3 = List-extension (if applicable) ;%4 = SaS Token';
        ListContainerExtensionLbl: Label '&comp=list', Comment = '%1 = Base URL; %2 = Container Name ; %3 = SaS Token';
        SingleBlobInContainerLbl: Label '%1/%2/%3', Comment = '%1 = Base URL; %2 = Container Name ; %3 = Blob Name ; %4 = SaS Token';
    begin
        TestConstructUrlParameter(StorageAccountName, RequestObject, Operation, ContainerName, BlobName);

        ConstructedUrl := StrSubstNo(BlobStorageBaseUrlLbl, StorageAccountName);
        case Operation of
            Operation::ListContainers:
                ConstructedUrl := StrSubstNo(SingleContainerLbl, ConstructedUrl, '', ListContainerExtensionLbl); // https://<StorageAccountName>.blob.core.windows.net/?restype=container&comp=list&<SaSToken>
            Operation::ListContainerContents:
                ConstructedUrl := StrSubstNo(SingleContainerLbl, ConstructedUrl, ContainerName, ListContainerExtensionLbl); // https://<StorageAccountName>.blob.core.windows.net/<ContainerName>?restype=container&comp=list&<SaSToken>
            Operation::PutContainer:
                ConstructedUrl := StrSubstNo(SingleContainerLbl, ConstructedUrl, ContainerName, ''); // https://<StorageAccountName>.blob.core.windows.net/<ContainerName>?restype=container&<SaSToken>
            Operation::GetBlob, Operation::PutBlob, Operation::DeleteBlob:
                ConstructedUrl := StrSubstNo(SingleBlobInContainerLbl, ConstructedUrl, ContainerName, BlobName); // https://<StorageAccountName>.blob.core.windows.net/<ContainerName>/<BlobName>?<SaSToken>
        end;

        // If SaS-Token is used for authentication, append it to the URI
        if RequestObject.GetAuthorizationType() = AuthorizationType::SasToken then
            if ConstructedUrl.Contains('?') then
                ConstructedUrl += '&' + RequestObject.GetSecret()
            else
                ConstructedUrl += '?' + RequestObject.GetSecret();
        exit(ConstructedUrl);
    end;

    /// <summary>
    /// Tests if all parameters necessary for the operation are given. Throws error if parameters are incomplete.
    /// </summary>
    /// <param name="StorageAccountName">The Name of the Azure Storage Account. Mandatory for all operations.</param>
    /// <param name="SaSToken">The Shared Access Signature (Token) used to perform the desired operation. Mandatory for all operations.</param>
    /// <param name="Operation">The type of the Operation. Mandatory.</param>
    /// <param name="ContainerName">The name of the container to access. Mandatory for all container- and BLOB-specific operations.</param>
    /// <param name="BlobName">The name of the BLOB. Mandatory for all BLOB-specific operations</param>
    local procedure TestConstructUrlParameter(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; Operation: Enum "AZBSA Blob Storage Operation"; ContainerName: Text; BlobName: Text)
    var
        AuthorizationType: Enum "AZBSA Authorization Type";
        ValueCanNotBeEmptyErr: Label '%1 can not be empty', Comment = '%1 = Variable Name';
        StorageAccountNameLbl: Label 'Storage Account Name';
        SasTokenLbl: Label 'Shared Access Signature (Token)';
        AccesKeyLbl: Label 'Access Key';
        ContainerNameLbl: Label 'Container Name';
        BlobNameLbl: Label 'Blob Name';
    begin
        if StorageAccountName = '' then
            Error(ValueCanNotBeEmptyErr, StorageAccountNameLbl);

        case RequestObject.GetAuthorizationType() of
            AuthorizationType::SasToken:
                if RequestObject.GetSecret() = '' then
                    Error(ValueCanNotBeEmptyErr, SasTokenLbl);
            AuthorizationType::SharedKey:
                if RequestObject.GetSecret() = '' then
                    Error(ValueCanNotBeEmptyErr, AccesKeyLbl);
        end;

        case true of
            Operation in [Operation::GetBlob, Operation::PutBlob, Operation::DeleteBlob]:
                begin
                    if ContainerName = '' then
                        Error(ValueCanNotBeEmptyErr, ContainerNameLbl);
                    if BlobName = '' then
                        Error(ValueCanNotBeEmptyErr, BlobNameLbl);
                end;
        end;
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