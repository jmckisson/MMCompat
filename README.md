Set of Mudlet aliases to allow creation of Triggers/Aliases etc using the MM2K syntax


MMCompat - MudMaster Compatibility

  MMCompat aims to provide command-line scriptability using the MudMaster script
  API. MudMaster commands can be entered on the Mudlet command-line and will be
  interpreted by this script and converted to Mudlet commands. Actions, Aliases,
  Events, such as /action, /alias, /event will be created as Mudlet Triggers,
  Aliases and Timers accordingly. Other commands such as /variable will create
  a variable in the global MMGlobal namespace which are used when the $ expansion
  occurs in MudMaster commands.

  ***Important Note***
  MudMaster uses a semicolon ; as a command separator, by default Mudlet uses two
  semicolons ;;. MMCompat will not function properly if you have changed your
  Mudlet command separator to a single semicolon!

##MudMaster Commands:

  Commands are prefixed by a forward-slash /.

  ###All Commands:
 action alias array assign call chat chatall chatname clearlist commands disableevent disablegroup editvariable emoteall empty enablegroup event gag highlight if itemadd itemdelete killgroup listadd listcopy listdelete listitems lists loadlibrary loop read remark resetevent seteventtime showme substitute unchat unevent unvariable variable
 while zap

##MudMaster Procedures:

  Procedures are special commands prefixed by the @ character and can be used
  in-line with Commands. Example: /chatall @AnsiReset()@ForeBlue()hello!
  will chat 'hello!' to all chat connections with the normal blue color.

  ###All Procedures:
 @A @Abs @AnsiBold @AnsiReset @AnsiRev @AnsiReverse @Arr @Asc @BackBlack @BackBlue @BackColor @BackCyan @BackGreen @BackMagenta @BackRed @BackWhite @BackYellow @Backward @Chr @Comma @ConCat @Connected @Day @DeComma @EventTime @Exists @FileExists @ForeBlack @ForeBlue @ForeColor @ForeCyan @ForeGreen @ForeMagenta @ForeRed @ForeWhite @ForeYellow @GetArray @GetArrayCols @GetArrayRows @GetCount @GetItem @Hour @IP @If @InList @IsEmpty @IsNumber @LTrim @Left @Len @Lower @Math @Mid @Minute @Month @NumActions @NumAliases @NumEvents @NumGags @NumHighlights @NumLists @NumMacros @NumVariables @PadLeft @PadRight @PreTrans @ProcedureCount @RTrim @Random @Replace @Right @Second @SessionName @SessionPath @StrStr @StrStrRev @StripAnsi @SubStr @Time @TimeToDay @TimeToDayOfWeek @TimeToHour @TimeToMinute @TimeToMonth @TimeToSecond @TimeToYear @Upper @Var @Version @Word @WordCount @Year
