//
//  JHServerCollaborator.h
//  Jesperhus
//
//  Created by Seva Kukhelnyy on 09.02.13.
//  Copyright (c) 2013 Sovergaard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"
#import "CustomerReservationsProxy.h"
#import "ActivitiesServiceProxy.h"

typedef enum { kFinishCodeOK = 0, kNoUserFoundError, kGetReservationInfoFromServerError, kNoActivitiesFound, kNoInternetConnection} kFinishCode;

typedef void (^FinishLoginBlock)(NSDictionary *,kFinishCode);
typedef void (^FinishActivitiesBlock)(NSArray *,kFinishCode);
typedef void (^FinishYoutubeVideosBlock)(NSArray *,kFinishCode);

@interface JHServerCollaborator : NSObject <Wsdl2CodeProxyDelegate>

+(JHServerCollaborator *)sharedJHServerCollaborator;

-(void)makeLoginWithLogin:(NSString *)login andPass:(NSString *)password finishBlock:(void (^) (NSDictionary *loginResults,kFinishCode finishCode))block;
-(void)getActivitiesForDate:(NSDate *)activitiesDate finishBlock:(void (^) (NSArray *results,kFinishCode finishCode))block;
-(void)getYoutubeVideosForKey:(NSString *)key finishBlock:(void (^) (NSArray *results,kFinishCode finishCode))block;
-(void)getBackgroundUpdateWithAuthtoken:(NSString *)authtoken finishBlock:(void (^) (NSDictionary *loginResults,kFinishCode finishCode))block;
@end
