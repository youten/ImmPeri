//
//  ViewController.h
//  ImmPeri
//
//  Created by youten on 2014/01/23.
//  Copyright (c) 2014年 sample. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController <UIAlertViewDelegate, CBPeripheralManagerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *manufacturerNameLabel;

@property (strong, nonatomic) IBOutlet UIButton *editButton;
- (IBAction)onClickEditButton:(id)sender;

@property (strong, nonatomic) IBOutlet UILabel *alertLevelLabel;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *startStopButtonItem;
- (IBAction)onStartStopButtonItem:(id)sender;


@end
