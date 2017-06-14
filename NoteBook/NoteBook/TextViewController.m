//
//  TextViewController.m
//  NoteBook
//
//  Created by miss on 16/12/7.
//  Copyright © 2016年 mukr. All rights reserved.
//

#import "TextViewController.h"

@interface TextViewController ()<UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomSpace;
@property (weak, nonatomic) IBOutlet UITextField *fontSizeTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *viewBottomSpace;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (nonatomic, assign) BOOL isShow;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, copy)   NSString *path;

@end

@implementation TextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _path = [NSString stringWithFormat:@"%@/Documents/%@.txt",NSHomeDirectory(),_dic[@"fileID"]];
    [self setNav];
    [self setUpTextView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)setNav{
    _titleTextField = [[UITextField alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width-140, 40)];
    _titleTextField.textAlignment = NSTextAlignmentCenter;
    _titleTextField.enabled = NO;
    [_titleTextField addTarget:self action:@selector(changeTitle) forControlEvents:UIControlEventEditingDidEnd];
    _titleTextField.text = _dic[@"fileName"];
    self.navigationItem.titleView = _titleTextField;
    [self setRightItemIsEdit:YES];
}

- (void)setUpTextView {
    NSString *fontSize = [[NSUserDefaults standardUserDefaults] objectForKey:@"fontSize"];
    if (fontSize) {
        _textView.font = [UIFont systemFontOfSize:[fontSize floatValue]];
    }
    _textView.text = [NSString stringWithContentsOfFile:_path encoding:NSUTF8StringEncoding error:nil];
    _textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    _textView.contentOffset = CGPointMake(0, 0);
    _textView.delegate = self;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]init];
    tap.numberOfTapsRequired = 2;
    [tap addTarget:self action:@selector(showOrHideBottomView)];
    [_textView addGestureRecognizer:tap];
    if (_textView.text.length == 0) {
        _textView.editable = YES;
        [_textView becomeFirstResponder];
        [self setRightItemIsEdit:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_endEditingBlock) {
        _endEditingBlock();
    }
}

- (void)keyboardChangeFrame:(NSNotification *)noti{
    NSInteger curve = [[noti.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    CGFloat duration = [[noti.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect endFrame = [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _textViewBottomSpace.constant = [UIScreen mainScreen].bounds.size.height-endFrame.origin.y;
    if (self.isShow) {
        _viewBottomSpace.constant = [UIScreen mainScreen].bounds.size.height-endFrame.origin.y;
    }
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:curve];
        [self.view layoutIfNeeded];
    }];
}

- (void)showOrHideBottomView{
    if (self.viewBottomSpace.constant > 0) {
        [self hideKeyboard];
        return;
    }
    if (self.isShow) {
        [self hideBottomView];
    }else {
        [self showBottomView];
    }
    self.isShow = !self.isShow;
    
    long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:_path error:nil] fileSize];
    NSString *fileSizeString;
    if (fileSize > 1024) {
        CGFloat fileSizeKB = fileSize /1024;
        fileSizeString = [NSString stringWithFormat:@"%.0fK",fileSizeKB];
    }else {
        fileSizeString = [NSString stringWithFormat:@"%lldB",fileSize];
    }
    self.infoLabel.text = [NSString stringWithFormat:@"共计:%ld字 大小:%@",_textView.text.length,fileSizeString];
    self.fontSizeTextField.text = [NSString stringWithFormat:@"%.0f",self.textView.font.pointSize];
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    [self save];
}

- (void)save{
    [_textView.text writeToFile:_path atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

- (void)changeTitle{
    if ([_titleTextField.text isEqualToString:_dic[@"fileName"]])return;
    if (self.changeTitleBlock) {
        self.changeTitleBlock(_titleTextField.text);
    }
}

- (void)openEdit{
    _textView.editable = YES;
    _titleTextField.enabled = YES;
    [self setRightItemIsEdit:NO];
}

- (void)setRightItemIsEdit:(BOOL)isEdit {
    if (isEdit) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"edit"] style:UIBarButtonItemStylePlain target:self action:@selector(openEdit)];
        self.navigationItem.rightBarButtonItem = item;
    }else {
        UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
        self.navigationItem.rightBarButtonItem = item;
    }
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
    _textView.editable = NO;
    _titleTextField.enabled = NO;
    [self setRightItemIsEdit:YES];
}

- (void)changeNoteTitle:(ChangeNoteTitleBlock)block{
    self.changeTitleBlock = block;
}

- (void)textEndEditingBlock:(TextEndEditingBlock)block {
    self.endEditingBlock = block;
}

- (IBAction)setFontSize:(id)sender {
    _textView.font = [UIFont systemFontOfSize:[self.fontSizeTextField.text floatValue]];
    [[NSUserDefaults standardUserDefaults] setObject:self.fontSizeTextField.text forKey:@"fontSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)hideBottomView:(id)sender {
    if (self.viewBottomSpace.constant > 0) {
        [self.view endEditing:YES];
    }else {
        self.isShow = NO;
        [self hideBottomView];
    }
   
}

- (void)showBottomView {
    self.viewBottomSpace.constant = 0;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)hideBottomView {
    self.viewBottomSpace.constant = -50;
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
