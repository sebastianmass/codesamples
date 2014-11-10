//
//  FNGameCenterManager.h
//  FontNerd
//
//  Created by Seva Kukhelny on 12.11.13.
//  Copyright (c) 2013 Instinkt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "SynthesizeSingleton.h"

@interface FNGameCenterManager : NSObject

+ (FNGameCenterManager *)sharedFNGameCenterManager;

- (void)authLocalPlayerFromView:(UIViewController *)showViewController;
- (void)reportScore:(int)score forLevel:(int)level;



- (void)finishedLevel:(int)level withStars:(int)stars askedForHelp:(BOOL)askedForHelp time:(int)time answeredWithoutOptions:(BOOL)answeredWithoutOptions;

- (void)shareWithUsersNotGuessed;
- (void)shareWithUsersGuessed;
- (void)shareWithMyFonts;

- (void)favoriteMaster;
- (void)likeComicSans;

- (void)comicSansWrongAnswer;

- (void)paparazzi;

- (void)missArialAndHelvetica;

- (void)soClose;

- (void)buyApp;

- (void)slowPoke;

@end
