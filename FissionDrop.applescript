
property type_list : {"JPEG", "TIFF", "PNGf", "8BPS", "BMPf", "GIFf", "PDF ", "PICT"}
property extension_list : {"jpg", "jpeg", "tif", "tiff", "png", "psd", "bmp", "gif", "jp2", "pdf", "pict", "pct", "sgi", "tga"}
property typeIDs_list : {"public.jpeg", "public.tiff", "public.png", "com.adobe.photoshop-image", "com.microsoft.bmp", "com.compuserve.gif", "public.jpeg-2000", "com.adobe.pdf", "com.apple.pict", "com.sgi.sgi-image", "com.truevision.tga-image"}

property theFolder : false

on run
	checkTheFolder()
	display alert "You're all set! Drop images on this app icon and they'll be uploaded to Fission!"
end run

-- This droplet processes files dropped onto the applet
on open theItems
	checkTheFolder()
	set filename to false
	repeat with anItem in theItems
		if (isValidItem(anItem)) then
			-- move it to the destination folder
			tell application "Finder"
				set filename to name of anItem
				move anItem to theFolder
			end tell
		else
			display alert "The file " & (name of anItem) & " is not supported." as warning
		end if
	end repeat
	
	try
		publishToFission(filename)
	on error errMsg
		display alert "💥  " & errMsg
	end try
end open

-- this sub-routine processes files
on publishToFission(filename)
	set progress total steps to 2
	set progress completed steps to 0
	set progress description to "Publishing to Fission"
	set progress additional description to "Preparing to process."
	delay (1)
	
	set progress additional description to "🔗 Registering Fission app"
	tell application "Finder"
		-- convert theFolder (alias) to a POSIX path
		set thePath to quoted form of POSIX path of theFolder
		
		-- check if the fission.yaml file has been created
		set fissionConfig to POSIX path of theFolder & "fission.yaml"
		
		if not (exists fissionConfig as POSIX file) then
			-- register a new app
			set registration to do shell script "cd " & thePath & "; echo '.' | /usr/local/bin/fission app register"
		end if
	end tell
	
	set progress completed steps to 1
	set progress additional description to "🚀 Publishing files"
		delay (1)

	
	set publishCmd to "cd " & thePath & "; /usr/local/bin/fission app publish"
	do shell script publishCmd
	
	set progress completed steps to 2
	set progress additional description to "🎉 Finished publishing!"
	
	if not (filename is false) then
		set fissionUrl to do shell script "grep url " & fissionConfig & "| awk '{ print $2 }'"
		set fileUrl to "https://" & fissionUrl & "/" & filename
		
		
		set the clipboard to fileUrl
		display alert "📋 Finished! The file URL is on your clipboard."
	end if
end publishToFission

-- check that theFolder is set, if not prompt user
on checkTheFolder()
	tell application "Finder"
		if (theFolder is false) or not (folder theFolder exists) then
			set theFolder to choose folder with prompt "Please select an output folder:"
		end if
	end tell
end checkTheFolder

on isValidItem(the_item)
	set the item_info to info for the_item
	set this_name to the name of the item_info
	try
		set this_extension to the name extension of item_info
	on error
		set this_extension to ""
	end try
	try
		set this_filetype to the file type of item_info
	on error
		set this_filetype to ""
	end try
	try
		set this_typeID to the type identifier of item_info
	on error
		set this_typeID to ""
	end try
	if (folder of the item_info is false) and (alias of the item_info is false) and ((this_filetype is in the type_list) or (this_extension is in the extension_list) or (this_typeID is in typeIDs_list)) then
		return true
	else
		return false
	end if
end isValidItem