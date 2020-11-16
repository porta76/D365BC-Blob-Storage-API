// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 89000 "AZBSA Blob Storage Connection"
{
    Caption = 'Blob Storage Connection';
    DataClassification = CustomerContent;
    LookupPageId = "AZBSA Blob Stor. Connections";
    DrillDownPageId = "AZBSA Blob Stor. Connections";

    fields
    {
        field(1; "Code"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
        }

        field(2; Description; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(3; "Storage Account Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Storage Account Name';
        }

        field(4; "Authorization Type"; Enum "AZBSA Authorization Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Authorization Type';
        }
        field(5; Secret; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Secret';
            ExtendedDatatype = Masked;

            trigger OnValidate()
            begin
                if Rec."Authorization Type" = Rec."Authorization Type"::SasToken then
                    if Rec."Secret".StartsWith('?') then
                        Rec."Secret" := CopyStr(Rec."Secret", 2, 250);
            end;
        }

        field(6; "API Version"; Enum "AZBSA API Version")
        {
            DataClassification = CustomerContent;
            Caption = 'API Version';
        }

        field(10; "Source Container Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Source Container Name';
        }
        field(11; "Target Container Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Target Container Name';
        }
    }

    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

    procedure TestSetup(ForDestination: Boolean)
    begin
        Rec.TestField("Storage Account Name");
        Rec.TestField("Secret");
        Rec.TestField("Storage Account Name");
        if ForDestination then
            Rec.TestField("Target Container Name")
        else
            Rec.TestField("Source Container Name");
    end;

    procedure ListContainers()
    var
        API: Codeunit "AZBSA Blob Storage API";
        RequestObject: Codeunit "AZBSA Request Object";
    begin
        RequestObject.InitializeAuthorization(Rec."Authorization Type", Rec.Secret);
        RequestObject.InitializeRequest(Rec."Storage Account Name");
        API.ListContainers(RequestObject);
    end;

    procedure ListContentSource()
    begin
        ListContentContainer(Rec."Source Container Name");
    end;

    procedure ListContentTarget()
    begin
        ListContentContainer(Rec."Target Container Name");
    end;

    local procedure ListContentContainer(ContainerName: Text)
    var
        API: Codeunit "AZBSA Blob Storage API";
        RequestObject: Codeunit "AZBSA Request Object";
    begin
        RequestObject.InitializeAuthorization(Rec."Authorization Type", Rec.Secret);
        RequestObject.InitializeRequest(Rec."Storage Account Name", ContainerName);
        API.ListBlobs(RequestObject);
    end;

    procedure CreateSourceContainer()
    begin
        CreateContainer(Rec."Source Container Name");
    end;

    procedure CreateTargetContainer()
    begin
        CreateContainer(Rec."Target Container Name");
    end;

    local procedure CreateContainer(ContainerName: Text)
    var
        API: Codeunit "AZBSA Blob Storage API";
        RequestObject: Codeunit "AZBSA Request Object";
    begin
        RequestObject.InitializeAuthorization(Rec."Authorization Type", Rec.Secret);
        RequestObject.InitializeRequest(Rec."Storage Account Name", ContainerName);
        API.CreateContainer(RequestObject);
    end;

    procedure DeleteSourceContainer()
    begin
        DeleteContainer(Rec."Source Container Name");
    end;

    procedure DeleteTargetContainer()
    begin
        DeleteContainer(Rec."Target Container Name");
    end;

    local procedure DeleteContainer(ContainerName: Text)
    var
        API: Codeunit "AZBSA Blob Storage API";
        RequestObject: Codeunit "AZBSA Request Object";
    begin
        RequestObject.InitializeAuthorization(Rec."Authorization Type", Rec.Secret);
        RequestObject.InitializeRequest(Rec."Storage Account Name", ContainerName);
    end;

    procedure UploadFileUI(ContainerName: Text)
    var
        API: Codeunit "AZBSA Blob Storage API";
        RequestObject: Codeunit "AZBSA Request Object";
    begin
        RequestObject.InitializeAuthorization(Rec."Authorization Type", Rec.Secret);
        RequestObject.InitializeRequest(Rec."Storage Account Name", ContainerName);
        API.UploadBlobIntoContainerUI(RequestObject);
    end;

    procedure DownloadFileUI(ContainerName: Text)
    var
        API: Codeunit "AZBSA Blob Storage API";
        RequestObject: Codeunit "AZBSA Request Object";
    begin
        RequestObject.InitializeAuthorization(Rec."Authorization Type", Rec.Secret);
        RequestObject.InitializeRequest(Rec."Storage Account Name", ContainerName);
        API.DownloadBlobAsFileWithSelect(RequestObject);
    end;
}