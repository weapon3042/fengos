//
//  OSPeopleTableView_m
//  OpenSilo
//
//  Created by Peng Wan on 7/19/14.
//  Copyright (c) 2014 OpenSilo Inc. All rights reserved.
//

#import "OSPeopleTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import <Firebase/Firebase.h>
#import "OSUIMacro.h"
#import "OSWebServiceMacro.h"

@implementation OSPeopleTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    [_status.layer setMasksToBounds:YES];
    [_status.layer setCornerRadius:5.0];
    [_pic.layer setMasksToBounds:YES];
    [_pic.layer setCornerRadius:22.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setPeopleCell:(NSDictionary *)userData{
    
    _fullName.text = [NSString stringWithFormat:@"%@ %@", userData[@"first_name"], userData[@"last_name"]];
    _fullName.textColor = [UIColor blackColor];
    _jobTitle.text = userData[@"knowledge_title"];
    _userEmail = userData[@"email"];
    _userId = userData[@"user_id"];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[userData objectForKey:@"picture"]]];
    
    [self.thumbProgressView startAnimating];
    
    [self.pic setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"imgPlaceholder"]
                             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                 self.pic.image = image;
                                 [self.thumbProgressView stopAnimating];
                             }
                             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                 [self.thumbProgressView stopAnimating];
                                 self.thumbProgressView.hidden = YES;
                             }];
    
    self.thumbProgressView.hidesWhenStopped=YES;
    self.status.backgroundColor = USER_AWAY;
    
    Firebase *firebase = [[Firebase alloc]
                          initWithUrl:[NSString stringWithFormat:@"%@/presence/%@",fireBaseUrl,userData[@"user_id"]]];
    
    [firebase authWithCredential:fireBaseSecret withCompletionBlock:^(NSError* error, id authData) {
        [firebase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            if ([snapshot.value isEqualToString:@"online"])
                self.status.backgroundColor = USER_ONLINE;
            else if ([snapshot.value isEqualToString:@"busy"])
                self.status.backgroundColor = USER_BUSY;
            
        }];
    } withCancelBlock:^(NSError* error) {
        NSLog(@"error:%@",error);
    }];
    
}

@end
