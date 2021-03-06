//
//  CDPost.h
//  waduanzi3
//
//  Created by chendong on 13-5-29.
//  Copyright (c) 2013年 chendong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CDUser.h"


@interface CDPost : NSObject

@property (nonatomic, strong) NSNumber * post_id;
@property (nonatomic, strong) NSNumber * channel_id;
@property (nonatomic, copy) NSString * title;
@property (nonatomic, copy) NSString * content;
@property (nonatomic, strong) NSNumber * up_count;
@property (nonatomic, strong) NSNumber * down_count;
@property (nonatomic, strong) NSNumber * create_time;
@property (nonatomic, strong) NSString * create_time_at;
@property (nonatomic, strong) NSNumber * author_id;
@property (nonatomic, copy) NSString * author_name;
@property (nonatomic, strong) NSNumber * favorite_count;
@property (nonatomic, strong) NSNumber * comment_count;
@property (nonatomic, copy) NSString * tags;
@property (nonatomic, copy) NSString * small_pic;
@property (nonatomic, copy) NSString * middle_pic;
@property (nonatomic, copy) NSString * large_pic;
@property (nonatomic, strong) NSNumber * pic_frames;

@property (nonatomic, strong) CDUser *user;

@end
