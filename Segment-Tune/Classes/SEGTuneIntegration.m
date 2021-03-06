//
//  SEGTuneIntegration.m
//  Tune Segment iOS Integration Version 1.0.0
//
//  Copyright (c) 2016 TUNE, Inc. All rights reserved.
//

#import "SEGTuneIntegration.h"
#import <Analytics/SEGAnalyticsUtils.h>

@implementation SEGTuneIntegration

- (instancetype)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        NSString *advertiserId = [settings objectForKey:@"advertiserId"];
        NSString *conversionKey = [settings objectForKey:@"conversionKey"];

        if (!advertiserId || advertiserId.length == 0) {
            @throw([NSException
                exceptionWithName:@"TUNE Error"
                           reason:[NSString stringWithFormat:@"Please add TUNE advertiser id in Segment settings."]
                         userInfo:nil]);
        }
        if (!conversionKey || conversionKey.length == 0) {
            @throw([NSException
                exceptionWithName:@"TUNE Error"
                           reason:[NSString stringWithFormat:@"Please add TUNE conversion key in Segment settings."]
                         userInfo:nil]);
        }

        [Tune initializeWithTuneAdvertiserId:advertiserId
                           tuneConversionKey:conversionKey];
        [Tune setDelegate:self];

        SEGLog(@"TUNE initialized");
    }
    return self;
}

- (void)applicationDidBecomeActive
{
    // Attribution will not function without the measureSession call included
    [Tune measureSession];
    SEGLog(@"Calling TUNE measureSession");
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    [Tune setUserId:payload.userId];
    [Tune setPhoneNumber:payload.traits[@"phone"]];
    [Tune setUserEmail:payload.traits[@"email"]];
    [Tune setUserName:payload.traits[@"username"]];
    SEGLog(@"Setting TUNE user identifiers");
}

- (void)track:(SEGTrackPayload *)payload
{
    NSString *eventName = payload.event;
    // Map Segment's "Completed Order" event to TUNE's "Purchase" event in order to record revenue
    if ([eventName isEqualToString:@"Completed Order"]) {
        eventName = TUNE_EVENT_PURCHASE;
    }
    TuneEvent *event = [TuneEvent eventWithName:eventName];
    event.revenue = [[payload.properties valueForKey:@"revenue"] doubleValue];
    event.currencyCode = payload.properties[@"currency"];
    [Tune measureEvent:event];
    SEGLog(@"Calling TUNE measureEvent with %@", eventName);
}

- (void)reset
{
    [Tune setUserId:nil];
    [Tune setPhoneNumber:nil];
    [Tune setUserEmail:nil];
    [Tune setUserName:nil];
    SEGLog(@"Clearing TUNE user identifiers");
}

- (void)tuneEnqueuedActionWithReferenceId:(NSString *)referenceId
{
    SEGLog(@"tuneEnqueuedActionWithReferenceId %@", referenceId);
}

- (void)tuneDidSucceedWithData:(NSData *)data
{
    SEGLog(@"tuneDidSucceedWithData %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)tuneDidFailWithError:(NSError *)error
{
    SEGLog(@"tuneDidFailWithError %@", error);
}

@end