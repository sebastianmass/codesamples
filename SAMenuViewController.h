//
//  SAMenuViewController.h
//  SprintApplication
//
//  Created by Seva Kukhelny on 12.02.14.
//  Copyright (c) 2014 Instinkt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface SAMenuViewController : UIViewController <SKProductsRequestDelegate,SKPaymentTransactionObserver>

@end
