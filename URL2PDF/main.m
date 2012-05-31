//
//  main.m
//  URL2PDF
//
//  Created by Scott Garner on 5/29/12.
//  Copyright (c) 2012 Project J38. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebKit/WebKit.h"
#import "PDFDownloader.h"
#include <getopt.h>

void printUsage() {
    printf("URL2PDF 6.0 (c) 2012 Scott Garner\n");
    printf("------------------------------------------------------\n");
    printf("Options:\n");
    printf("  --help                        -h      Displays this message\n");
    printf("  --url=<URL>                   -u      URL to download\n");
    printf("  --enable-javascript=<BOOL>    -j      Enable javascript, YES or NO\n");
    printf("  --print-paginate=<BOOL>       -g      Enable pagination, YES or NO\n");
    printf("  --print-backgrounds=<BOOL>    -b      Print Backgrounds, YES or NO\n");
    printf("  --load-images=<BOOL>          -i      Load Images, YES or NO\n");
    printf("  --print-orientation=<VALUE>   -o      Orientation, Portrait or Landscape\n");
    printf("  --autosave-name=<VALUE>       -n      Filename source, URL or Title\n");
    printf("  --autosave-path=<PATH>        -p      Save path\n");
    
}

NSMutableDictionary* parseOptions(const int argc, char **argv) {
    int option;
    
    if (argc == 0) {        
        printUsage();
        exit(EXIT_FAILURE);        
    }
    
    // Defaults
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       [NSNull null] , @"url",
                                       @"~/Desktop/", @"savePath",
                                       [NSNumber numberWithInt:1], @"fileNameFrom",
                                       [NSNumber numberWithInt:1], @"printOrientation",
                                       [NSNumber numberWithBool:NO], @"printPaginate",
                                       [NSNumber numberWithBool:YES], @"printBackgrounds",
                                       [NSNumber numberWithBool:YES], @"loadImages",
                                       [NSNumber numberWithBool:NO], @"enableJavaScript",
                                       nil];    
    
    
    // Option Table
    
    char *shortOptions = "hu:j:g:b:i:o:n:p:";
    const struct option longOptions[] = {
        {"help",                no_argument,        NULL,   'h'},
        {"url",                 required_argument,  NULL,   'u'},
        {"enable-javascript",   required_argument,  NULL,   'j'},
        {"print-paginate",      required_argument,  NULL,   'g'},    
        {"print-backgrounds",   required_argument,  NULL,   'b'}, 
        {"load-images",         required_argument,  NULL,   'i'},   
        {"print-orientation",   required_argument,  NULL,   'o'},
        {"autosave-name",       required_argument,  NULL,   'n'}, 
        {"autosave-path",       required_argument,  NULL,   'p'},        
        {NULL,                  0,                  NULL,   0},
    };
        
    while ((option = getopt_long(argc, argv, shortOptions, longOptions, NULL)) != -1) {
        
        
        switch(option) {
            case 'h':
                printUsage();
                exit(EXIT_SUCCESS);
                
            case 'f':
                [parameters setObject:[NSString stringWithFormat:@"%s",optarg] forKey:@"pdf"];
                break;
                
            case 'u':
                [parameters setObject:[NSString stringWithFormat:@"%s",optarg] forKey:@"url"];
                break;
                
            case 'j':
                if (strcasecmp(optarg,"YES") == 0)
                    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"enableJavaScript"];
                else if (strcasecmp(optarg,"NO") == 0)
                    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"enableJavaScript"];
                else {
                    printf("Invalid argument for --enable-javascript\n");
                    exit(EXIT_FAILURE);
                }
                break;
                
            case 'g':
                if (strcasecmp(optarg,"YES") == 0)
                    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"printPaginate"];
                else if (strcasecmp(optarg,"NO") == 0)
                    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"printPaginate"];
                else {
                    printf("Invalid argument for --print-paginate\n");
                    exit(EXIT_FAILURE);
                }
                break;    
                
            case 'i':
                if (strcasecmp(optarg,"YES") == 0)
                    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"loadImages"];
                else if (strcasecmp(optarg,"NO") == 0)
                    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"loadImages"];
                else {
                    printf("Invalid argument for --load-images\n");
                    exit(EXIT_FAILURE);
                }
                break;         
                
            case 'b':
                if (strcasecmp(optarg,"YES") == 0)
                    [parameters setObject:[NSNumber numberWithBool:YES] forKey:@"printBackgrounds"];
                else if (strcasecmp(optarg,"NO") == 0)
                    [parameters setObject:[NSNumber numberWithBool:NO] forKey:@"printBackgrounds"];
                else {
                    printf("Invalid argument for --print-backgrounds\n");
                    exit(EXIT_FAILURE);
                }
                break;       
                
            case 'o':
                if (strcasecmp(optarg,"Portrait") == 0)
                    [parameters setObject:[NSNumber numberWithInt:0] forKey:@"printOrientation"];
                else if (strcasecmp(optarg,"Landscape") == 0)
                    [parameters setObject:[NSNumber numberWithInt:1] forKey:@"printOrientation"];
                else {
                    printf("Invalid argument for --print-orientation\n");
                    exit(EXIT_FAILURE);
                }
                break; 
                
            case 'n':
                if (strcasecmp(optarg,"URL") == 0)
                    [parameters setObject:[NSNumber numberWithInt:0] forKey:@"fileNameFrom"];
                else if (strcasecmp(optarg,"Title") == 0)
                    [parameters setObject:[NSNumber numberWithInt:1] forKey:@"fileNameFrom"];
                else {
                    printf("Invalid argument for --autosave-name\n");
                    exit(EXIT_FAILURE);
                }
                break;  
                
            case 'p':
                [parameters setObject:[NSString stringWithFormat:@"%s",optarg] forKey:@"savePath"];
                break;               
                    
            default:
                printUsage();
                exit(EXIT_FAILURE);
        }
    }
    
    if ([parameters objectForKey:@"url"] == [NSNull null]) {
        printf("Missing required parameter --url\n");
        exit(EXIT_FAILURE);
    }
    
    return parameters;
}


int main(const int argc, char **argv)
{
    
    @autoreleasepool {
        
        [NSApplication sharedApplication];
        
//        NSArray *input = [[NSArray alloc] initWithObjects:
//                          [NSURL URLWithString:@"http://cargocollective.com/coryschmitz"],
//                          [NSURL URLWithString:@"http://mareodomo.com/"],
//                          [NSURL URLWithString:@"http://appleinsider.com/"],
//                          [NSURL URLWithString:@"http://bing.com/"],
//                          [NSURL URLWithString:@"http://google.com/"],
//                          [NSURL URLWithString:@"http://yahoo.com/"],
//                          nil];    
        
        NSMutableDictionary *parameters = parseOptions(argc, argv);
//        NSLog(@"%@",parameters);
                
        NSArray *input = [[NSArray alloc] initWithObjects:
                          [NSURL URLWithString:[parameters objectForKey:@"url"]],
                          nil];
        
        PDFDownloader *downloader = [[PDFDownloader alloc] init];
        
        [downloader downloadURLs:input parameters:parameters];          
        
        
    }
    return 0;
}


