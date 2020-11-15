// ------------------------------------------------------------------------------------------------
// Copyright (c) Simon "SimonOfHH" Fischer. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

page 89002 "AZBSA Container"
{

    ApplicationArea = All;
    Caption = 'Container';
    PageType = List;
    SourceTable = "AZBSA Container";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field("Last-Modified"; Rec."Last-Modified")
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field(DefaultEntryptionScope; Rec.DefaultEncryptionScope)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field(DenyEncryptionScopeOverride; Rec.DenyEncryptionScopeOverride)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field(HasImmutabilityPolicy; Rec.HasImmutabilityPolicy)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field(HasLegalHold; Rec.HasLegalHold)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field(LeaseState; Rec.LeaseState)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
                field(LeaseStatus; Rec.LeaseStatus)
                {
                    ApplicationArea = All;
                    ToolTip = 'xxx';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action(ShowEntryDetails)
            {
                Caption = 'Show Entry Details';
                Image = ViewDetails;
                ApplicationArea = All;
                // Promoted = true;
                // PromotedIsBig = true;
                // ApplicationArea = All;
                ToolTip = 'xxx';

                trigger OnAction()
                var
                    InStr: InStream;
                    OuterXml: Text;
                begin
                    if not Rec."XML Value".HasValue then
                        exit;

                    Rec.CalcFields("XML Value");
                    Rec."XML Value".CreateInStream(InStr);
                    InStr.Read(OuterXml);
                    Message(OuterXml);
                end;
            }
        }
    }

}
