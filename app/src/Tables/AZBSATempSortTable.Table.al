// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

table 89003 "AZBSA Temp. Sort Table"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Key"; Text[250])
        {
            DataClassification = CustomerContent;
        }
        field(2; Value; Text[250])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Key")
        {
            Clustered = true;
        }
    }
}