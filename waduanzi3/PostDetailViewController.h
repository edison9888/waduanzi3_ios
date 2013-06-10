//
//  PostDetailViewController.h
//  waduanzi3
//
//  Created by chendong on 13-6-5.
//  Copyright (c) 2013年 chendong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CDPost;
@class CDPostDetailView;

@interface PostDetailViewController : UITableViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate>
{
    NSMutableArray *_comments;
    NSInteger _lasttime;
}

@property (nonatomic) NSInteger postID;
@property (nonatomic, strong) CDPost *post;
@property (nonatomic, strong) UIImage *smallImage;
@property (nonatomic, strong) UIImage *middleImage;

- (id)initWithStyle:(UITableViewStyle)style andPost:(CDPost *)post;
- (id)initWithStyle:(UITableViewStyle)style andPostID:(NSInteger)post_id;

@end
