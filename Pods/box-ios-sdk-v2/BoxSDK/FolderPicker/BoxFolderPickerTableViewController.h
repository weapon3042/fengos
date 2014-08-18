//
//  BoxFolderPickerViewController.h
//  FolderPickerSampleApp
//
//  Created on 5/1/13.
//  Copyright (c) 2013 Box Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class BoxFolderPickerViewController;
@class BoxItem;
@class BoxSDK;
@class BoxFolderPickerHelper;

/**
 * The BoxFolderPickerTableViewControllerDelegate interface provides methods
 * for indicating the current state of a BoxFolderPickerTableViewController.
 */
@protocol BoxFolderPickerTableViewControllerDelegate <NSObject>

/**
 * Returns the number of items that needs to be displayed
 */
- (NSUInteger)currentNumberOfItems;

/**
 * Returns the number of items in the current folder (can be more that currentNumberOfItems because of the pagination).
 */
- (NSUInteger)totalNumberOfItems;

/**
 * Returns the item that needs to be displayed at the specified row
 */
- (BoxItem *)itemAtIndex:(NSUInteger)index;

/**
 * Starts downloading the next page of items
 */
- (void)loadNextSetOfItems;

/**
 * Returns the path where thumbnails need to be stored. Can be nil.
 */
- (NSString *)thumbnailPath;

/**
 * Returns whether the user wants to display thumbnails or not.
 */
- (BOOL)thumbnailsEnabled;

/**
 * Returns whether the user can select the files or not
 */
- (BOOL)fileSelectionEnabled;

/**
 * Returns the SDK currently used by the folder picker
 */
- (BoxSDK *)currentSDK;


@end

/**
 * BoxFolderPickerTableViewController is a paged UITableView that can load
 * BoxItems in batches.
 */
@interface BoxFolderPickerTableViewController : UITableViewController

@property (nonatomic, readwrite, weak) BoxFolderPickerViewController *folderPicker;
@property (nonatomic, readwrite, weak) id<BoxFolderPickerTableViewControllerDelegate> delegate;
@property (nonatomic, readwrite, strong) BoxFolderPickerHelper *helper;

- (id)initWithFolderPickerHelper:(BoxFolderPickerHelper *)helper;

- (void)refreshData;

@end
