//
//  FNGameCenterManager.m
//  FontNerd
//
//  Created by Seva Kukhelny on 12.11.13.
//  Copyright (c) 2013 Instinkt. All rights reserved.
//

#import "FNGameCenterManager.h"

#import "FNAppDelegate.h"

@interface FNGameCenterManager ()
@property (nonatomic, strong) NSArray *achievementsArray;
@end

@implementation FNGameCenterManager
@synthesize achievementsArray;


SYNTHESIZE_SINGLETON_FOR_CLASS(FNGameCenterManager);

- (void)authLocalPlayerFromView:(UIViewController *)showViewController;
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error)
    {
        __weak UIViewController *weakVC = showViewController;

        if (viewController != nil)
        {
            [weakVC presentViewController:viewController animated:YES completion:^{
                
            }];
        }
    };
}

- (void)reportScore:(int)score forLevel:(int)level
{
    NSString *category = [NSString stringWithFormat:@"level%d",level + 1];
    
    GKScore *scoreReporter = [[GKScore alloc] initWithCategory:category];
    scoreReporter.value = score;
    scoreReporter.context = 0;

    [scoreReporter reportScoreWithCompletionHandler:^(NSError *error)
    {
        GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
        
        if (leaderboardRequest != nil)
        {
            leaderboardRequest.playerScope = GKLeaderboardPlayerScopeGlobal;
            leaderboardRequest.timeScope = GKLeaderboardTimeScopeAllTime;
            leaderboardRequest.category = category;
            leaderboardRequest.range = NSMakeRange(1,100);
            
            [leaderboardRequest loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error)
            {
                if (scores != nil)
                {
                    for (int i = 0; i < [scores count]; i++)
                    {
                        GKScore *scoreTemp = [scores objectAtIndex:i];
                        
                        if (i <= 99 && ((int)scoreTemp.value < score))
                        {
                            [self reportAchievementIdentifier:@"top100"];
                        }
                        
                        if (i <= 9 && ((int)scoreTemp.value < score))
                        {
                            [self reportAchievementIdentifier:@"top10er"];
                        }
                        
                        if (i == 0 && ((int)scoreTemp.value < score))
                        {
                            [self reportAchievementIdentifier:@"theFontNerd"];
                        }
                    }
                }
            }];
        }
    }];
}

- (void)reportAchievementIdentifier:(NSString*)identifier
{
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
    {
        __weak FNGameCenterManager *weakSelf = self;
        
        for (GKAchievement *ach in achievements)
        {
            if([ach.identifier isEqualToString:identifier])
            {
                NSLog(@"Already submitted");
                return;
            }
        }
        
        if ([weakSelf.achievementsArray count] == 0)
        {
            [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error)
             {
                 weakSelf.achievementsArray = descriptions;
                 
                 for (GKAchievementDescription *descr in descriptions)
                 {
                     if ([descr.identifier isEqualToString:identifier])
                     {
                         [weakSelf reportAchievementWithIdentifier:identifier name:descr.title description:descr.achievedDescription];
                     }
                 }
             }];
        }
        else
        {
            for (GKAchievementDescription *descr in weakSelf.achievementsArray)
            {
                if ([descr.identifier isEqualToString:identifier])
                {
                    [weakSelf reportAchievementWithIdentifier:identifier name:descr.title description:descr.achievedDescription];
                }
            }
        }
    }];
}

- (void)reportAchievementWithIdentifier:(NSString *)ident name:(NSString *)name description:(NSString *)description
{
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier:ident];
    achievement.percentComplete = 100.0f;

    [GKAchievement reportAchievements:[NSArray arrayWithObject:achievement] withCompletionHandler:^(NSError *error)
     {
         if (error == nil)
         {
             [GKNotificationBanner showBannerWithTitle:name message:description completionHandler:nil];
         }
     }];
}

- (void)finishedLevel:(int)level withStars:(int)stars askedForHelp:(BOOL)askedForHelp time:(int)time answeredWithoutOptions:(BOOL)answeredWithoutOptions
{
    NSString *completeLevelArchievement = [NSString stringWithFormat:@"completeLevel%d", level +1];
    
    [self reportAchievementIdentifier:completeLevelArchievement];
        
    if (stars == 5)
    {
        NSString *fiveStarsArchievement = [NSString stringWithFormat:@"perfectedLevel%d", level +1];
        [self reportAchievementIdentifier:fiveStarsArchievement];
    }
    
    FNAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    if ([appDelegate currentStarsScore] >=15)
    {
        [self reportAchievementIdentifier:@"15Stars"];
    }
    
    if ([appDelegate currentStarsScore] ==25)
    {
        [self reportAchievementIdentifier:@"25Stars"];
        
        FNAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        [appDelegate becomeFontNerd];
    }
    
    if (stars >= 3 && askedForHelp == NO)
    {
        [self reportAchievementIdentifier:@"iveGotThis"];
    }
    
    if (stars >= 3 && answeredWithoutOptions == NO)
    {
        [self reportAchievementIdentifier:@"helpMePlease"];
    }
    
    if (stars >= 3 && time <= 25)
    {
        [self reportAchievementIdentifier:@"speedy"];
    }
    
    if (stars >= 4 && time <= 45)
    {
        [self reportAchievementIdentifier:@"typophile"];
    }
    
    if (stars == 5 && time <= 45)
    {
        [self reportAchievementIdentifier:@"fontNerdPro"];
    }
    
    if (stars == 0)
    {
        [self reportAchievementIdentifier:@"fontNoob"];
    }
}

- (void)shareWithUsersNotGuessed
{
    [self reportAchievementIdentifier:@"iSuckAndIAdmitIt"];
}

- (void)shareWithUsersGuessed
{
    [self reportAchievementIdentifier:@"showEm"];
}

- (void)shareWithMyFonts
{
    [self reportAchievementIdentifier:@"youLikeItThatMuch"];
}

- (void)favoriteMaster
{
    [self reportAchievementIdentifier:@"collector"];
}

- (void)likeComicSans
{
    [self reportAchievementIdentifier:@"youGotAbsolutelyNoComicSense"];
}

- (void)comicSansWrongAnswer
{
    [self reportAchievementIdentifier:@"youGotNoComicSense"];
}

- (void)buyApp
{
    [self reportAchievementIdentifier:@"barista"];
}

- (void)paparazzi
{
    [self reportAchievementIdentifier:@"paparazzi"];
}

- (void)missArialAndHelvetica
{
    [self reportAchievementIdentifier:@"sirMisalot"];
}

- (void)soClose
{
    [self reportAchievementIdentifier:@"soClose"];
}

- (void)slowPoke
{
    [self reportAchievementIdentifier:@"slowpoke"];
}

@end
