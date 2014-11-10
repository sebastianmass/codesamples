//
//  SAMenuViewController.m
//  SprintApplication
//
//  Created by Seva Kukhelny on 12.02.14.
//  Copyright (c) 2014 Instinkt. All rights reserved.
//
#define IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

#import "SAMenuViewController.h"
#import "SAScreenManager.h"
#import "SAConnectionManager.h"
#import "SADeviceView.h"
#import "SASearchDeviceView.h"
#import "MBProgressHUD.h"

#import <MultipeerConnectivity/MultipeerConnectivity.h>

#import "SAAppDelegate.h"

@interface SAMenuViewController ()
@property (nonatomic, weak) IBOutlet UILabel *hostLabel;
@property (nonatomic, weak) IBOutlet UIScrollView *devicesScrollView;
@property (nonatomic, weak) IBOutlet UIImageView *animationView;
@property (nonatomic, weak) IBOutlet UIButton *deviceButton;
@property (nonatomic, weak) IBOutlet UILabel *majorButtonLabel;
@property (nonatomic, weak) IBOutlet UILabel *minorButtonLabel;
@property (nonatomic, weak) IBOutlet UIButton *restorePurchasesButton;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, strong) NSMutableArray *devicesView;
@property (nonatomic, strong) UIViewController *helpVC;
@end

@implementation SAMenuViewController
@synthesize hostLabel;
@synthesize devicesScrollView;
@synthesize devicesView;
@synthesize lastContentOffset;
@synthesize animationView;
@synthesize currentPage;
@synthesize helpVC;
@synthesize deviceButton;
@synthesize majorButtonLabel;
@synthesize minorButtonLabel;
@synthesize restorePurchasesButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFoundNewPeer) name:@"NewPeerFounded" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didLostPeer) name:@"PeerLost" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getInvited) name:@"GetInvited" object:nil];

    self.view.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0];
    
    [self.hostLabel setText:[[UIDevice currentDevice] name]];
    
    self.devicesView = [[NSMutableArray alloc] init];
    
    [self composeDevicesView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [SAConnectionManager sharedInstance].isClientServer = NO;
   // [[SAConnectionManager sharedInstance] disconnectPeer];
    [SAConnectionManager sharedInstance].isHost = NO;

    [SAConnectionManager sharedInstance].lostPeer = nil;
    
    [[SAConnectionManager sharedInstance] makeConnectionAvailable];
    
    [self didFoundNewPeer];
    
    SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.firstTimestamp = 0;
    [SAConnectionManager sharedInstance].dif = 0;
    [SAConnectionManager sharedInstance].commandCount = 1;
    [SAConnectionManager sharedInstance].lastCommand = 0;
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[SAConnectionManager sharedInstance] makeConnectionUnavailable];
    
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)singleDeviceButtonPressed:(id)sender
{
    if (self.currentPage == ([self.devicesView count] - 1))
    {
        [[SAScreenManager sharedInstance] moveToScreen:@"ReadyForRunVC"];
    }
    else
    {
        SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;

        if (appDelegate.isPurchased)
        {
            [SAConnectionManager sharedInstance].isHost = YES;
            MCPeerID *peer = [[SAConnectionManager sharedInstance].peers objectAtIndex:self.currentPage];
            [[SAConnectionManager sharedInstance] makeConnectWithPeer:peer];
            
            [[SAScreenManager sharedInstance] moveToScreen:@"SyncVC"];
        }
        else
        {
            if ([SKPaymentQueue canMakePayments])
            {
                SKProductsRequest *request= [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:@"multidevice"]];
                request.delegate = self;
                [request start];
                
                [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:@"Please ask your mom or dad if you can play Font Nerd"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didFoundNewPeer
{
    [self composeDevicesView];
}

- (void)didLostPeer
{
    [self composeDevicesView];
}

- (void)getInvited
{
    [[SAScreenManager sharedInstance] moveToScreen:@"SyncVC"];
}

#pragma mark - Scroll view methods

- (void)composeDevicesView
{
    self.currentPage = 0;
    
    [self.devicesScrollView setContentSize:CGSizeZero];
    
    for (UIView *view in [self.devicesScrollView subviews])
    {
        [view removeFromSuperview];
    }
    
    [self.devicesView removeAllObjects];
    
    int cellsCount;
    
    if ([[SAConnectionManager sharedInstance].peers count])
    {
        cellsCount = [[SAConnectionManager sharedInstance].peers count] + 1;
        [self makeButtonAvailable:YES];
        
        SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;

        if (appDelegate.isPurchased)
        {
            [self makeButtonRegular];
        }
        else
        {
            [self makeButtonInApp];
        }
    }
    else
    {
        cellsCount = 2;
        
        [self makeButtonRegular];
    }
    
    [self.devicesScrollView setContentSize:CGSizeMake(self.devicesScrollView.frame.size.width, self.devicesScrollView.frame.size.height * cellsCount)];
        
    for (int i = 0; i < cellsCount; i++)
    {
        if (![[SAConnectionManager sharedInstance].peers count] && i == 0)
        {
            SASearchDeviceView *deviceView = [[[NSBundle mainBundle] loadNibNamed:@"SearchDeviceView" owner:self options:nil] objectAtIndex:0];
            
            [deviceView setFrame:CGRectMake(0, self.devicesScrollView.frame.size.height * i, self.devicesScrollView.frame.size.width, self.devicesScrollView.frame.size.height)];
            
            [self.devicesScrollView addSubview:deviceView];
            
            UIImageView *imgView = (UIImageView *)[deviceView viewWithTag:3];
            
            NSMutableArray *animationFramesArray = [[NSMutableArray alloc] init];
            
            for (int i = 0; i < 8; i++)
            {
                [animationFramesArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"loading-icon-%d",i+1]]];
            }
            
            imgView.animationImages = animationFramesArray;
            
            imgView.animationDuration = 1;
            
            [imgView startAnimating];

            
            [self.devicesView addObject:deviceView];
            
            [self makeButtonAvailable:NO];
        
            continue;
        }
        
        SADeviceView *deviceView = [[[NSBundle mainBundle] loadNibNamed:@"DeviceView" owner:self options:nil] objectAtIndex:0];
        
        [deviceView setFrame:CGRectMake(0, self.devicesScrollView.frame.size.height * i, self.devicesScrollView.frame.size.width, self.devicesScrollView.frame.size.height)];
        
        [self.devicesScrollView addSubview:deviceView];
        
        [self.devicesView addObject:deviceView];
        
        if (i == cellsCount - 1)
        {
            [deviceView.textLabel setText:@"No B device"];
            deviceView.textLabel.alpha = 0.3f;
            [deviceView.deviceImageView setImage:[UIImage imageNamed:@"phone-none"]];
            deviceView.deviceImageView.alpha = 0.3f;
        }
        else if (i != 0)
        {
            [deviceView goDownNotAnimated];
            MCPeerID *peer = [[SAConnectionManager sharedInstance].peers objectAtIndex:i];
            [deviceView.textLabel setText:peer.displayName];
            
            SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;

            if (!appDelegate.isPurchased)
            {
                [deviceView.deviceImageView setImage:[UIImage imageNamed:@"phone-locked"]];
            }
        }
        else
        {
            MCPeerID *peer = [[SAConnectionManager sharedInstance].peers objectAtIndex:i];
            [deviceView.textLabel setText:peer.displayName];
            
            SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;

            if (!appDelegate.isPurchased)
            {
                [deviceView.deviceImageView setImage:[UIImage imageNamed:@"phone-locked"]];
            }
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
    ScrollDirection scrollDirection;
    if (self.lastContentOffset > self.devicesScrollView.contentOffset.x)
        scrollDirection = ScrollDirectionRight;
    else if (self.lastContentOffset < self.devicesScrollView.contentOffset.x)
        scrollDirection = ScrollDirectionLeft;
    
    self.lastContentOffset = self.devicesScrollView.contentOffset.x;
    
    static NSInteger previousPage = 0;
    
    CGFloat pageWidth = self.devicesScrollView.frame.size.height;
    float fractionalPage = self.devicesScrollView.contentOffset.y / pageWidth;
    NSInteger page = lround(fractionalPage);
    
    if (previousPage != page)
    {
        self.currentPage = page;
        
        if (![[SAConnectionManager sharedInstance].peers count] && page == 0)
        {
            [self makeButtonAvailable:NO];
        }
        else
        {
            [self makeButtonAvailable:YES];
        }
        
        if (previousPage == ([self.devicesView count] - 1) && page == ([self.devicesView count] - 2))
        {
            [self runAnimationReversed:NO];
            
            SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            
            if ([[SAConnectionManager sharedInstance].peers count] && !appDelegate.isPurchased)
            {
                [self makeButtonInApp];
            }
        }
        else if (previousPage == ([self.devicesView count] - 2) && page == ([self.devicesView count] - 1))
        {
            [self runAnimationReversed:YES];
            [self makeButtonRegular];
        }
        
        if (page >= [self.devicesView count])
        {
            return;
        }

        SADeviceView *deviceView = [self.devicesView objectAtIndex:previousPage];

        if (previousPage < page)
        {
            [deviceView goUp];
        }
        else
        {
            [deviceView goDown];
        }
        
        SADeviceView *newDeviceView = [self.devicesView objectAtIndex:page];
        
        if (page == ([self.devicesView count] - 1))
        {
            [newDeviceView goMiddleWithoutAlpha];
        }
        else
        {
            [newDeviceView goMiddle];
        }
        previousPage = page;
    }
}

- (void)runAnimationReversed:(BOOL)reversed
{
    NSMutableArray *animationFramesArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < 15; i++)
    {
        [animationFramesArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"arrow-animation-%d",i+1]]];
    }

    self.animationView.animationImages = animationFramesArray;
    
    [self.animationView setImage:[UIImage imageNamed:@"arrow-animation-15"]];

    if (reversed)
    {
        NSArray *reversedArray = [[animationFramesArray reverseObjectEnumerator] allObjects];
        
        self.animationView.animationImages = reversedArray;
        
        [self.animationView setImage:[UIImage imageNamed:@"arrow-animation-1"]];
    }
    
    self.animationView.animationDuration = 0.495;
    self.animationView.animationRepeatCount = 1;
    
    [self.animationView startAnimating];
}

- (void)makeButtonAvailable:(BOOL)available
{
    self.deviceButton.enabled = available;
    
    __weak __typeof(&*self)weakSelf = self;
    
    if (!available)
    {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            strongSelf.majorButtonLabel.alpha = 0.3f;
            strongSelf.minorButtonLabel.alpha = 0.3f;
            
        } completion:NULL];
    }
    else
    {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            __strong __typeof(&*weakSelf)strongSelf = weakSelf;
            strongSelf.majorButtonLabel.alpha = 1.0f;
            strongSelf.minorButtonLabel.alpha = 1.0f;
            
        } completion:NULL];
    }
}

- (void)makeButtonInApp
{
    [self.majorButtonLabel setText:@"Unlock A to B sprinting"];
    
    NSMutableString *buyText = [NSMutableString stringWithString:@"Click here to unlock multidevice"];
    
    SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    if (appDelegate.inAppPrice)
    {
        [buyText appendFormat:@" for %@", appDelegate.inAppPrice];
    }
    
    [self.minorButtonLabel setText:buyText];
    
    [self.restorePurchasesButton setHidden:NO];
}

- (void)makeButtonRegular
{
    [self.majorButtonLabel setText:@"Is this the setup you want?"];
    [self.minorButtonLabel setText:@"Press here to get started"];
    [self.restorePurchasesButton setHidden:YES];
}

- (IBAction)helpButtonPressed:(id)sender
{
    SAAppDelegate *appDelegate = (SAAppDelegate *)[UIApplication sharedApplication].delegate;
    
    self.helpVC = [appDelegate.storyboard instantiateViewControllerWithIdentifier:@"HelpVC"];
    
    [self.view addSubview:self.helpVC.view];
}

- (IBAction)restoreButtonPressed:(id)sender
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

#pragma mark - In-app purchases methods

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *myProduct = response.products;
    
    SKPayment *newPayment = [SKPayment paymentWithProduct:[myProduct objectAtIndex:0]];
    
    [[SKPaymentQueue defaultQueue] addPayment:newPayment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"We're having some trouble reaching Apples servers. Please try again in a moment."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    appDelegate.isPurchased = YES;

    [self makeButtonRegular];
    
    [self composeDevicesView];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    SAAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    appDelegate.isPurchased = YES;
    
    [self makeButtonRegular];
    
    [self composeDevicesView];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"We're having some trouble reaching Apples servers. Please try again in a moment."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

@end
