//
//  CSXImageCompressTool.m
//  PicD
//
//  Created by 曹世鑫 on 2019/5/22.
//  Copyright © 2019 宗盛商业. All rights reserved.
//

#import "CSXImageCompressTool.h"

@implementation CSXImageCompressTool


+ (void)compressedImageFiles:(UIImage *)image imageKB:(CGFloat)fImageKBytes imageBlock:(void(^)(NSData *imageData))block {
    //二分法压缩图片
    CGFloat compression = 1;
    NSData *imageData = UIImageJPEGRepresentation(image, compression);
    NSUInteger fImageBytes = fImageKBytes * 1000;//需要压缩的字节Byte，iOS系统内部的进制1000
    if (imageData.length <= fImageBytes){
        block(imageData);
        return;
    }
    CGFloat max = 1;
    CGFloat min = 0;
    //指数二分处理，s首先计算最小值
    compression = pow(2, -6);
    imageData = UIImageJPEGRepresentation(image, compression);
    if (imageData.length < fImageBytes) {
        //二分最大10次，区间范围精度最大可达0.00097657；最大6次，精度可达0.015625
        for (int i = 0; i < 6; ++i) {
            compression = (max + min) / 2;
            imageData = UIImageJPEGRepresentation(image, compression);
            //容错区间范围0.9～1.0
            if (imageData.length < fImageBytes * 0.9) {
                min = compression;
            } else if (imageData.length > fImageBytes) {
                max = compression;
            } else {
                break;
            }
        }
        
        block(imageData);
        return;
    }
    
    // 对于图片太大上面的压缩比即使很小压缩出来的图片也是很大，不满足使用。
    //然后再一步绘制压缩处理
    UIImage *resultImage = [UIImage imageWithData:imageData];
    while (imageData.length > fImageBytes) {
        @autoreleasepool {
            CGFloat ratio = (CGFloat)fImageBytes / imageData.length;
            //使用NSUInteger不然由于精度问题，某些图片会有白边
            NSLog(@">>>>>>>>>>>>>>>>>%f>>>>>>>>>>>>%f>>>>>>>>>>>%f",resultImage.size.width,sqrtf(ratio),resultImage.size.height);
            CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                     (NSUInteger)(resultImage.size.height * sqrtf(ratio)));
            resultImage = [self createImageForData:imageData maxPixelSize:MAX(size.width, size.height)];
            imageData = UIImageJPEGRepresentation(resultImage, compression);
        }
    }
    
    //   整理后的图片尽量不要用UIImageJPEGRepresentation方法转换，后面参数1.0并不表示的是原质量转换。
    block(imageData);
}

+ (void)resetSizeOfImage:(UIImage *)orignalImage imageKB:(CGFloat)fImageKBytes imageBlock:(ImageBlock)block {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //二分法压缩图片
        CGFloat compression = 1;
        __block NSData *imageData = UIImageJPEGRepresentation(orignalImage, compression);
        NSUInteger fImageBytes = fImageKBytes*1000;
        if (imageData.length <= fImageBytes){
            block(imageData);
            return;
        }
        //这里二分之前重绘一下，就能解决掉内存的不足导致的问题。
        UIImage *newImage = [self createImageForData:imageData maxPixelSize:MAX((NSUInteger)orignalImage.size.width, (NSUInteger)orignalImage.size.height)];
        [self halfFuntionImage:newImage maxSizeByte:fImageBytes back:^(NSData *halfImageData, CGFloat compress) {
            //再一步绘制压缩处理
            UIImage *resultImage = [UIImage imageWithData:halfImageData];
            imageData = halfImageData;
            while (imageData.length > fImageBytes) {
                CGFloat ratio = (CGFloat)fImageBytes / imageData.length;
                //使用NSUInteger不然由于精度问题，某些图片会有白边
                CGSize size = CGSizeMake((NSUInteger)(resultImage.size.width * sqrtf(ratio)),
                                         (NSUInteger)(resultImage.size.height * sqrtf(ratio)));
                resultImage = [self createImageForData:imageData maxPixelSize:MAX(size.width, size.height)];
                imageData = UIImageJPEGRepresentation(resultImage, compress);
            }
            //   整理后的图片尽量不要用UIImageJPEGRepresentation方法转换，后面参数1.0并不表示的是原质量转换。
            block(imageData);
        }];
    });
}


#pragma mark --------------二分法
+ (void)halfFuntionImage:(UIImage *)image maxSizeByte:(NSInteger)maxSizeByte back:(void(^)(NSData *halfImageData, CGFloat compress))block {
    //二分法压缩图片
    CGFloat compression = 1;
    NSData *imageData = UIImageJPEGRepresentation(image, compression);
    CGFloat max = 1;
    CGFloat min = 0;
    //指数二分处理，s首先计算最小值
    compression = pow(2, -6);
    imageData = UIImageJPEGRepresentation(image, compression);
    if (imageData.length < maxSizeByte) {
        //二分最大10次，区间范围精度最大可达0.00097657；最大6次，精度可达0.015625
        for (int i = 0; i < 6; i++) {
            compression = (max + min) / 2;
            imageData = UIImageJPEGRepresentation(image, compression);
            //容错区间范围0.9～1.0
            if (imageData.length < maxSizeByte * 0.9) {
                min = compression;
            } else if (imageData.length > maxSizeByte) {
                max = compression;
            } else {
                break;
            }
        }
    }
    if (block) {
        block(imageData, compression);
    }
}

+ (UIImage *)createImageForData:(NSData *)data maxPixelSize:(NSUInteger)size {
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
    CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef) @{
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
                                                                                                      (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(size),
                                                                                                      (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES,
                                                                                                      });
    CFRelease(source);
    CFRelease(provider);
    if (!imageRef) {
        return nil;
    }
    UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
    CFRelease(imageRef);
    return toReturn;
}


@end
