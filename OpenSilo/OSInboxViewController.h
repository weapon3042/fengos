//
//  OSInboxViewController.h
//  OpenSilo
//
//  Created by Peng Wan & Elmir Kouliev on 8/5/14.
//  Copyright (c) 2014 OpenSilo Co. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSInboxViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate>


@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) NSMutableArray *filteredArray;
@property (nonatomic, strong) NSMutableArray *inboxArray;
@property (nonatomic, strong) NSMutableArray *selectedArray;
@property (nonatomic, strong) NSMutableDictionary *dict;

@end
