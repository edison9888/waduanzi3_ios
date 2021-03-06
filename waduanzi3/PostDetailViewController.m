//
//  PostDetailViewController.m
//  waduanzi3
//
//  Created by chendong on 13-6-5.
//  Copyright (c) 2013年 chendong. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "PostDetailViewController.h"
#import "WCAlertView.h"
#import "UIScrollView+SVPullToRefresh.h"
#import "UIScrollView+SVInfiniteScrolling.h"
#import "CDComment.h"
#import "CDPost.h"
#import "CDRestClient.h"
#import "CDDefine.h"
#import "CDCommentTableViewCell.h"
#import "UIImageView+WebCache.h"


@interface PostDetailViewController ()
- (void) initData;
- (void) loadPostComments;
- (void) loadPostDetail;
- (NSDictionary *) commentsParameters;
- (void) setCellSubViews:(CDCommentTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void) supportComment:(NSInteger) index;
- (void) copyComment:(NSInteger) index;
- (void) reportComment:(NSInteger) index;
@end


@implementation PostDetailViewController

@synthesize postID = _postID;
@synthesize post = _post;

- (void) initData
{
    _comments = [NSMutableArray array];
    _lasttime = 0;
}

- (id)initWithStyle:(UITableViewStyle)style andPostID:(NSInteger)post_id
{
    self = [super initWithStyle:style];
    if (self) {
        [self initData];
        self.postID = post_id;
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style andPost:(CDPost *)post
{
    self = [super initWithStyle:style];
    if (self) {
        [self initData];
        self.post = post;
        self.postID = [_post.post_id integerValue];
    }
    return self;
}

- (NSDictionary *) commentsParameters
{
    if (_comments.count > 0) {
        CDComment *lastComment = [_comments lastObject];
        _lasttime = [lastComment.create_time integerValue];
    }
    else
        _lasttime = 0;
    
    NSString *last_time = [NSString stringWithFormat:@"%d", _lasttime];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:last_time forKey:@"lasttime"];
    
    return [CDRestClient requestParams:params];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UISwipeGestureRecognizer *swipGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwips:)];
    swipGestureRecognizer.delegate = self;
    swipGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    swipGestureRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:swipGestureRecognizer];
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableViewLongPress:)];
    longPressRecognizer.minimumPressDuration = 0.5f;
    longPressRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:longPressRecognizer];
    
    __block PostDetailViewController *blockSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [blockSelf loadPostDetail];
    }];
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [blockSelf loadPostComments];
    }];
    
    [self.tableView triggerInfiniteScrolling];
}

- (void) handleSwips:(UISwipeGestureRecognizer *)recognizer
{
    NSLog(@"direction: %d", recognizer.direction);
    if (recognizer.direction & UISwipeGestureRecognizerDirectionRight)
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview datasource
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 :[_comments count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        static NSString *PostDetailCellIdentifier = @"PostDetailCell";
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PostDetailCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PostDetailCellIdentifier];
            
        }
        
        cell.textLabel.text = [_post.comment_count stringValue];
        cell.detailTextLabel.text = _post.content;

        if (_post.middle_pic.length > 0) {
            NSURL *imageUrl = [NSURL URLWithString:_post.middle_pic];
            UIImage *placeImage = [UIImage imageNamed:@"thumb_placeholder"];
            [cell.imageView setImageWithURL:imageUrl placeholderImage:placeImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                NSLog(@"error: %@", error);
            }];
        }
        
        
        return cell;
    }
    else {
        static NSString *CommentListCellIdentifier = @"CommentListCell";
        
        CDCommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CommentListCellIdentifier];
        if (cell == nil) {
            cell = [[CDCommentTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CommentListCellIdentifier];
            [self setCellSubViews:cell forRowAtIndexPath:indexPath];
        }
        
        CDComment *comment = [_comments objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = comment.content;
        cell.authorTextLabel.text = comment.author_name;
        
        cell.orderTextLabel.text = [NSString stringWithFormat:@"#%d", indexPath.row+1];
        
        [cell.avatarImageView setImageWithURL:[NSURL URLWithString:comment.user.mini_avatar] placeholderImage:[UIImage imageNamed:@"avatar_placeholder"]];
        
        comment = nil;
        
        return cell;
    }
    
}

- (void) setCellSubViews:(CDCommentTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.padding = CELL_PADDING;
    
    cell.detailTextLabel.font = [UIFont systemFontOfSize:14.0f];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:0.01f green:0.01f blue:0.01f alpha:1.00f];
    
    cell.authorTextLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    cell.authorTextLabel.textColor = [UIColor colorWithRed:0.37f green:0.75f blue:0.51f alpha:1.00f];
    
    cell.orderTextLabel.font = [UIFont systemFontOfSize:14.0f];
    cell.orderTextLabel.textColor = [UIColor colorWithRed:0.80f green:0.80f blue:0.80f alpha:1.00f];
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return 100;
    
    CDComment *comment = [_comments objectAtIndex:indexPath.row];
    
    CGFloat contentWidth = self.view.frame.size.width - CELL_PADDING*2;
    UIFont *detailFont = [UIFont systemFontOfSize:14.0f];
    CGSize detailLabelSize = [comment.content sizeWithFont:detailFont
                                      constrainedToSize:CGSizeMake(contentWidth, 9999.0)
                                          lineBreakMode:UILineBreakModeWordWrap];
    
    CGFloat cellHeight = CELL_PADDING + COMMENT_AVATAR_WIDTH + detailLabelSize.height + CELL_PADDING;
    
    return cellHeight;
}

- (void) handleTableViewLongPress:(UILongPressGestureRecognizer *)recognizer
{
    NSLog(@"state: %d", recognizer.state);
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [recognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        if (indexPath == nil || indexPath.section == 0) return;
        
        CDComment *comment = [_comments objectAtIndex:indexPath.row];
        NSString *upText = [NSString stringWithFormat:@"顶[%d]", [comment.up_count integerValue]];
        UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self
                                                         cancelButtonTitle:@"取消"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:upText, @"复制", @"举报", nil];
        actionSheet.tag = indexPath.row;
        [actionSheet showInView:self.navigationController.view];
    }
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self supportComment:actionSheet.tag];
            break;
        case 1:
            [self copyComment:actionSheet.tag];
            break;
        case 2:
            [self reportComment:actionSheet.tag];
            break;
        default:
            break;
    }
}

- (void) supportComment:(NSInteger) index
{
    CDComment *comment = [_comments objectAtIndex:index];
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[comment.comment_id stringValue], @"comment_id", nil];
    
    [objectManager.HTTPClient putPath:@"/comment/support" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        comment.up_count = [NSNumber numberWithInteger: [comment.up_count integerValue] + 1];
        [_comments replaceObjectAtIndex:index withObject:comment];
        
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
    }];
}

- (void) reportComment:(NSInteger)index
{
    CDComment *comment = [_comments objectAtIndex:index];
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:[comment.comment_id stringValue], @"comment_id", nil];
    
    [objectManager.HTTPClient putPath:@"/comment/report" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        comment.report_count = [NSNumber numberWithInteger: [comment.report_count integerValue] + 1];
        [_comments replaceObjectAtIndex:index withObject:comment];
        
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error);
    }];
}

- (void) copyComment:(NSInteger)index
{
    CDComment *comment = [_comments objectAtIndex:index];
    
    NSString *text = comment.content;
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:text];
}

#pragma mark - load data
- (void)loadPostComments
{
    // Load the object model via RestKit
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager getObjectsAtPath:[NSString stringWithFormat:@"/comment/show/%d", _postID]
                         parameters:[self commentsParameters]
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                [self.tableView.infiniteScrollingView stopAnimating];
                                
                                if (mappingResult.count > 0) {
                                    NSMutableArray* statuses = (NSMutableArray *)[mappingResult array];
                                    NSInteger currentCount = [_comments count];
                                    [_comments addObjectsFromArray:statuses];
                                    
                                    NSMutableArray *insertIndexPaths = [NSMutableArray array];
                                    for (int i=0; i<statuses.count; i++) {
                                        [insertIndexPaths addObject:[NSIndexPath indexPathForRow:currentCount+i inSection:1]];
                                    }
                                    
                                    [self.tableView beginUpdates];
                                    [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationFade];
                                    [self.tableView endUpdates];
                                }
                                else {
                                    NSLog(@"没有更多内容了");
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                [self.tableView.infiniteScrollingView stopAnimating];
                                [WCAlertView showAlertWithTitle:@"出错啦"
                                                        message:@"载入数据出错。"
                                             customizationBlock:^(WCAlertView *alertView) {
                                                 
                                                 alertView.style = WCAlertViewStyleWhite;
                                                 
                                             } completionBlock:^(NSUInteger buttonIndex, WCAlertView *alertView) {
                                                 if (buttonIndex == 1)
                                                     [self loadPostComments];
                                             } cancelButtonTitle:@"关闭" otherButtonTitles:@"重试",nil];
                                NSLog(@"Hit error: %@", error);
                            }];
    
}

- (void) loadPostDetail
{
    // Load the object model via RestKit
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    [objectManager getObjectsAtPath:[NSString stringWithFormat:@"/post/show/%d", _postID]
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                [self.tableView.pullToRefreshView stopAnimating];
                                
                                if (mappingResult.count > 0) {
                                    self.post = (CDPost *) [mappingResult firstObject];
                                    NSLog(@"%@", _post);
                                    
                                    
                                    if (self.isViewLoaded) {
                                        NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:0];
                                        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
                                    }
                                }
                                else {
                                    NSLog(@"没有更多内容了");
                                }
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                [self.tableView.pullToRefreshView stopAnimating];
                                [WCAlertView showAlertWithTitle:@"出错啦"
                                                        message:@"载入数据出错。"
                                             customizationBlock:^(WCAlertView *alertView) {
                                                 
                                                 alertView.style = WCAlertViewStyleWhite;
                                                 
                                             } completionBlock:^(NSUInteger buttonIndex, WCAlertView *alertView) {
                                                 if (buttonIndex == 1)
                                                     [self loadPostComments];
                                             } cancelButtonTitle:@"关闭" otherButtonTitles:@"重试",nil];
                                NSLog(@"Hit error: %@", error);
                            }];
    
}


@end
