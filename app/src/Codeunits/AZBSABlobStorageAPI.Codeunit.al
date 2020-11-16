// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 89000 "AZBSA Blob Storage API"
{
    // See: https://docs.microsoft.com/en-us/rest/api/storageservices/blob-service-rest-api

    trigger OnRun()
    begin

    end;

    // #region (PUT) Create Containers
    /// <summary>
    /// List all Containers in specific Storage Account and outputs the result to the user
    /// see: https://docs.microsoft.com/en-us/rest/api/storageservices/create-container
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    /// <param name="ContainerName">The Name of the Container that should be created.</param>
    procedure CreateContainer(StorageAccountName: Text; ContainerName: Text[50]; RequestObject: Codeunit "AZBSA Request Object")
    var
        WebRequestHelper: Codeunit "AZBSA Web Request Helper";
        HelperLibrary: Codeunit "AZBSA Helper Library";
        Operation: Enum "AZBSA Blob Storage Operation";
        Url: Text;
        OperationNotSuccessfulErr: Label 'Could not create container %1.', Comment = '%1 = Container Name';
    begin
        Url := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::PutContainer, ContainerName, '');

        WebRequestHelper.PutOperation(Url, StorageAccountName, RequestObject, StrSubstNo(OperationNotSuccessfulErr, ContainerName));
    end;
    // #endregion 

    // #region (GET) List Available Containers
    // TODO: Implement optional parameters

    /// <summary>
    /// List all Containers in specific Storage Account and outputs the result to the user
    /// see: https://docs.microsoft.com/en-us/rest/api/storageservices/list-containers2
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    procedure ListContainers(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object")
    begin
        ListContainers(StorageAccountName, RequestObject, true);
    end;

    /// <summary>
    /// List Containers in specific Storage Account
    /// see: https://docs.microsoft.com/en-us/rest/api/storageservices/list-containers2
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    /// <param name="ShowOutput">Determines if the result should be shown as a Page to the user.</param>
    procedure ListContainers(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ShowOutput: Boolean)
    var
        BlobStorageContainer: Record "AZBSA Container";
    begin
        ListContainers(StorageAccountName, RequestObject, BlobStorageContainer, ShowOutput);
    end;

    /// <summary>
    /// List Containers in specific Storage Account
    /// see: https://docs.microsoft.com/en-us/rest/api/storageservices/list-containers2
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    /// <param name="BlobStorageContainer">Collection of the result (temporary record).</param>
    /// <param name="ShowOutput">Determines if the result should be shown as a Page to the user.</param>
    procedure ListContainers(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; var BlobStorageContainer: Record "AZBSA Container"; ShowOutput: Boolean)
    var
        WebRequestHelper: Codeunit "AZBSA Web Request Helper";
        HelperLibrary: Codeunit "AZBSA Helper Library";
        Operation: Enum "AZBSA Blob Storage Operation";
        ResponseText: Text;
        Url: Text;
        NodeList: XmlNodeList;
    begin
        Url := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::ListContainers, '', '');

        WebRequestHelper.GetResponseAsText(Url, StorageAccountName, RequestObject, ResponseText); // might throw error

        NodeList := HelperLibrary.CreateContainerNodeListFromResponse(ResponseText);
        BlobStorageContainer.SetBaseInfos(StorageAccountName, '', RequestObject);
        HelperLibrary.ContainerNodeListTotempRecord(NodeList, BlobStorageContainer);
        if ShowOutput then
            HelperLibrary.ShowTempRecordLookup(BlobStorageContainer);
    end;
    // #endregion

    // #region (GET) List Container Contents
    /// <summary>
    /// Lists the Blobs in a specific container and outputs the result to the user
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    /// <param name="ContainerName">The Name of the Container which contents should be listed.</param>
    procedure ListBlobs(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text[50])
    begin
        ListBlobs(StorageAccountName, RequestObject, ContainerName, true);
    end;

    /// <summary>
    /// Lists the Blobs in a specific container
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    /// <param name="ContainerName">The Name of the Container which contents should be listed.</param>
    /// <param name="ShowOutput">Determines if the result should be shown as a Page to the user.</param>
    procedure ListBlobs(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text[50]; ShowOutput: Boolean)
    var
        BlobStorageContent: Record "AZBSA Container Content";
    begin
        ListBlobs(StorageAccountName, RequestObject, ContainerName, BlobStorageContent, ShowOutput);
    end;

    /// <summary>
    /// Lists the Blobs in a specific container
    /// </summary>
    /// <param name="StorageAccountName">The Storage Account to connect to.</param>
    /// <param name="Authorization">Contains information with Authorization to use for authentication.</param>
    /// <param name="ContainerName">The Name of the Container which contents should be listed.</param>
    /// <param name="BlobStorageContent">Collection of the result (temporary record).</param>
    /// <param name="ShowOutput">Determines if the result should be shown as a Page to the user.</param>
    procedure ListBlobs(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; var BlobStorageContent: Record "AZBSA Container Content"; ShowOutput: Boolean)
    var
        HelperLibrary: Codeunit "AZBSA Helper Library";
        WebRequestHelper: Codeunit "AZBSA Web Request Helper";
        Operation: Enum "AZBSA Blob Storage Operation";
        ResponseText: Text;
        Url: Text;
        NodeList: XmlNodeList;
    begin
        Url := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::ListContainerContents, ContainerName, '');

        WebRequestHelper.GetResponseAsText(Url, StorageAccountName, RequestObject, ResponseText); // might throw error

        NodeList := HelperLibrary.CreateBlobNodeListFromResponse(ResponseText);
        BlobStorageContent.SetBaseInfos(StorageAccountName, ContainerName, RequestObject);
        HelperLibrary.BlobNodeListToTempRecord(NodeList, BlobStorageContent);
        if ShowOutput then
            HelperLibrary.ShowTempRecordLookup(BlobStorageContent);
    end;
    // #endregion (GET) ListContainerContents

    // #region (PUT) Upload Blob into Container
    procedure UploadBlobIntoContainerUI(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text)
    var
        Filename: Text;
        SourceStream: InStream;
    begin
        if UploadIntoStream('Upload File', '', '', Filename, SourceStream) then
            UploadBlobIntoContainerStream(StorageAccountName, RequestObject, ContainerName, Filename, SourceStream);
    end;

    procedure UploadBlobIntoContainerStream(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; Filename: Text; var SourceStream: InStream)
    var
        SourceContent: Variant;
    begin
        SourceContent := SourceStream;
        UploadBlobIntoContainer(StorageAccountName, RequestObject, ContainerName, Filename, SourceContent);
    end;

    procedure UploadBlobIntoContainerText(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; Filename: Text; var SourceText: Text)
    var
        SourceContent: Variant;
    begin
        SourceContent := SourceText;
        UploadBlobIntoContainer(StorageAccountName, RequestObject, ContainerName, Filename, SourceContent);
    end;

    local procedure UploadBlobIntoContainer(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; BlobName: Text; var SourceContent: Variant)
    var
        HelperLibrary: Codeunit "AZBSA Helper Library";
        WebRequestHelper: Codeunit "AZBSA Web Request Helper";
        Operation: Enum "AZBSA Blob Storage Operation";
        Url: Text;
        Content: HttpContent;
        SourceStream: InStream;
        SourceText: Text;
        OperationNotSuccessfulErr: Label 'Could not upload %1 to %2', Comment = '%1 = Blob Name; %2 = Container Name';
    begin
        Url := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::PutBlob, ContainerName, BlobName);

        case true of
            SourceContent.IsInStream():
                begin
                    SourceStream := SourceContent;
                    WebRequestHelper.AddBlobPutBlockBlobContentHeaders(Content, RequestObject, SourceStream);
                end;
            SourceContent.IsText():
                begin
                    SourceText := SourceContent;
                    WebRequestHelper.AddBlobPutBlockBlobContentHeaders(Content, RequestObject, SourceText);
                end;
        end;

        WebRequestHelper.PutOperation(Url, StorageAccountName, RequestObject, Content, StrSubstNo(OperationNotSuccessfulErr, BlobName, ContainerName));
    end;
    // #endregion

    // #region (GET) Get Blob from Container
    procedure DownloadBlobAsFileWithSelect(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text)
    var
        BlobStorageContent: Record "AZBSA Container Content";
        HelperLibrary: Codeunit "AZBSA Helper Library";
        BlobName: Text;
    begin
        // Get list of available blobs
        ListBlobs(StorageAccountName, RequestObject, ContainerName, BlobStorageContent, false);
        // Show Lookup Page to select Blob to download
        BlobName := HelperLibrary.LookupContainerContent(BlobStorageContent);
        // Download Blob
        DownloadBlobAsFile(StorageAccountName, RequestObject, ContainerName, BlobName);
    end;

    procedure DownloadBlobAsFile(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; BlobName: Text)
    var
        TargetStream: InStream;
    begin
        DownloadBlobAsStream(StorageAccountName, RequestObject, ContainerName, BlobName, TargetStream);
        DownloadFromStream(TargetStream, '', '', '', BlobName);
    end;

    procedure DownloadBlobAsStream(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; BlobName: Text; var TargetStream: InStream)
    var
        WebRequestHelper: Codeunit "AZBSA Web Request Helper";
        HelperLibrary: Codeunit "AZBSA Helper Library";
        Operation: Enum "AZBSA Blob Storage Operation";
        Url: Text;
    begin
        Url := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::GetBlob, ContainerName, BlobName);

        WebRequestHelper.GetResponseAsStream(Url, StorageAccountName, RequestObject, TargetStream);
    end;

    procedure DownloadBlobAsText(StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; ContainerName: Text; BlobName: Text; var TargetText: Text)
    var
        WebRequestHelper: Codeunit "AZBSA Web Request Helper";
        HelperLibrary: Codeunit "AZBSA Helper Library";
        Operation: Enum "AZBSA Blob Storage Operation";
        Url: Text;
    begin
        Url := HelperLibrary.ConstructUrl(StorageAccountName, RequestObject, Operation::GetBlob, ContainerName, BlobName);

        WebRequestHelper.GetResponseAsText(Url, StorageAccountName, RequestObject, TargetText);
    end;
    // #endregion

    // TODO: Add Delete Blob    
}