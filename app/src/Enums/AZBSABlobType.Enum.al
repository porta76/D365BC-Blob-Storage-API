// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

enum 89001 "AZBSA Blob Type"
{
    Extensible = true;

    value(0; BlockBlob)
    {
    }
    value(1; PageBlob)
    {
    }
    value(2; AppendBlob)
    {
    }
}