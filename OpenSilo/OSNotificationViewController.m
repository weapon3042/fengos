//
//  OSNotificationViewController.m
//  OpenSilo
//
//  Created by Peng Wan & Elmir Kouliev  on 8/19/14.
//  Copyright (c) 2014 OpenSilo Co. All rights reserved.
//

#import "OSNotificationViewController.h"
#import <Firebase/Firebase.h>
#import "OSUIMacro.h"
#import "UIImageView+AFNetworking.h"
#import "OSTranscriptTableViewCell.h"
#import "OSSession.h"
#import "OSDateTimeUtils.h"



@interface OSNotificationViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *notificationArray;

@end

@implementation OSNotificationViewController

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
    [self registerCustomCellsFromNibs];
    self.tableView.separatorColor = [UIColor lightGrayColor];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self fetchNotifications];
    });
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notificationArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSTranscriptTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OSTranscriptTableViewCell" forIndexPath:indexPath];
    
    NSDictionary *messageDict = [self.notificationArray objectAtIndex:indexPath.row];
    
    NSString *userId = messageDict[@"user_id"];
    
    NSDictionary *userInfo = [[OSSession getInstance].allUsers objectForKey:userId];
    
    cell.fullName.text = [NSString stringWithFormat:@"%@ %@", userInfo[@"first_name"], userInfo[@"last_name"]];
    
    NSString *messageTimestamp = messageDict[@"timestamp"];
    NSString *timeDetails = [[OSDateTimeUtils getInstance] convertDateTimeFromUTCtoLocalForDateTime:[messageTimestamp longLongValue]];
    NSArray *foo = [timeDetails componentsSeparatedByString: @"/"];
    NSString *time = [foo objectAtIndex: 0];
    
    cell.messageTime.text = time;
    cell.message.text = messageDict[@"text"];
    
    NSURL *url = [NSURL URLWithString:userInfo[@"picture"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    UIImage *placeholderImage = [UIImage imageNamed:@"imgPlaceholder"];
    
    [cell.thumbProgressView startAnimating];
    
    [cell.pic setImageWithURLRequest:request
                    placeholderImage:placeholderImage
                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                 cell.pic.image = image;
                                 [cell.thumbProgressView stopAnimating];
                             } failure:^(NSURLRequest *request,
                                         NSHTTPURLResponse *response, NSError *error) {
                                 [cell.thumbProgressView stopAnimating];
                             }];
    
    cell.thumbProgressView.hidesWhenStopped=YES;
    
    Firebase *fb = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/presence/%@",fireBaseUrl,userInfo[@"user_id"]]];
    
    //online/offline/idle/away/busy
    cell.status.backgroundColor = USER_AWAY;
    [fb authWithCredential:fireBaseSecret withCompletionBlock:^(NSError* error, id authData) {
        [fb observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            //NSLog(@"status:%@", snapshot.value);
            if ([snapshot.value isEqualToString:@"online"]) {
                //                NSLog(@"userId:%@", userInfo[@"user_id"]);
                cell.status.backgroundColor = USER_ONLINE;
            }
            if ([snapshot.value isEqualToString:@"busy"]) {
                cell.status.backgroundColor = USER_BUSY;
            }
        }];
    } withCancelBlock:^(NSError* error) {
        NSLog(@"error:%@",error);
    }];
    
    return cell;
}

-(void)registerCustomCellsFromNibs
{
    [self.tableView registerNib:[UINib nibWithNibName:@"OSTranscriptTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"OSTranscriptTableViewCell"];
}

-(void)fetchNotifications{
    NSString *userId = [OSSession getInstance].user.userId;
    Firebase *firebase = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/notifications/%@",fireBaseUrl,userId]];
    self.notificationArray = [[NSMutableArray alloc] init];
    [firebase authWithCredential:fireBaseSecret withCompletionBlock:^(NSError* error, id authData) {
        [firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            [self.notificationArray addObject:snapshot.value];
            [self.tableView reloadData];
        }];
    } withCancelBlock:^(NSError* error) {
        NSLog(@"error:%@",error);
    }];
}

@end
