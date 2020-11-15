// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 89000 "AZBSA Blob Storage Operation"
{
    Extensible = true;

    value(0; ListContainers)
    {
        Caption = 'List Containers';
    }
    value(1; ListContainerContents)
    {
        Caption = 'List Container Contents';
    }
    value(2; PutContainer)
    {
        Caption = 'Create Container';
    }
    value(10; GetBlob)
    {
        Caption = 'Get Blob';
    }
    value(11; PutBlob)
    {
        Caption = 'Upload Blob';
    }
    value(12; DeleteBlob)
    {
        Caption = 'Delete Blob';
    }
}