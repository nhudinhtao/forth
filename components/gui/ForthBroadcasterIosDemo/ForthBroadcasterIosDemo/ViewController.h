//
//  ViewController.h
//  ForthBroadcasterIosDemo
//
//  Created by Cao Minh Trang on 1/27/16.
//  Copyright © 2016 Cao Minh Trang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForthViewController.h"

@interface ViewController : ForthViewController
@property (strong, nonatomic) IBOutlet UIView *previewView;

@property (strong, nonatomic) IBOutlet UIButton *streamButton;
- (IBAction)startStreaming:(id)sender;

@end

