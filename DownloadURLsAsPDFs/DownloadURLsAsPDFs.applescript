-- DownloadURLsAsPDFs.applescript
-- DownloadURLsAsPDFs

-- Created by Scott Garner on 5/30/12.
-- Copyright (c) 2012 Project J38. All rights reserved.

script UIController
    property parent : class "NSObject"
    
    on pushedButton_(sender)
        
        if identifier of sender as text is equal to "feedback" then
            open location "mailto:feedback@j38.net?subject=Download%20URLs%20as%20PDFs"
        end if
   
        if identifier of sender as text is equal to "website" then
            open location "http://scott.j38.net/interactive/url2pdf/"
        end if
        
        if identifier of sender as text is equal to "donate" then
            open location "http://scott.j38.net/store/"
        end if        
    
    
    end pushedButton_    
    
end script


script DownloadURLsAsPDFs
	property parent : class "AMBundleAction"
	
   
    
	on runWithInput_fromAction_error_(input, anAction, errorRef)
		-- Add your code here, returning the data to be passed to the next action.
		
        set output to {}
        
        set actionBundle to |bundle|()
        set actionParameters to my |parameters|()
                
        set commandPath to "\"" & actionBundle's pathForResource_ofType_("url2pdf", "") as text & "\""
        
        repeat with i in input
            set command to commandPath & " --url=" & (absoluteString of i)
            
            set command to command & " --autosave-path=\"" & savePath of actionParameters & "\""
            
            if (enableJavaScript of actionParameters as integer) is equal to 0 then
                set command to command & " --enable-javascript=NO"
            else
                set command to command & " --enable-javascript=YES"
            end if
        
            if fileNameFrom of actionParameters  as integer equals 0 then
                set command to command & " --autosave-name=URL"
            else
                set command to command & " --autosave-name=Title"
            end if
    
            if loadImages of actionParameters as integer equals 0 then
                set command to command & " --load-images=NO"
            else
                set command to command & " --load-images=YES"
            end if    

            if printBackgrounds of actionParameters as integer equals 0 then
                set command to command & " --print-backgrounds=NO"
            else
                set command to command & " --print-backgrounds=YES"
            end if 

            if printOrientation of actionParameters as integer equals 0 then
                set command to command & " --print-orientation=Portrait"
            else
                set command to command & " --print-orientation=Landscape"
            end if

            if printPaginate of actionParameters as integer equals 0 then
                set command to command & " --print-paginate=NO"
            else
                set command to command & " --print-paginate=YES"
            end if

            log command

            set commandResult to do shell script command
            copy commandResult to end of output
        end repeat

		return output
	end runWithInput_fromAction_error_
	
end script
