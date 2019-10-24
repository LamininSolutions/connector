"use strict";


// We need some json builder funcs:
var JSON = JSON || {};

// implement JSON.stringify serialization
JSON.stringify = JSON.stringify || function (obj) {

    var t = typeof (obj);
    if (t != "object" || obj === null) {

        // simple data type
        if (t == "string") obj = '"' + obj + '"';
        return String(obj);

    }
    else {

        // recurse array or object
        var n, v, json = [], arr = (obj && obj.constructor == Array);

        for (n in obj) {
            v = obj[n]; t = typeof (v);

            if (t == "string") v = '"' + v + '"';
            else if (t == "object" && v !== null) v = JSON.stringify(v);

            json.push((arr ? "" : '"' + n + '":') + String(v));
        }

        return (arr ? "[" : "{") + String(json) + (arr ? "]" : "}");
    }
};

function OnNewShellUI(shellUI) {
	/// <summary>The entry point of ShellUI module.</summary>
	/// <param name="shellUI" type="MFiles.ShellUI">The new shell UI object.</param>

	// Register to listen new shell frame creation event.
    //shellUI.Events.Register(Event_NewShellFrame, newShellFrameHandler);
    
    shellUI.Events.Register(Event_NewNormalShellFrame, newShellFrameHandler);
    //var Vaul = shellUI.Vault;
   
}

function newShellFrameHandler(shellFrame) {
	/// <summary>Handles the OnNewShellFrame event.</summary>
	/// <param name="shellFrame" type="MFiles.ShellFrame">The new shell frame object.</param>

    // Register to listen the started event.
 
    shellFrame.Events.Register(Event_Started, getShellFrameStartedHandler(shellFrame));
    
}

function getShellFrameStartedHandler(shellFrame) {
  
//	debugger;
	/// <summary>Gets a function to handle the Started event for shell frame.</summary>
	/// <param name="shellFrame" type="MFiles.ShellFrame">The current shell frame object.</param>
	/// <returns type="MFiles.Events.OnStarted">The event handler.</returns>

	// Return the handler function for Started event.
    return function ()
    {
		// Shell frame object is now started.

		// Create some commands.
		//	var commandShow1 = shellFrame.Commands.CreateCustomCommand( "Show Message #1" );
	    var commandShow2 = shellFrame.Commands.CreateCustomCommand("MFSQL Connector");
	    var commandShow1 = shellFrame.Commands.CreateCustomCommand("MFSQL Connector");
	    var shellUIForPrompts = shellFrame.ShellUI;

	    if (shellFrame.ShellUI.Vault.ClientOperations.IsOffline() == 0) { //Added for the to resolve vault offline Error.
	        var Output=shellFrame.ShellUI.Vault.ExtensionMethodOperations.ExecuteVaultExtensionMethod("CheckUserContextMenuAccess", "");
	        var OutArray=Output.split('|');

	        if (OutArray[0] == "1")
	        {
	            //var homeTab = shellFrame.RightPane.AddTab("_home", MFiles.GetStringResource(27664), "_last");  // The string id 27664 is allocated from the resource-id space, which is mainly used through enumeration from localization.js. This is an exception.
	            var homeTab = shellFrame.RightPane.AddTab("_Menu", "MFSQL Connector", "_last");

	            // shellUIForPrompts.ShowMessage("Working");
	            //
	            // Set command icons.
	            //	shellFrame.Commands.SetIconFromPath( commandShow1, "png/tennis_ball.ico" );
	            shellFrame.Commands.SetIconFromPath(commandShow2, "png/LS-favicon-green.ico");

	        // Add a command to the context menu in right click task pane.
	        shellFrame.Commands.AddCustomCommandToMenu(commandShow1, MenuLocation_ContextMenu_Bottom, 0);

	        // Add a commands to the task pane.
	        //		shellFrame.TaskPane.AddCustomCommandToGroup( commandShow1, TaskPaneGroup_Main, -101 );
	        shellFrame.TaskPane.AddCustomCommandToGroup(commandShow2, TaskPaneGroup_Main, -100);

	        // Hold a reference to the selected items and update as selection changes.
	        var currentItems = null;
	        shellFrame.Events.OnNewShellListing = function (listing) {
	            return {
	                OnSelectionChanged: function (items) {
	                    currentItems = items.ObjectVersions;
	                }
	            }
	        }


	        // Set the command handler function.
	        shellFrame.Commands.Events.Register(Event_CustomCommand, function (command) {



	            // Branch by command.
	            if (command == commandShow2) {
	                //Commented Following line of code for Task #1058
	                //shellFrame.ShowPopupDashboard("popup_message", true,{ caption: "MFSQL Connector" });

                    //Added following lines of code for task #1058
	                homeTab.ShowDashboard("popup_message", {caption: "MFSQL Connector1"});
	                homeTab.Visible = true;
	                homeTab.Select();
	                
	            }
	            else {
	                var selectedItems = currentItems || shellFrame.Listing.CurrentSelection.ObjectVersions;
	                //var data = [];
	                //for (var i = 1; i <= selectedItems.Count; i++) {
	                //    var item = selectedItems.Item(i).ObjVer;
	                //    data.push({
	                //        ID: item.ID,
	                //        Type: item.Type,
	                //        Version: item.Version
	                //    });
	                //}
	                //data = JSON.stringify(data);
	                var data = "";
	                for (var i = 1; i <= selectedItems.Count; i++) {
	                    var item = selectedItems.Item(i).ObjVer;
	                    data = item.ID + "|" + item.Type + "|" + item.Version;   // where item.ID=objectID of m-files ,item.type=objecttype of m-files and item.version=object version of m-files

	                }

	                // Debug.
	                //shellUIForPrompts.ShowMessage("Input was: " + data);
	                // shellUIForPrompts.ShowMessage();
	                //Added following lines of code for task #1058
	                homeTab.ShowDashboard("popup_message", {caption: data});
	                homeTab.Visible = true;
	                homeTab.Select();

	                //Commented Following line of code for Task #1058
	                //shellFrame.ShowPopupDashboard("popup_message", true,  { caption: data });

	                }
	        });
	        if(OutArray.length>1)
	        {
	            shellUIForPrompts.ShowMessage(OutArray[1]);
	        }
	        }
	        else
	        {
	            //  shellUIForPrompts.ShowMessage(shellFrame.ShellUI.Vault.ExtensionMethodOperations.ExecuteVaultExtensionMethod("CheckUserContextMenuAccess", ""));
	        }
	    }
	};
}