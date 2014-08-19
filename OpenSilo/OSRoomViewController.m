//
//  OSRoomViewController.m
//  OpenSilo
//
//  Created by Peng Wan & Elmir Kouliev  on 8/2/14.
//  Copyright (c) 2014 OpenSilo Co. All rights reserved.
//

#import "OSRoomViewController.h"
#import "OSUserUtils.h"
#import "OSSession.h"
#import "OSWebServiceMacro.h"
#import "OSMacro.h"
#import "OSUIMacro.h"
#import "OSConstant.h"
#import "METransitions.h"
#import "OSTranscriptTableViewCell.h"
#import "OSDateTimeUtils.h"
#import "UIImageView+AFNetworking.h"
#import "OSRequestUtils.h"

@interface OSRoomViewController ()

@property (nonatomic, strong) METransitions *transitions;
@property (nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation OSRoomViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[OSUserUtils getInstance] reloadAllUsers];
    });
    
    [super viewWillAppear:animated];
    
    self.array = [[NSMutableArray alloc] init];
    
    // Initialize the root of our Firebase namespace.
    // Initialize the root of our Firebase namespace.
    NSString *roomId = [OSSession getInstance].currentRoom.fireBaseId ? [OSSession getInstance].currentRoom.fireBaseId : DEFAULT_ROOM_ID;
    NSString *url = [NSString stringWithFormat:@"%@resolutionrooms/%@/messages",fireBaseUrl,roomId];
    self.firebase = [[Firebase alloc] initWithUrl:url];
    _dict = [[NSMutableDictionary alloc]init];
    [self.firebase authWithCredential:fireBaseSecret withCompletionBlock:^(NSError* error, id authData) {
        [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            
            [self.array addObject:snapshot.name];
            [_dict setObject:snapshot.value forKey:snapshot.name];
            [self.tableView reloadData];
            if (self.array.count > 1) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.array.count -1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }];
    } withCancelBlock:^(NSError* error) {
        NSLog(@"Authentication status was cancelled! %@", error);
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillShow:)
     name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(keyboardWillHide:)
     name:UIKeyboardWillHideNotification object:nil];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self registerCustomCellsFromNibs];
    
    [self drawView];
}

-(void) drawView
{
    OSRoom *room = [OSSession getInstance].currentRoom;
    OSUser *user = [OSSession getInstance].user;
    
    _userName.text = [NSString stringWithFormat:@"%@ %@",user.firstName, user.lastName];
    
    NSURL *url = [NSURL URLWithString:[OSSession getInstance].user.picture];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage = [UIImage imageNamed:@"imgPlaceholder"];
    
    [_userImage setImageWithURLRequest:request
                      placeholderImage:placeholderImage
                               success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                   _userImage.image = image;
                               } failure:^(NSURLRequest *request,
                                           NSHTTPURLResponse *response, NSError *error) {
                               }];
    [_userImage.layer setMasksToBounds:YES];
    [_userImage.layer setCornerRadius:22.0];
    
    
    _roomTitle.text = room.title;
    _roomDescription.text = room.description;
    _roomSnippet.text = room.snippet;
    
    
    SET_BORDER_GREY(_messageInput);
    SET_ROUNDED_CORNER(_messageInput);
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    // We only have one section in our table view.
    return 1;
}

- (NSInteger)tableView:(UITableView*)table numberOfRowsInSection:(NSInteger)section
{
    // This is the number of chat messages.
    return [self.array count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell*)tableView:(UITableView*)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSTranscriptTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OSTranscriptTableViewCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSString *messageFirebaseId = [self.array objectAtIndex:indexPath.row];
    NSDictionary *message = _dict[messageFirebaseId];
    NSString *userId = message[@"user_id"];
    NSDictionary *userInfo = [[OSSession getInstance].allUsers objectForKey:userId];
    if([message isKindOfClass:[NSDictionary class]]){
        cell.fullName.text = [NSString stringWithFormat:@"%@ %@", userInfo[@"first_name"], userInfo[@"last_name"]];
    }
    
    NSString *text = message[@"text"];
    cell.message.text = text;
    if (![message[@"type"] isEqualToString:@"chatNotice"]) {
        cell.chilliCount.hidden = NO;
        cell.chilliBtn.hidden = NO;
        cell.chilliBtn.tag = indexPath.row;
        [cell.chilliBtn addTarget:self action:@selector(onClickChili:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        cell.chilliCount.hidden = YES;
        cell.chilliBtn.hidden = YES;
    }
    
    NSString *messageTimestamp = message[@"timestamp"];
    NSString *timeDetails = [[OSDateTimeUtils getInstance] convertDateTimeFromUTCtoLocalForDateTime:[messageTimestamp longLongValue]];
    NSArray *foo = [timeDetails componentsSeparatedByString: @"/"];
    NSString *time = [foo objectAtIndex: 0];
    NSString *date = [foo objectAtIndex: 1];
    cell.messageTime.text = time;
    NSURL *url = [NSURL URLWithString:userInfo[@"picture"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    UIImage *placeholderImage = [UIImage imageNamed:@"imgPlaceholder"];
    __weak OSTranscriptTableViewCell *weakCell = cell;
    [weakCell.thumbProgressView startAnimating];
    [cell.pic setImageWithURLRequest:request
                    placeholderImage:placeholderImage
                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                 weakCell.pic.image = image;
                                 [weakCell.thumbProgressView stopAnimating];
                             } failure:^(NSURLRequest *request,
                                         NSHTTPURLResponse *response, NSError *error) {
                                 [weakCell.thumbProgressView stopAnimating];
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
    [cell.status.layer setMasksToBounds:YES];
    [cell.status.layer setCornerRadius:5.0];
    [cell.pic.layer setMasksToBounds:YES];
    [cell.pic.layer setCornerRadius:22.0];
    return cell;
}

-(void) onClickChili:(UIButton*)sender
{
    UIButton *chiliBtn =  (UIButton *)[self.view viewWithTag:sender.tag];
    NSString *userId = [OSSession getInstance].user.userId;
    //{“chili”: {“firebase_msg_id”: “DSFDSRWE”, “given_by”: “reww2423423”, “given_to”: “rewfewfewg”}}
    NSString *messageFirebaseId = [self.array objectAtIndex:sender.tag];
    NSDictionary *message = _dict[messageFirebaseId];
    NSDictionary *parameters = @{@"chili":
                                     @{
                                         @"firebase_msg_id":@"",
                                         @"given_by":userId,
                                         @"given_to":message[@"user_id"]
                                         }
                                 };
    OSRequestUtils *request = [[OSRequestUtils alloc]init];
    [request httpRequestWithURL:[NSString stringWithFormat:@"api/user/chilis/%@",userId] andType:@"POST"  andAuthHeader:YES andParameters:parameters andResponseBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if ([[json objectForKey:@"success"] boolValue]) {
                [chiliBtn setImage:[UIImage imageNamed:@"red-chili"] forState:UIControlStateNormal];
            }
        }
    }];
}

-(void)registerCustomCellsFromNibs
{
    [self.tableView registerNib:[UINib nibWithNibName:@"OSTranscriptTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"OSTranscriptTableViewCell"];
}

#pragma mark - Text Field

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    
    if([textField.text length] > 0){
        
        long timestamp = [[NSDate date] timeIntervalSince1970];
        
        [[self.firebase childByAutoId] setValue:@{
                                                  @"user_id" : @"53c6030e94e4bf19725dd2c6",
                                                  @"text": textField.text,
                                                  @"timestamp" : [NSString stringWithFormat:@"%ld",timestamp]
                                                  }];
        
        [textField setText:@""];
        
        
    }
    
    return NO;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    if ([_messageInput isFirstResponder]) {
        [_messageInput resignFirstResponder];
    }
}

#pragma mark - Animations
-(void)dealloc
{
    // Unsubscribe from keyboard show/hide notifications.
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]
     removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

// text field upwards when the keyboard shows, and downwards when it hides.
- (void)keyboardWillShow:(NSNotification*)notification
{
    [self moveView:[notification userInfo] up:YES];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    [self moveView:[notification userInfo] up:NO];
}

- (void)moveView:(NSDictionary*)userInfo up:(BOOL)up
{
    CGRect keyboardEndFrame;
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]
     getValue:&keyboardEndFrame];
    
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey]
     getValue:&animationCurve];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey]
     getValue:&animationDuration];
    
    // Get the correct keyboard size to we slide the right amount.
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    int y = keyboardFrame.size.height * (up ? -1 : 1);
    self.view.frame = CGRectOffset(self.view.frame, 0, y);
    
    [UIView commitAnimations];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
@end
