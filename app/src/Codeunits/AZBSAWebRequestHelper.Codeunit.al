// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 89004 "AZBSA Web Request Helper"
{
    trigger OnRun()
    begin

    end;

    var
        ContentLengthLbl: Label '%1', Comment = '%1 = Length';

    // #region GET-Request
    /// <summary>
    /// Performs GET-request and includes the content of HttpResponseMessage as a Text-object
    /// </summary>
    /// <param name="Url">The URL to perform the GET-request against.</param>
    /// <param name="Response">The result of the GET-request as Text-object (by reference).</param>
    procedure GetResponseAsText(Url: Text; StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; var ResponseText: Text)
    var
        Response: HttpResponseMessage;
        ReadResponseFailedErr: Label 'Could not read response.';
    begin
        GetResponse(Url, StorageAccountName, RequestObject, Response);

        if not Response.Content.ReadAs(ResponseText) then
            Error(ReadResponseFailedErr);
    end;

    /// <summary>
    /// Performs GET-request and includes the content of HttpResponseMessage as a InStream-object
    /// </summary>
    /// <param name="Url">The URL to perform the GET-request against.</param>
    /// <param name="Response">The result of the GET-request as InStream-object (by reference).</param>
    procedure GetResponseAsStream(Url: Text; StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; var Stream: InStream)
    var
        Response: HttpResponseMessage;
        ReadResponseFailedErr: Label 'Could not read response.';
    begin
        GetResponse(Url, StorageAccountName, RequestObject, Response);

        if not Response.Content.ReadAs(Stream) then
            Error(ReadResponseFailedErr);
    end;

    /// <summary>
    /// Performs GET-request and includes HttpResponseMessageas VAR
    /// </summary>
    /// <param name="Url">The URL to perform the GET-request against.</param>
    /// <param name="Response">The result of the GET-request as HttpResponseMessage (by reference).</param>
    local procedure GetResponse(Url: Text; StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; var Response: HttpResponseMessage)
    var
        FormatHelper: Codeunit "AZBSA Format Helper";
        Client: HttpClient;
        HttpRequestType: Enum "Http Request Type";
        IntitialGetFailedErr: Label 'Could not connect to %1.\\Response Code: %2 %3', Comment = '%1 = Base URL; %2 = Status Code; %3 = Reason Phrase';
    begin
        HandleAuthorizationHeaders(HttpRequestType::GET, StorageAccountName, Url, Client, RequestObject);

        if not Client.Get(Url, Response) then
            Error(IntitialGetFailedErr, Url, Response.HttpStatusCode, Response.ReasonPhrase);
        if not Response.IsSuccessStatusCode then
            Error(IntitialGetFailedErr, FormatHelper.RemoveSasTokenParameterFromUrl(Url), Response.HttpStatusCode, Response.ReasonPhrase);
    end;
    // #endregion GET-Request

    // #region PUT-Request
    procedure PutOperation(Url: Text; StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; OperationNotSuccessfulErr: Text)
    var
        Content: HttpContent;
    begin
        PutOperation(Url, StorageAccountName, RequestObject, Content, OperationNotSuccessfulErr);
    end;

    procedure PutOperation(Url: Text; StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; Content: HttpContent; OperationNotSuccessfulErr: Text)
    var
        Response: HttpResponseMessage;
    begin
        PutOperation(Url, StorageAccountName, RequestObject, Content, Response, OperationNotSuccessfulErr);
    end;

    local procedure PutOperation(Url: Text; StorageAccountName: Text; RequestObject: Codeunit "AZBSA Request Object"; Content: HttpContent; var Response: HttpResponseMessage; OperationNotSuccessfulErr: Text)
    var
        Client: HttpClient;
        HttpRequestType: Enum "Http Request Type";
        RequestMsg: HttpRequestMessage;
        HttpResponseInfoErr: Label '%1.\\Response Code: %2 %3', Comment = '%1 = Default Error Message ; %2 = Status Code; %3 = Reason Phrase';
    begin
        HandleAuthorizationHeaders(HttpRequestType::PUT, StorageAccountName, Url, Client, RequestObject);
        // Prepare HttpRequestMessage
        RequestMsg.Method(Format(HttpRequestType::PUT));
        if ContentSet(Content) then
            RequestMsg.Content := Content;
        RequestMsg.SetRequestUri(Url);
        // Send Request    
        Client.Send(RequestMsg, Response);
        if not Response.IsSuccessStatusCode then
            Error(HttpResponseInfoErr, OperationNotSuccessfulErr, Response.HttpStatusCode, Response.ReasonPhrase);
    end;

    local procedure ContentSet(Content: HttpContent): Boolean
    var
        VarContent: Text;
    begin
        Content.ReadAs(VarContent);
        if StrLen(VarContent) > 0 then
            exit(true);

        exit(VarContent <> '');
    end;
    // #endregion PUT-Request

    // #region HTTP Header Helper
    procedure AddBlobPutBlockBlobContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; var SourceStream: InStream)
    var
        BlobType: Enum "AZBSA Blob Type";
    begin
        AddBlobPutContentHeaders(Content, RequestObject, SourceStream, BlobType::BlockBlob)
    end;

    procedure AddBlobPutBlockBlobContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; var SourceText: Text)
    var
        BlobType: Enum "AZBSA Blob Type";
    begin
        AddBlobPutContentHeaders(Content, RequestObject, SourceText, BlobType::BlockBlob)
    end;

    /*
    procedure AddBlobPutPageBlobContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; var SourceStream: InStream)
    var
        BlobType: Enum "AZBSA Blob Type";
    begin
        AddBlobPutContentHeaders(Content, RequestObject, SourceStream, BlobType::PageBlob)
    end;
    */
    procedure AddBlobPutAppendBlobContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; var SourceStream: InStream)
    var
        BlobType: Enum "AZBSA Blob Type";
    begin
        AddBlobPutContentHeaders(Content, RequestObject, SourceStream, BlobType::AppendBlob)
    end;

    local procedure AddBlobPutContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; var SourceStream: InStream; BlobType: Enum "AZBSA Blob Type")
    var
        Length: Integer;
    begin
        // Do this before calling "GetStreamLength", because for some reason the system errors out with "Cannot access a closed Stream."
        Content.WriteFrom(SourceStream);

        Length := GetStreamLength(SourceStream);

        AddBlobPutContentHeaders(Content, RequestObject, BlobType, Length, 'application/octet-stream');
    end;

    local procedure AddBlobPutContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; var SourceText: Text; BlobType: Enum "AZBSA Blob Type")
    var
        Length: Integer;
    begin
        // Do this before calling "GetStreamLength", because for some reason the system errors out with "Cannot access a closed Stream."
        Content.WriteFrom(SourceText);

        Length := StrLen(SourceText);

        AddBlobPutContentHeaders(Content, RequestObject, BlobType, Length, 'text/plain; charset=UTF-8');
    end;

    local procedure AddBlobPutContentHeaders(var Content: HttpContent; RequestObject: Codeunit "AZBSA Request Object"; BlobType: Enum "AZBSA Blob Type"; ContentLength: Integer; ContentType: Text)
    var
        Headers: HttpHeaders;
    begin
        if ContentType = '' then
            ContentType := 'application/octet-stream';
        Content.GetHeaders(Headers);
        RequestObject.AddHeader(Headers, 'Content-Type', ContentType);
        case BlobType of
            BlobType::PageBlob:
                begin
                    RequestObject.AddHeader(Headers, 'x-ms-blob-content-length', StrSubstNo(ContentLengthLbl, ContentLength));
                    RequestObject.AddHeader(Headers, 'Content-Length', StrSubstNo(ContentLengthLbl, 0));
                end;
            else
                RequestObject.AddHeader(Headers, 'Content-Length', StrSubstNo(ContentLengthLbl, ContentLength));
        end;
        RequestObject.AddHeader(Headers, 'x-ms-blob-type', Format(BlobType));
    end;

    local procedure HandleAuthorizationHeaders(HttpRequestType: Enum "Http Request Type"; StorageAccountName: Text; Url: Text; var Client: HttpClient; var RequestObject: Codeunit "AZBSA Request Object")
    var
        FormatHelper: Codeunit "AZBSA Format Helper";
        UsedDateTimeText: Text;
        AuthType: enum "AZBSA Authorization Type";
        Headers: HttpHeaders;
    begin
        if RequestObject.GetAuthorizationType() = AuthType::SasToken then
            exit;
        UsedDateTimeText := FormatHelper.GetRfc1123DateTime();
        Headers := Client.DefaultRequestHeaders;
        RequestObject.AddHeader(Headers, 'x-ms-date', UsedDateTimeText);
        RequestObject.AddHeader(Headers, 'x-ms-version', Format(RequestObject.GetApiVersion()));
        RequestObject.AddHeader(Headers, 'Authorization', RequestObject.GetSharedKeySignature(HttpRequestType, StorageAccountName, Url));
    end;
    // #endregion

    /// <summary>
    /// Retrieves the length of the given stream (used for "Content-Length" header in PUT-operations)
    /// </summary>
    /// <param name="SourceStream">The InStream containing the required data.</param>
    /// <returns>The length of the current stream</returns>
    local procedure GetStreamLength(var SourceStream: InStream): Integer
    var
        MemoryStream: Codeunit "MemoryStream Wrapper";
        Length: Integer;
    begin
        // Load the memory stream and get the size
        MemoryStream.Create(0);
        MemoryStream.ReadFrom(SourceStream);
        Length := MemoryStream.Length();
        MemoryStream.GetInStream(SourceStream);
        MemoryStream.SetPosition(0);
        exit(Length);
    end;

    // TODO: Create GetStreamLength(var SourceText: Text)
}