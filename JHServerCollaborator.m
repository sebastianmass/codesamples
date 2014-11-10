//
//  JHServerCollaborator.m
//  Jesperhus
//
//  Created by Seva Kukhelnyy on 09.02.13.
//  Copyright (c) 2013 Sovergaard. All rights reserved.
//

#import "JHServerCollaborator.h"
#import "AFNetworking.h"
#import <Parse/Parse.h>
#import "JHYoutubeVideo.h"
#import "JHUserInfo.h"
#import "NSDate-Utilities.h"
#import <XMLDictionary.h>

@interface JHServerCollaborator()
@property (nonatomic,strong) FinishLoginBlock finishLoginBlock;
@property (nonatomic,strong) FinishActivitiesBlock finishActivitiesBlock;
@property (nonatomic,strong) FinishYoutubeVideosBlock finishYoutubeVideosBlock;
@property (nonatomic,strong) CustomerReservationsProxy *customerProxy;
@property (nonatomic,strong) ActivitiesServiceProxy *activitiesProxy;
@end

@implementation JHServerCollaborator
@synthesize finishLoginBlock;
@synthesize customerProxy;
@synthesize activitiesProxy;
@synthesize finishActivitiesBlock;
@synthesize finishYoutubeVideosBlock;

SYNTHESIZE_SINGLETON_FOR_CLASS(JHServerCollaborator);

- (id)init
{
    self = [super init];
    
    if (self)
    {
        customerProxy = [[CustomerReservationsProxy alloc] initWithUrl:@"xxx" AndDelegate:self];
        activitiesProxy = [[ActivitiesServiceProxy alloc] initWithUrl:@"xxx" AndDelegate:self];
    }
    return self;
}

- (void)makeLoginWithLogin:(NSString *)login andPass:(NSString *)password finishBlock:(void (^) (NSDictionary *loginResults,kFinishCode finishCode))block
{
    self.finishLoginBlock = block;
    
    if ([login isEqualToString:@"xxx"])
    {
        [self processAccessTokenResponse:@{@"username":login, @"password":password}];
    }
    else
    {
        [self.customerProxy GetAuth:login:password];
    }
}

-(void)getActivitiesForDate:(NSDate *)activitiesDate finishBlock:(void (^) (NSArray *results,kFinishCode finishCode))block
{
    self.finishActivitiesBlock = block;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    NSString *strFromDate = [dateFormatter stringFromDate:activitiesDate];
    [self.activitiesProxy GetActivities:strFromDate:strFromDate:0:@"da-DK"];
}

-(void)getYoutubeVideosForKey:(NSString *)key finishBlock:(void (^) (NSArray *results,kFinishCode finishCode))block
{
    self.finishYoutubeVideosBlock = block;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://gdata.youtube.com/feeds/api/playlists/%@?max-results=50",key]]];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    __weak __typeof(&*self)weakSelf = self;
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        [strongSelf loadYouTubeVideosFromResponse:responseObject];
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        __strong __typeof(&*weakSelf)strongSelf = weakSelf;
        strongSelf.finishYoutubeVideosBlock(nil,kNoInternetConnection);
    }];
    
    [[NSOperationQueue mainQueue] addOperation:op];
}

- (void)loadYouTubeVideosFromResponse:(NSData *)responseObject
{
    NSMutableArray *videosArray = [NSMutableArray array];
    
    NSDictionary *dict = [NSDictionary dictionaryWithXMLData:responseObject];
    
    NSArray *videos = [dict objectForKey:@"entry"];
    
    for (int i = 0; i < [videos count]; i++)
    {
        NSDictionary *tempDict = [videos objectAtIndex:i];
        JHYoutubeVideo *video = [[JHYoutubeVideo alloc] init];
        video.title = [[tempDict objectForKey:@"title"] objectForKey:@"__text"];
        video.urlToVideo = [[[tempDict objectForKey:@"media:group"] objectForKey:@"media:player"] objectForKey:@"_url"];
        video.urlToThumbnail = [[[[tempDict objectForKey:@"media:group"] objectForKey:@"media:thumbnail"] objectAtIndex:0] objectForKey:@"_url"];
        
        [videosArray addObject:video];
    }
    
    NSArray *resultArray = [[NSArray alloc] initWithArray:videosArray];
    
    self.finishYoutubeVideosBlock(resultArray,kFinishCodeOK);
}

- (void)getFamilyInfoWithToken:(NSString *)token
{
    if (token == nil)
    {
        self.finishLoginBlock(nil,kNoUserFoundError);
        return;
    }
    
    [PFCloud callFunctionInBackground:@"GetAccessTokenResponse" withParameters:@{@"authToken":token} block:^(id object, NSError *error)
    {
        if (error)
        {
            self.finishLoginBlock(nil,kGetReservationInfoFromServerError);
            return;
        }
        else
        {
            [self processAccessTokenResponse:object];
        }
    }];
}

- (void)processAccessTokenResponse:(id)object
{
    [PFUser logInWithUsernameInBackground:object[@"username"] password:object[@"password"] block:^(PFUser *user, NSError *error)
     {
         if (user)
         {
             [PFCloud callFunctionInBackground:@"UpdateInstallations" withParameters:@{@"installationID":[PFInstallation currentInstallation].installationId} block:^(id object, NSError *error)
              {
                  if (error)
                  {
                      self.finishLoginBlock(nil,kNoInternetConnection);
                      return;
                  }
                  else
                  {
                      if (user[@"children"])
                      {
                          [JHUserInfo sharedJHUserInfo].children = user[@"children"];
                      }
                      else
                      {
                          [JHUserInfo sharedJHUserInfo].children = [NSArray array];
                      }
                      
                      [JHUserInfo sharedJHUserInfo].address = user[@"address"];
                      [JHUserInfo sharedJHUserInfo].children = user[@"children"];
                      [JHUserInfo sharedJHUserInfo].homeCoordinate = CLLocationCoordinate2DMake([[[user objectForKey:@"homeCoordinate"] valueForKey:@"latitude"] doubleValue], [[[user objectForKey:@"homeCoordinate"] valueForKey:@"longitude"] doubleValue]);
                      [JHUserInfo sharedJHUserInfo].lastName = user[@"surname"];
                      [JHUserInfo sharedJHUserInfo].promoCode = user[@"promoCode"];
                      [JHUserInfo sharedJHUserInfo].referenceCodeValue = user[@"promoCodeValue"];
                      [JHUserInfo sharedJHUserInfo].stayCount = user[@"stayCount"];
                      [JHUserInfo sharedJHUserInfo].typeOfHome = user[@"typeOfHome"];
                      
                      [JHUserInfo sharedJHUserInfo].arrivalDate = user[@"arrivalDate"];
                      [JHUserInfo sharedJHUserInfo].departureDate = user[@"departureDate"];
                      
                      [JHUserInfo sharedJHUserInfo].isLogged = YES;
                      
                      self.finishLoginBlock(nil, kFinishCodeOK);
                  }
              }];
         }
         else
         {
             self.finishLoginBlock(nil,kNoInternetConnection);
             return;
         }
     }];
}

-(void)getBackgroundUpdateWithAuthtoken:(NSString *)authtoken finishBlock:(void (^) (NSDictionary *loginResults,kFinishCode finishCode))block
{
    self.finishLoginBlock = block;
    [self getFamilyInfoWithToken:authtoken];
}

#pragma Proxy delegate methods

- (void)proxydidFinishLoadingData:(id)data InMethod:(NSString*)method
{
    if ([method isEqualToString:@"GetActivities"])
    {
        if ([data count] > 0) {
            self.finishActivitiesBlock(data,kFinishCodeOK);
        }
        else
        {
            self.finishActivitiesBlock(nil,kNoActivitiesFound);
        }
        return;
    }
    
    if ([method isEqualToString:@"GetAuth"])
    {
        AuthenticationStatus *status = data;
        if (status.status == 0 )
        {
            self.finishLoginBlock(nil,kNoUserFoundError);
        }
        else
        {
            [JHUserInfo sharedJHUserInfo].authToken = status.authToken;
            [self getFamilyInfoWithToken:status.authToken];
        }
    }
    else
    {
        NSLog(@"Unknown error occured while getting server login data");
    }
}

- (void)proxyRecievedError:(NSException*)ex InMethod:(NSString*)method
{
    if ([method isEqualToString:@"GetActivities"]) {
        self.finishActivitiesBlock(nil,kNoInternetConnection);
    }
    else if ([method isEqualToString:@"GetAuth"])
    {
        self.finishLoginBlock(nil,kNoInternetConnection);
    }
}

@end
