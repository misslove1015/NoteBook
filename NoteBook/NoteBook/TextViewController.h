//
//  TextViewController.h
//  NoteBook
//
//  Created by miss on 16/12/7.
//  Copyright © 2016年 mukr. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ChangeNoteTitleBlock)(NSString *noteTitle);
typedef void (^TextEndEditingBlock)();

@interface TextViewController : UIViewController

@property (nonatomic, copy) ChangeNoteTitleBlock changeTitleBlock;
@property (nonatomic, copy) TextEndEditingBlock endEditingBlock;
@property (nonatomic, strong) NSDictionary *dic;

- (void)changeNoteTitle:(ChangeNoteTitleBlock)block;
- (void)textEndEditingBlock:(TextEndEditingBlock)block;

@end
