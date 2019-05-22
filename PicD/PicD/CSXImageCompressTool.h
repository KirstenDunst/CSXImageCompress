/*      __.--'\     \.__./     /'--.__
    _.-'       '.__.'    '.__.'       '-._
  .'                曹世鑫                 '.
/                                           \
|    CSDN:https://me.csdn.net/BUG_delete     |
|   GitHub:https://github.com/KirstenDunst   |
\         .---.              .---.          /
  '._    .'     '.''.    .''.'     '.    _.'
     '-./            \  /            \.-'
                      ''*/
//
//  CSXImageCompressTool.h
//  PicD
//
//  Created by 曹世鑫 on 2019/5/22.
//  Copyright © 2019 宗盛商业. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^ImageBlock)(NSData *imageData);

NS_ASSUME_NONNULL_BEGIN

@interface CSXImageCompressTool : NSObject


/**
 内存处理，循环压缩处理，图片处理过程中内存不会爆增

 @param image 原始图片
 @param fImageKBytes 限制最终的文件大小
 @param block 处理之后的数据返回，data类型
 */
+ (void)compressedImageFiles:(UIImage *)image imageKB:(CGFloat)fImageKBytes imageBlock:(void(^)(NSData *imageData))block;



/**
 图片压缩（针对内存爆表出现的压缩失真分层问题的使用工具）

 @param orignalImage 原始图片
 @param fImageKBytes 最终限制
 @param block 处理之后的数据返回，data类型
 */
+ (void)resetSizeOfImage:(UIImage *)orignalImage imageKB:(CGFloat)fImageKBytes imageBlock:(ImageBlock)block;



@end

NS_ASSUME_NONNULL_END
