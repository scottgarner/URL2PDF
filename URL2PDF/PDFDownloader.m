//
//  PDFDownloader.m
//  DownloadPDF
//
//  Created by Scott Garner on 5/23/12.
//  Copyright (c) 2012 Project J38. All rights reserved.
//

#import "PDFDownloader.h"

@implementation PDFDownloader

@synthesize loadComplete;
@synthesize pageTitle;


- (id)downloadURLs:(id)input parameters: (NSMutableDictionary *) parameters
{
    
    // Retrieve Parameters                                
    
    NSString *savePath = [ parameters objectForKey:@"savePath"];
    int fileNameFrom = [[ parameters objectForKey:@"fileNameFrom"] intValue];
    
    int printOrientation = [[ parameters objectForKey:@"printOrientation"] intValue];
    BOOL printPaginate = [[ parameters objectForKey:@"printPaginate"] boolValue];
    BOOL printBackgrounds = [[ parameters objectForKey:@"printBackgrounds"] boolValue];	
    
    BOOL loadImages = [[ parameters objectForKey:@"loadImages"] boolValue];	
    BOOL enableJavaScript = [[ parameters objectForKey:@"enableJavaScript"] boolValue];	                                       
    
    // Paper Size
    
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    NSSize pageSize = [printInfo paperSize];
    
	int printWidth;
	int printHeight;
	switch (printOrientation) {
		case 0:
			printWidth = pageSize.width;
			printHeight = pageSize.height;
			break;
		case 1:
			printWidth = pageSize.height;
			printHeight = pageSize.width;
			break;
	}	
    
    // Webview
    
    NSRect frame = NSMakeRect(0.0, 0.0, printWidth, printHeight);
    
    WebView *webView = [[WebView alloc] initWithFrame:frame];
    [webView setMaintainsBackForwardList:NO];	
    [webView setFrameLoadDelegate:self];
    [webView setResourceLoadDelegate:self];
    
    // Window
    
    NSWindow * window = [[NSWindow alloc]  
                         initWithContentRect:NSMakeRect(0,0,printWidth,printHeight)                         
                         styleMask:NSBorderlessWindowMask                         
                         backing:NSBackingStoreNonretained defer:NO];
    [window setContentView:webView];    
    
    // Static Prefernces
    
    [[webView preferences] setAllowsAnimatedImages:NO];	
    [[webView preferences] setAllowsAnimatedImageLooping:NO];
    [[webView preferences] setPlugInsEnabled:NO];
    [[webView preferences] setJavaEnabled:NO];	
    [[webView preferences] setJavaScriptCanOpenWindowsAutomatically:NO];
    
    // Optional preferences
    
    [[webView preferences] setJavaScriptEnabled:enableJavaScript];
	[[webView preferences] setShouldPrintBackgrounds:printBackgrounds];
	[[webView preferences] setLoadsImagesAutomatically:loadImages];	        
    
	// Process each URL
    
    NSMutableArray *output = [NSMutableArray arrayWithCapacity:[input count]];
    NSEnumerator *enumerate = [input objectEnumerator];
    NSURL *curURL;	
	
	while (curURL = [enumerate nextObject]) {
        
        //NSLog(@"Downloading URL: %@", [curURL absoluteString]);
        
        // Send Requests
        
        bool isRunning;
		[self setPageTitle:nil];
		[self setLoadComplete:NO];  
        
        [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:curURL 
                                                          cachePolicy:NSURLRequestUseProtocolCachePolicy 
                                                      timeoutInterval:5]];    
        
        // Loop while waiting for responses.
        
        NSDate* next = [NSDate dateWithTimeIntervalSinceNow:1.0]; 
        do {
            isRunning = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:next];
        } while (![self loadComplete]);
        
        [[webView mainFrame] stopLoading];
        
        // Filename Fuss
        
        NSString *saveFilePath = [self getFileNameAt:savePath from:fileNameFrom forURL:curURL];
        
        // Print It
        
        [self printWebView:webView fileName:saveFilePath paginate:printPaginate orientation:printOrientation];    
        
		[output addObject:saveFilePath];
        
	}
    
	return (output);    
}

#pragma mark Filename Handling

- (NSString *)getFileNameAt:(NSString *)savePath from:(int)fileNameFrom forURL:(NSURL *) url
{
    savePath = [savePath stringByExpandingTildeInPath];
    
    if ([self pageTitle] == nil)
        [self setPageTitle:@"Untitled"];
    
    NSString *saveFile;
    NSString *saveFilePath;		
    
    // Set filename source
    
    switch (fileNameFrom) {
        case 0:
            if ([[url path] length] > 1)
                saveFile = [[[[url path] lastPathComponent] stringByDeletingPathExtension]
                            stringByAppendingPathExtension:@"pdf"];
            else
                saveFile = [[url host] stringByAppendingPathExtension:@"pdf"];
            break;
        case 1:
            // No forward slashes are allowed in file names, so we replace them with a colon.
            saveFile = [[[[self pageTitle] componentsSeparatedByString:@"/"] componentsJoinedByString:@":"] stringByAppendingPathExtension:@"pdf"];
            break;
    }	
    
    saveFilePath = [savePath stringByAppendingPathComponent:saveFile];	
    
    // Don't overwrite existing files.
    
    int renameCounter=1;		
    while ([[NSFileManager defaultManager] fileExistsAtPath:saveFilePath]) {
        saveFilePath = [savePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%i.%@",[saveFile stringByDeletingPathExtension],renameCounter++,[saveFile pathExtension]]];
    }     
    
    // Return safe path
    
    return saveFilePath;
}

- (void)printWebView:(WebView *) webView fileName:(NSString *)filename paginate:(BOOL)printPaginate orientation:(int)printOrientation;
{
	// Get Print View...
	NSView *printView = [[[webView mainFrame] frameView] documentView];
    
    [[[webView mainFrame] frameView] setAllowsScrolling:NO];
    
    if (printPaginate) {
		// To paginate we have to fake a print
		
		NSMutableDictionary *printInfoDict;
		printInfoDict = [NSMutableDictionary dictionaryWithDictionary:[[NSPrintInfo sharedPrintInfo] dictionary]];
		[printInfoDict setObject:filename forKey:NSPrintSavePath];		
		
		NSPrintInfo *printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
		[printInfo setHorizontallyCentered:NO];
		[printInfo setVerticallyCentered:NO];
		[printInfo setJobDisposition:NSPrintSaveJob];		
		
		// Handle margins
        
		NSRect imageableBounds = [printInfo imageablePageBounds];
		NSSize paperSize = [printInfo paperSize];
		if (NSWidth(imageableBounds) > paperSize.width) {
			imageableBounds.origin.x = 0;
			imageableBounds.size.width = paperSize.width;
		}
		if (NSHeight(imageableBounds) > paperSize.height) {
			imageableBounds.origin.y = 0;
			imageableBounds.size.height = paperSize.height;
		}
        
		[printInfo setBottomMargin:NSMinY(imageableBounds)];
		[printInfo setTopMargin:paperSize.height - NSMinY(imageableBounds) - NSHeight(imageableBounds)];
		[printInfo setLeftMargin:NSMinX(imageableBounds)];
		[printInfo setRightMargin:paperSize.width - NSMinX(imageableBounds) - NSWidth(imageableBounds)];
        
		// Set orientation
		
		switch (printOrientation) {
			case 0:
				[printInfo setOrientation:NSPortraitOrientation];
				break;
			case 1:
				[printInfo setOrientation:NSLandscapeOrientation];
				break;
		}			
        
		// Create print operation
		
		NSPrintOperation *printOp;
		printOp = [NSPrintOperation printOperationWithView:printView printInfo:printInfo];
		[printOp setShowsPrintPanel:NO];
		[printOp setShowsProgressPanel:NO];
		[printOp runOperation];
		        
    } else {
        // No pagination
        
        NSRect printRect = [printView frame];
        NSData *printData = [printView dataWithPDFInsideRect:printRect];
        [printData writeToFile:filename atomically:YES];    
    }
    
    printf("%s", [filename UTF8String]);
    
}

#pragma mark Webview Delegates

- (void)webView:(WebView*)sender didStartProvisionalLoadForFrame:(WebFrame*)frame
{	
    if ([sender mainFrame] == frame) {
		//NSLog(@"didStartProvisionalLoadForFrame");
    }
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    printf("Failed to load URL\n");
    exit(EXIT_FAILURE);    
    
}

- (void)webView:(WebView*)sender didCommitLoadForFrame:(WebFrame*)frame
{	
	if ([sender mainFrame] == frame) {
		//NSLog(@"didCommitLoadForFrame");
	}
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
    
	if ([sender mainFrame] == frame) {
		[self setPageTitle:title];
	}
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame
{
	if ([sender mainFrame] == frame) {
		[self setLoadComplete:YES];
	}
}

@end
