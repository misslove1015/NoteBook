//
//  NoteTableViewCell.h
//  NoteBook
//
//  Created by miss on 2017/6/13.
//  Copyright © 2017年 mukr. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoteTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *fileTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileInfoLabel;

@end
