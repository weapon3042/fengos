//
//  OSChannelViewController.m
//  OpenSilo
//
//  Created by Peng Wan & Elmir Kouliev  on 8/2/14.
//  Copyright (c) 2014 OpenSilo Co. All rights reserved.
//

#import "OSChannelViewController.h"
#import "OSUserUtils.h"
#import "OSSession.h"
#import "OSWebServiceMacro.h"
#import "OSMacro.h"
#import "OSUIMacro.h"
#import "OSConstant.h"
#import "METransitions.h"
#import "OSTranscriptTableViewCell.h"
#import "OSSearchViewController.h"
#import "OSDataManager.h"
#import "OSGuidUtils.h"
#import "OSToastUtils.h"
#import <APToast/UIView+APToast.h>
#import "OSRequestUtils.h"

@interface OSChannelViewController ()

@property (nonatomic, strong) METransitions *transitions;
@property (nonatomic, weak) NSString *pinText;

@end

@implementation OSChannelViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[OSUserUtils getInstance] reloadAllUsers];
    });
    
    [super viewWillAppear:animated];
    
    self.messageThread = [[NSMutableArray alloc] init];
    
    // Initialize the root of our Firebase namespace.
    NSString *channelId = [OSSession getInstance].currentChannel.fireBaseId ? [OSSession getInstance].currentChannel.fireBaseId : DEFAULT_FIREBASE_CHANNEL_ID;
    
    NSString *url = [NSString stringWithFormat:@"%@channel/%@/messages",fireBaseUrl,channelId];
    
    self.firebase = [[Firebase alloc] initWithUrl:url];
    
    [self.firebase authWithCredential:fireBaseSecret withCompletionBlock:^(NSError* error, id authData) {
        [self.firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            [self.messageThread addObject:snapshot.value];
            [self.tableView reloadData];
            if (self.messageThread.count > 1) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.messageThread.count -1) inSection:0]atScrollPosition:UITableViewScrollPositionBottom animated:YES];
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
    return [self.messageThread count];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell*)tableView:(UITableView*)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OSTranscriptTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OSTranscriptTableViewCell" forIndexPath:indexPath];
    
    NSDictionary *message = [self.messageThread objectAtIndex:indexPath.row];
    
    [cell setTranscriptCell:message];
    
    NSString *text = message[@"text"];
    if (![message[@"type"] isEqualToString:@"chatNotice"]) {
        cell.message.hidden = YES;
        cell.popBtn.hidden = NO;
        [cell.popBtn setTitle:text forState:UIControlStateNormal];
        cell.popBtn.tag = indexPath.row;
        [cell.popBtn addTarget:self action:@selector(popupOption:) forControlEvents:UIControlEventTouchUpInside];
    }else{
        cell.message.hidden = NO;
        cell.popBtn.hidden = YES;
        cell.message.text = text;
    }
    return cell;
}

-(void) popupOption:(UIButton*)sender
{
    UIButton *pinBtn =  (UIButton *)[self.view viewWithTag:sender.tag];
    _pinText = pinBtn.titleLabel.text;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Pin a question" message:[NSString stringWithFormat:@"Are you sure to pin '%@'",_pinText] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch(buttonIndex) {
        case 0:
            break;
        case 1:
            [self pinQuestion];
            break;
    }
}

-(void) pinQuestion
{
    NSString *guid = [[OSGuidUtils getInstance] createGuid];
    NSDictionary *parameters = @{
                                 @"question_id": guid,
                                 @"question":_pinText
                                 };
    OSRequestUtils *loginRequest = [[OSRequestUtils alloc]init];
    NSString *channelId = [OSSession getInstance].currentChannel.channelId;
    if (!channelId) {
        channelId = DEFAULT_CHANNEL_ID;
    }
    [loginRequest httpRequestWithURL:[NSString stringWithFormat:@"api/channels/%@/pinnedquestions",channelId] andType:@"POST" andAuthHeader:YES andParameters:parameters andResponseBlock:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if ([[json objectForKey:@"success"] boolValue]) {
                [self.view ap_makeToastView:[[OSToastUtils getInstance] getToastMessage:@"Successfully pinned." andType:TOAST_SUC] duration:4.f position:APToastPositionBottom];
            }else{
                [self.view ap_makeToastView:[[OSToastUtils getInstance] getToastMessage:@"Fail to pins" andType:TOAST_FAIL] duration:4.f position:APToastPositionBottom];
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
