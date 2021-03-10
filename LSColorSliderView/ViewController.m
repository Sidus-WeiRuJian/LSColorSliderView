//
//  ViewController.m
//  LSColorSliderView
//
//  Created by Choshim.Wei on 2021/3/9.
//

#import "ViewController.h"
#import "LSColorSliderView.h"
#import <Masonry/Masonry.h>


@interface ViewController ()

@property (nonatomic, strong) LSColorSliderView *colorSlider;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.colorSlider = [[LSColorSliderView alloc] initWithStyle:LSColorSliderStyleSAT];
    self.colorSlider.value = 120;
    self.colorSlider.satColor = UIColor.orangeColor;
    [self.view addSubview:self.colorSlider];
    [self.colorSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.width.equalTo(@76);
        make.height.equalTo(@500);
    }];
}


@end
