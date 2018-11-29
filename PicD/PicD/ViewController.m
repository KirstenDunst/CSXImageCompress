//
//  ViewController.m
//  PicD
//
//  Created by CSX on 2018/1/19.
//  Copyright © 2018年 宗盛商业. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    UIImageView * imageView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor cyanColor];
    // Do any additional setup after loading the view, typically from a nib.
    imageView = [[UIImageView alloc]init];
    imageView.backgroundColor = [UIColor redColor];
    imageView.frame = CGRectMake(100, 200, 200, 200);
    [self.view addSubview:imageView];
    UIButton *myCreateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    myCreateButton.frame = CGRectMake(100, 100, 100, 100);
    [myCreateButton setBackgroundColor:[UIColor grayColor]];
    [myCreateButton setTitle:@"Choose" forState:UIControlStateNormal];
    [myCreateButton addTarget:self action:@selector(buttonChoose:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:myCreateButton];
    
    
}

- (void)buttonChoose:(UIButton *)sender{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray * paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];//去处需要的路径
    /// NSDocumentDirectory, NSUserDomainMask, YES)
    NSString *strPath = [documentsDirectory stringByAppendingPathComponent:@"text"];
    NSLog(@">>>>>>>>>>>>>>>>>%@",strPath);
    //    NSString *strPath = [[NSBundle mainBundle]pathForResource:@"123" ofType:@"png"];
    NSDirectoryEnumerator<NSString *> * myDirectoryEnumerator;
    
    myDirectoryEnumerator=  [fileManager enumeratorAtPath:strPath];
    
    
    while (strPath = [myDirectoryEnumerator nextObject]) {
        
        for (NSString * namePath in strPath.pathComponents) {
            if ([namePath isEqualToString:@".DS_Store"]) {
                continue;
            }
            NSLog(@"-----AAA-----%@", namePath  );
            static UIImage *image;
            image = [[UIImage alloc]initWithContentsOfFile:[NSString stringWithFormat:@"%@/%@",[documentsDirectory stringByAppendingPathComponent:@"text"],namePath]];
            [self compressedImageFiles:image imageKB:500 imageBlock:^(NSData *imageData) {
                NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"new/%@", namePath]];// 保存文件的名称

                BOOL result = [imageData writeToFile: filePath atomically:YES]; // 保存成功会返回YES
                
                NSLog(@"文件%@保存成功？%d",namePath,result);
            }];
        }
    }
    
}
//把图片压缩到指定的大小附近
- (NSData *)scaleImage:(UIImage *)image toKb:(NSInteger)kb{
    if (!image||kb<1) {//当图片不存在的时候或者压缩目的小于1kb那么不处理，直接返回
        return UIImageJPEGRepresentation(image, 1.0);
    }
    kb *= 1024;
    CGFloat compression = 0.9f;
    CGFloat maxCompression = 0.1f;
    NSData *imageData = UIImageJPEGRepresentation(image, 0.9);
    while ([imageData length]>kb && compression>maxCompression) {
        compression -= 0.1;
        imageData = UIImageJPEGRepresentation(image, compression);
    }
    return imageData;
}

- (void)compressedImageFiles:(UIImage *)image
                         imageKB:(CGFloat)fImageKBytes imageBlock:(void(^)(NSData *imageData))block{
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
            resultImage = [self thumbnailForData:imageData maxPixelSize:MAX(size.width, size.height)];
            imageData = UIImageJPEGRepresentation(resultImage, compression);
        }
    }

//   整理后的图片尽量不要用UIImageJPEGRepresentation方法转换，后面参数1.0并不表示的是原质量转换。
    block(imageData);
    
}

- (UIImage *)thumbnailForData:(NSData *)data maxPixelSize:(NSUInteger)size {
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
