//
//  bleuuid.h
//  ImmPeri - Immediate Alert Peripheral Sample
//
//  Created by youten on 2014/01/06.
//  Copyright (c) 2014年 sample. All rights reserved.
//

#ifndef bleuuid_h
#define bleuuid_h

// 180A Device Information
static NSString * SERVICE_DEVICE_INFORMATION = @"0000180a-0000-1000-8000-00805f9b34fb";
static NSString * CHAR_MANUFACTURER_NAME_STRING = @"00002a29-0000-1000-8000-00805f9b34fb";
static NSString * CHAR_MODEL_NUMBER_STRING = @"00002a24-0000-1000-8000-00805f9b34fb";
static NSString * CHAR_SERIAL_NUMBEAR_STRING = @"00002a25-0000-1000-8000-00805f9b34fb";

// 1802 Immediate Alert
static NSString * SERVICE_IMMEDIATE_ALERT = @"00001802-0000-1000-8000-00805f9b34fb";
static NSString * CHAR_ALERT_LEVEL = @"00002a06-0000-1000-8000-00805f9b34fb";
// StickNFindではCHAR_ALERT_LEVELに0x01をWriteすると光り、0x02では音が鳴り、0x03では光って鳴る。

#endif
