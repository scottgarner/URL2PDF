//
//  PDFDownloader.h
//  DownloadPDF
//
//  Created by Scott Garner on 5/23/12.
//  Copyright (c) 2012 Project J38. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebKit/WebKit.h"

@interface PDFDownloader : NSObject {
@private
    BOOL loadComplete;
    NSString *pageTitle;
}

@property (nonatomic,readwrite) BOOL loadComplete;
@property (nonatomic,readwrite, copy) NSString *pageTitle;

- (id)downloadURLs:(id)input parameters: (NSMutableDictionary *) parameters;

@end

