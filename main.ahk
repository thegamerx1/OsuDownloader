#include <mustExec>
debug.init()

global progConfig := new configLoader("settings.json")
loginGui.init()
return

#Include gui.ahk
#Include <EzGui>
#Include <urlCode>
#Include <configLoader>
#Include <debug>
#Include <fileDownloader>
#Include <timer>
#Include <requests>