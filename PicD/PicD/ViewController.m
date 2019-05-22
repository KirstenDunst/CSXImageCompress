//
//  ViewController.m
//  PicD
//
//  Created by CSX on 2018/1/19.
//  Copyright © 2018年 宗盛商业. All rights reserved.
//

#import "ViewController.h"
#import "CSXImageCompressTool.h"

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
//            [CSXImageCompressTool resetSizeOfImage:image imageKB:500 imageBlock:^(NSData *imageData) {
            [CSXImageCompressTool compressedImageFiles:image imageKB:500 imageBlock:^(NSData *imageData) {
                NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"new/%@", namePath]];// 保存文件的名称
                
                BOOL result = [imageData writeToFile: filePath atomically:YES]; // 保存成功会返回YES
                
                NSLog(@"文件%@保存成功？%d",namePath,result);
            }];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
