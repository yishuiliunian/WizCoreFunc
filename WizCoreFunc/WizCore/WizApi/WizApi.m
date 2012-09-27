//
//  WizApi.m
//  WizCore
//
//  Created by wiz on 12-8-1.
//  Copyright (c) 2012年 cn.wiz. All rights reserved.
//

#import "WizApi.h"
#import "WizSyncErrorCenter.h"
#import "WizSyncDataCenter.h"

@implementation WizApi
@synthesize apiDelegate;
@synthesize statue = _statue;
@synthesize connection;
@synthesize kbGuid;
@synthesize accountUserId;
- (void) dealloc
{
    apiDelegate = nil;
    [connection release];
    [accountUserId release];
    [kbGuid release];
    [super dealloc];
}
- (id) init
{
    self = [super init];
    if (self) {
        attemptTime = WizApiAttemptTimeMax;
    }
    return self;
}

- (BOOL) start
{
    if (attemptTime <= 0) {
        _statue = WizApistatueError;
        [self end];
        return NO;
    }
    _statue = WizApiStatueBusy;
    return YES;
}

- (void) reduceAttempTime
{
    attemptTime--;
}

- (void) onError:(NSError *)error
{
    _statue = WizApistatueError;
    WizSyncErrorCenter* errorCenter = [WizSyncErrorCenter shareInstance];
    [errorCenter willSolveWizApi:self onError:error];
}

- (void) cancel
{
    if (self.connection) {
        [self.connection cancel];
    }
    self.connection = nil;
}

- (void) end
{
    switch (self.statue) {
        case WizApiStatueBusy:
            [self.apiDelegate wizApiEnd:self withSatue:WizApiStatueNormal];
            break;
        case WizApistatueError:
            [self.apiDelegate wizApiEnd:self withSatue:WizApistatueError];
        default:
            [self.apiDelegate wizApiEnd:self withSatue:WizApiStatueNormal];
            break;
    }
    _statue = WizApiStatueNormal;
}

-(void) addCommonParams: (NSMutableDictionary*)postParams
{
	[postParams setObject:@"iphone" forKey:@"client_type"];
	[postParams setObject:@"normal" forKey:@"program_type"];
    [postParams setObject:[NSNumber numberWithInt:4] forKey:@"api_version"];
	//
    NSString* token = [[WizSyncDataCenter shareInstance] tokenForKbguid:self.kbGuid];
	if (token != nil)
	{
		[postParams setObject:token forKey:@"token"];
	}
	if (kbGuid != nil)
	{
		[postParams setObject:kbGuid forKey:@"kb_guid"];
	}
}
-(BOOL)executeXmlRpcWithArgs:(NSMutableDictionary*)postParams  methodKey:(NSString*)methodKey
{
    NSURL* apiUrl = [[WizSyncDataCenter shareInstance] apiUrlForKbguid:self.kbGuid];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithHost:apiUrl];
	if (!request)
    {
		return NO;
    }
    [self addCommonParams:postParams];
    NSArray* args = [NSArray arrayWithObject:postParams];
	//
	[request setMethod:methodKey withObjects:args];
	//
	self.connection = [XMLRPCConnection sendAsynchronousXMLRPCRequest:request delegate:self];
	//
	[request release];
	//
    if(nil != self.connection)
        return YES;
    else
        return NO;
}

- (void)xmlrpcDone: (XMLRPCConnection *)connection isSucceeded: (BOOL)succeeded retObject: (id)ret forMethod: (NSString *)method
{
    if (succeeded) {
        [self xmlrpcDoneSucced:ret forMethod:method];
    }
    else
    {
        [self onError:ret];
    }
    self.connection = nil;
}

- (id<WizMetaDataBaseDelegate>)groupDataBase
{
    return [[WizDbManager shareInstance] getMetaDataBaseForAccount:self.accountUserId kbGuid:self.kbGuid];
}

- (NSInteger) listCount
{
    return 39;
}

- (void) changeStatue:(enum WizApiStatue)statue
{
    _statue = statue;
}
@end