//
//  ViewController.m
//  NoteBook
//
//  Created by miss on 16/12/6.
//  Copyright © 2016年 mukr. All rights reserved.
//

#import "ViewController.h"
#import "TextViewController.h"
#import "NoteTableViewCell.h"

#define PATH [NSString stringWithFormat:@"%@/Documents/",NSHomeDirectory()]

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *noteArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    _noteArray = [NSMutableArray arrayWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/noteArray.plist"]];
    if (!_noteArray) {
        _noteArray = [[NSMutableArray alloc]init];
    }
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.tableFooterView = [[UIView alloc]init];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _noteArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dic = _noteArray[indexPath.row];
    NoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.fileTitleLabel.text = dic[@"fileName"];
    cell.fileInfoLabel.text = [NSString stringWithFormat:@"%@    %@",dic[@"fileDate"],dic[@"fileSize"]];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]init];
    [longPress addTarget:self action:@selector(openTableViewEdit)];
    [cell.contentView addGestureRecognizer:longPress];
    return cell;
}

- (void)openTableViewEdit{
    _tableView.editing = YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_noteArray[indexPath.row]];
    TextViewController *text = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"textViewController"];
    text.dic = dic;
    [text textEndEditingBlock:^{ //正文做出了改动，刷新文章大小
        NSString *path = [NSString stringWithFormat:@"%@/Documents/%@.txt",NSHomeDirectory(),dic[@"fileID"]];
        NSString *fileSize = [self fileSizeWithPath:path];
        [dic setObject:fileSize forKey:@"fileSize"];
        [_noteArray replaceObjectAtIndex:indexPath.row withObject:dic];
        [self save];
    }];
    [text changeNoteTitle:^(NSString *noteTitle) { //标题做出了改动，刷新标题
        [dic setObject:noteTitle forKey:@"fileName"];
        [_noteArray replaceObjectAtIndex:indexPath.row withObject:dic];
        [self save];
    }];
    [self.navigationController pushViewController:text animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    _tableView.editing = NO;
    [self showAlertController:@"确定删除笔记?\n删除后将无法恢复" message:nil cancel:@"取消" confirm:@"确定" textFiledPlaceholder:nil tag:2 row:indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
    _tableView.editing = NO;
    NSDictionary *dic = _noteArray[[sourceIndexPath row]];
    [_noteArray removeObjectAtIndex:[sourceIndexPath row]];
    [_noteArray insertObject:dic atIndex:[destinationIndexPath row]];
    [self save];
}

- (void)save{
    [_tableView reloadData];
    [_noteArray writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/noteArray.plist"] atomically:NO];
}

- (IBAction)addNote:(id)sender {
    [self showAlertController:@"添加新笔记" message:nil cancel:@"取消" confirm:@"添加" textFiledPlaceholder:@"输入笔记名字" tag:1 row:0];
}

- (void)showAlertController:(NSString *)title message:(NSString *)message cancel:(NSString *)cancelText confirm:(NSString *)confirmText textFiledPlaceholder:(NSString *)textFieldPlaceholder tag:(NSInteger)tag row:(NSInteger)row{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmAction;
    if (confirmText) {
        confirmAction= [UIAlertAction actionWithTitle:confirmText style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (tag == 1) { //添加笔记
                NSString *fileID = [self nowDateStringIsShort:NO];
                NSString *filePath = [NSString stringWithFormat:@"%@/Documents/%@.txt",NSHomeDirectory(),fileID];
                [[NSFileManager defaultManager]createFileAtPath:filePath contents:nil attributes:nil];
                
                UITextField *textField = [alert.textFields firstObject];
                NSDictionary *dic = @{@"fileID":[self nowDateStringIsShort:NO],
                                      @"fileName":textField.text,
                                      @"fileDate":[self nowDateStringIsShort:YES],
                                      @"fileSize":@"0B"};
                [_noteArray insertObject:dic atIndex:0];
                [self save];
                
            }else if (tag == 2){ //删除笔记
                [_noteArray removeObjectAtIndex:row];
                [_tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                 [_noteArray writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/noteArray.plist"] atomically:NO];
            }
            
        }];

    }
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelText style:UIAlertActionStyleCancel handler:nil];
    
    if (textFieldPlaceholder) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = textFieldPlaceholder;
        }];
    }
    [alert addAction:cancelAction];
    if (confirmText) {
        [alert addAction:confirmAction];
    }    
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSString *)nowDateStringIsShort:(BOOL)isShort {
    NSDate *nowDate = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    if (isShort) {
        formatter.dateFormat = @"yyyy-MM-dd";
    }else {
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    return [formatter stringFromDate:nowDate];
}

- (NSString *)fileSizeWithPath:(NSString *)path {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [manager attributesOfItemAtPath:path error:nil];
    NSNumber *fileSize = [fileAttributes objectForKey:NSFileSize];
    NSString *fileSizeString;
    if ([fileSize unsignedLongLongValue] > 1024) {
        CGFloat fileSizeKB = [fileSize unsignedLongLongValue]/1024;
        fileSizeString = [NSString stringWithFormat:@"%.0fK",fileSizeKB];
    }else {
        fileSizeString = [NSString stringWithFormat:@"%.0fB",[fileSize floatValue]];
    }
    return fileSizeString;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
