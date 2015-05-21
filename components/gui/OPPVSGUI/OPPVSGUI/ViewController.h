//
//  ViewController.h
//  OPPVSGUI
//
//  Created by Cao Minh Trang on 3/13/15.
//  Copyright (c) 2015 Cao Minh Trang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"
#import "DrawMouseBoxView.h"
#import "FrameView.h"
#import "DropDownMenu.h"

@class Document;


@interface ViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate, DrawMouseBoxViewDelegate>
{
    NSArray *videoDevices;
    NSDictionary *windowInputs;
    
    NSString *selectedVideoDevice;
    NSString *selectedWindowInput;
    Document* document;
    
    IBOutlet NSTextField *serverPort;
    
    IBOutlet NSView *hostPreviewLayer;
    
    IBOutlet NSTableView *tableView;
    
    IBOutlet DropDownMenu *addSourceButton;
}

@property (retain) NSMutableArray *listSources;

@property (retain) NSArray *videoDevices;
@property (retain) NSDictionary *windowInputs;

@property (assign) NSString *selectedVideoDevice;
@property (assign) NSString *selectedWindowInput;

@property (retain) NSMutableArray *listCaptureSources;

@property (assign,getter=isRecording) BOOL recording;
@property (assign,getter=isStreaming) BOOL streaming;


- (IBAction)AddClick:(id)sender;
- (void) renderFrame: (oppvs::PixelBuffer*) pixelBuffer;
- (IBAction)startStreaming:(id)sender;
- (void) reset;
- (void) setRegion;
- (void) setStreamInfo: (NSString*) info;
- (IBAction) addSource:(id)sender;

@end

