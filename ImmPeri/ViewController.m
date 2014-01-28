//
//  ViewController.m
//  ImmPeri
//
//  Created by youten on 2014/01/23.
//  Copyright (c) 2014年 sample. All rights reserved.
//

#import "ViewController.h"
#include "bleuuid.h"

static NSString * START_ADVERTISING = @"Start Advertising";
static NSString * STOP_ADVERTISING = @"Stop Advertising";

@interface ViewController ()

@end

@implementation ViewController {
    CBPeripheralManager *_peripheralManager;
    CBMutableService *_deviceInformationService;
    CBMutableService *_immediateAlertService;
    CBMutableCharacteristic *_manufacturerNameChar;
    CBMutableCharacteristic *_serialNumberChar;
    CBMutableCharacteristic *_alertLevelChar;
    BOOL _advertising;
    
    UIAlertView *_editManufacturerName;
    AVSpeechSynthesizer *_speechSynthesizer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _advertising = NO;
    _startStopButtonItem.title = START_ADVERTISING;
    
    // init Speech Synthesizer
    _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)onClickEditButton:(id)sender {
    if (_advertising) {
        [[self simpleAlertWithTitle:@"Alert"
                            message:@"Edit Manufacturer Name after stop Advertising."] show];
    } else {
        // show edit alert
        _editManufacturerName = [[UIAlertView alloc]
                                 initWithTitle:@"Manufacturer Name"
                                 message:nil
                                 delegate:self
                                 cancelButtonTitle:@"Cancel"
                                 otherButtonTitles:@"OK", nil];
        [_editManufacturerName setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [[_editManufacturerName textFieldAtIndex:0] setText:_manufacturerNameLabel.text];
        [_editManufacturerName show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == _editManufacturerName) {
        if (buttonIndex == 1) { // OK
            _manufacturerNameLabel.text = [[alertView textFieldAtIndex:0] text];
        }
    }
}

- (IBAction)onStartStopButtonItem:(id)sender {
    // start/stop Advertising
    [self startStopAdvertising];
}

- (void)speech:(NSString *)text {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.rate = 0.3f;
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"ja-JP"];
    [_speechSynthesizer speakUtterance:utterance];
}

#pragma mark BLE advertising

// Start/Stop Advertising Button
- (void)startStopAdvertising {
    if (_advertising) {
        [self speech:@"アドバタイズを停止します。"];
        if (_peripheralManager.isAdvertising) {
            [_peripheralManager stopAdvertising];
        }
        _advertising = NO;
        _startStopButtonItem.title = START_ADVERTISING;
    } else {
        if (!_peripheralManager) {
            [self initService];
        }
        [_peripheralManager
         startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:
                                @[_deviceInformationService.UUID, _immediateAlertService.UUID],
                            CBAdvertisementDataLocalNameKey:@"ImmPeri"}];
    }
}

// Advertise が開始されるとコールされる
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral
                                       error:(NSError *)error
{
    LOG_METHOD;
    
    if (error) {
        // show error alert
        [[self simpleAlertWithTitle:[error localizedDescription]
                            message:[error localizedFailureReason]] show];
        
        [self speech:@"エラー、アドバタイズが開始できませんでした。"];
        _advertising = NO;
        _startStopButtonItem.title = START_ADVERTISING;
    } else {
        [self speech:@"アドバタイズが開始されました。"];
        _advertising = YES;
        _startStopButtonItem.title = STOP_ADVERTISING;
    }
}

// Bluetoothの状態が変更されるとコールされる
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    LOG_METHOD;
    
    switch (peripheral.state) {
        case CBPeripheralManagerStatePoweredOff:
            LOG(@"not ready");
            break;
        case CBPeripheralManagerStatePoweredOn:
            LOG(@"ready");
            break;
        default:
            break;
    }
}


#pragma mark BLE service and characteristic

- (void)initService {
    // init Peripheral Manager
    if (!_peripheralManager) {
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    
    // init BLE Characteristic Manufacturer Name
    _manufacturerNameChar = [[CBMutableCharacteristic alloc]
               initWithType:[CBUUID UUIDWithString:CHAR_MANUFACTURER_NAME_STRING]
               properties:CBCharacteristicPropertyRead
               value:nil
               permissions:CBAttributePermissionsReadable];
    
    // init BLE CHaracteristic Serial Number
    _serialNumberChar = [[CBMutableCharacteristic alloc]
                         initWithType:[CBUUID UUIDWithString:CHAR_SERIAL_NUMBEAR_STRING]
                         properties:CBCharacteristicPropertyRead
                         value:nil
                         permissions:CBAttributePermissionsReadable];

    // init BLE Device Information Service
    _deviceInformationService = [[CBMutableService alloc]
                                 initWithType:[CBUUID UUIDWithString:SERVICE_DEVICE_INFORMATION]
                                 primary:YES];
    _deviceInformationService.characteristics = @[_manufacturerNameChar, _serialNumberChar];

    // init BLE Characteristic for Alert Level
    _alertLevelChar = [[CBMutableCharacteristic alloc]
                initWithType:[CBUUID UUIDWithString:CHAR_ALERT_LEVEL]
                properties:CBCharacteristicPropertyWrite
                value:nil
                permissions:CBAttributePermissionsWriteable];
    
    // init BLE Immediate Alert Service
    _immediateAlertService = [[CBMutableService alloc]
                initWithType:[CBUUID UUIDWithString:SERVICE_IMMEDIATE_ALERT]
                primary:YES];
    _immediateAlertService.characteristics = @[_alertLevelChar];
    
    @try {
        [_peripheralManager addService:_deviceInformationService];
        [_peripheralManager addService:_immediateAlertService];
    }
    @catch (NSException *exception) {
        LOG(@"Peripheral addService Error name=%@, reason=%@", exception.name, exception.reason);
        _peripheralManager = nil;
    }
    @finally {
    }
}

#pragma mark ReadRequest

- (void)peripheralManager:(CBPeripheralManager *)peripheral
    didReceiveReadRequest:(CBATTRequest *)request
{
    LOG_METHOD;
    
    // UUIDをチェックして値を返す
    if ([request.characteristic.UUID isEqual:_manufacturerNameChar.UUID]) {
        request.value = [_manufacturerNameLabel.text dataUsingEncoding:NSUTF8StringEncoding];
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        return;
    }
    if ([request.characteristic.UUID isEqual:_serialNumberChar.UUID]) {
        request.value = [@"DummySerial" dataUsingEncoding:NSUTF8StringEncoding];
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        return;
    }
    
    // それ以外はNotFoundを返す
    [_peripheralManager respondToRequest:request withResult:CBATTErrorAttributeNotFound];
}

#pragma mark WriteRequest

- (void)peripheralManager:(CBPeripheralManager *)peripheral
  didReceiveWriteRequests:(NSArray *)requests
{
    LOG_METHOD;
    
    for (CBATTRequest *request in requests) {
        if ([request.characteristic.UUID isEqual:_alertLevelChar.UUID]) {
            NSString *stringValue = [self toHex:request.value];
            LOG(@"written:%@", stringValue);
            [self speech:[NSString stringWithFormat:@"%@が書き込まれました。", stringValue]];
            _alertLevelLabel.text = stringValue;
            [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
        } else {
            [_peripheralManager respondToRequest:request withResult:CBATTErrorAttributeNotFound];
        }
    }
}

#pragma mark util

- (UIAlertView *) simpleAlertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:title
                          message:message
                          delegate:self
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    return alert;
}

- (NSString *) toHex:(NSData *) data
{
    NSMutableString *str = [NSMutableString stringWithCapacity:64];
    NSInteger length = [data length];
    char *bytes = malloc(sizeof(char) * length);
    
    [data getBytes:bytes length:length];
    
    for (int i = 0; i < length; i++)
    {
        [str appendFormat:@"%02.2hhx", bytes[i]];
    }
    free(bytes);
    
    return str;
}

- (NSData *) toDataFromHex:(NSString *) hex
{
    NSString *trim = [hex stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    NSMutableData *data= [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i = 0; i < [trim length] / 2; i++) {
        byte_chars[0] = [trim characterAtIndex:i * 2];
        byte_chars[1] = [trim characterAtIndex:i * 2 + 1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    
    return [data copy];
}

@end
