//
//  OSTranscriptTableViewCell.m
//  OpenSilo
//
//  Created by Peng Wan & Elmir Kouliev on 7/22/14.
//  Copyright (c) 2014 OpenSilo Co. All rights reserved.
//

#import "OSTranscriptTableViewCell.h"
#import "OSSession.h"
#import "OSDateTimeUtils.h"
#import "UIImageView+AFNetworking.h"
#import <Firebase/Firebase.h>
#import "OSUIMacro.h"
#import "OSWebServiceMacro.h"

@implementation OSTranscriptTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.status.layer setMasksToBounds:YES];
    [self.status.layer setCornerRadius:5.0];
    [self.pic.layer setMasksToBounds:YES];
    [self.pic.layer setCornerRadius:22.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setTranscriptCell:(NSDictionary *)messageData{
    
    NSString *userId = messageData[@"user_id"];
   
    NSDictionary *userInfo = [[OSSession getInstance].allUsers objectForKey:userId];
    
    _fullName.text = [NSString stringWithFormat:@"%@ %@", userInfo[@"first_name"], userInfo[@"last_name"]];
    
    NSString *messageTimestamp = messageData[@"timestamp"];
    NSString *timeDetails = [[OSDateTimeUtils getInstance] convertDateTimeFromUTCtoLocalForDateTime:[messageTimestamp longLongValue]];
    NSArray *foo = [timeDetails componentsSeparatedByString: @"/"];
    NSString *time = [foo objectAtIndex: 0];

    _messageTime.text = time;

    
    NSURL *url = [NSURL URLWithString:userInfo[@"picture"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    UIImage *placeholderImage = [UIImage imageNamed:@"imgPlaceholder"];

    [self.thumbProgressView startAnimating];
    
    [self.pic setImageWithURLRequest:request
                    placeholderImage:placeholderImage
                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                 _pic.image = image;
                                 [_thumbProgressView stopAnimating];
                             } failure:^(NSURLRequest *request,
                                         NSHTTPURLResponse *response, NSError *error) {
                                 [_thumbProgressView stopAnimating];
                             }];
    
    self.thumbProgressView.hidesWhenStopped=YES;
    
    Firebase *fb = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/presence/%@",fireBaseUrl,userInfo[@"user_id"]]];
    
    //online/offline/idle/away/busy
    _status.backgroundColor = USER_AWAY;
    [fb authWithCredential:fireBaseSecret withCompletionBlock:^(NSError* error, id authData) {
        [fb observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            //NSLog(@"status:%@", snapshot.value);
            if ([snapshot.value isEqualToString:@"online"]) {
                //                NSLog(@"userId:%@", userInfo[@"user_id"]);
                _status.backgroundColor = USER_ONLINE;
            }
            if ([snapshot.value isEqualToString:@"busy"]) {
                _status.backgroundColor = USER_BUSY;
            }
        }];
    } withCancelBlock:^(NSError* error) {
        NSLog(@"error:%@",error);
    }];



}

@end
