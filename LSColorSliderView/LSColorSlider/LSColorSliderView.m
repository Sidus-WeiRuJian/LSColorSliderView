//
//  LSColorSliderView.m
//  LSColorSliderView
//
//  Created by Choshim.Wei on 2021/3/9.
//  Copyright © 2021 Sidus Link. All rights reserved.
//

#import "LSColorSliderView.h"
#import <Masonry/Masonry.h>
#import "MSColorUtils.h"

#define SEND_DATA_INTERVAL 0.2
#define RADIUS 15
#define CCT_VALUE 56
#define LSRGB(r, g, b) ([UIColor colorWithRed:((r)/255.0) green:((g)/255.0) blue:((b)/255.0) alpha:1.0])

@interface LSColorSliderView()

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *addBtn;
@property (nonatomic, strong) UIButton *subBtn;
@property (nonatomic, strong) UIView *sliderView;
@property (nonatomic, strong) UIButton *thumbView;
@property (nonatomic, strong) UIView *valueView;

@property (nonatomic, assign) LSColorSliderStyle style;

/// HUE 0~360 || CCT 16~100 || GM 0~20 || INT 0~100
@property (nonatomic, assign) NSInteger minValue;
@property (nonatomic, assign) NSInteger maxValue;

@property (nonatomic, assign) BOOL allowSend;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation LSColorSliderView

- (instancetype)initWithStyle:(LSColorSliderStyle)style {
    self = [super init];
    if (self) {
        
        self.value = 0;
        self.minValue = 0;
        self.maxValue = 360;
        self.style = style;
        [self setupView];
        
        
    }
    return self;
}

#pragma mark - Setter
- (void)setTextFont:(UIFont *)textFont {
    _textFont = textFont;
    self.valueLabel.font = textFont;
    self.titleLabel.font = textFont;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.valueLabel.textColor = textColor;
    self.titleLabel.textColor = textColor;
}

- (void)setSatColor:(UIColor *)satColor {
    _satColor = satColor;
    if (self.style == LSColorSliderStyleSAT) {
        self.sliderView.backgroundColor = [self colorWithSAT:self.value];
        CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
        gradientLayer.frame = self.sliderView.bounds;
        gradientLayer.colors = @[(id)satColor.CGColor, (id)UIColor.whiteColor.CGColor];
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(0, 1);
        gradientLayer.cornerRadius = 8;
        [self.sliderView.layer addSublayer:gradientLayer];
    }
}

- (void)setupView {
    
    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.backgroundColor = LSRGB(16, 16, 16);
    self.valueLabel.layer.cornerRadius = 20;
    self.valueLabel.layer.masksToBounds = YES;
    self.valueLabel.text = @"0°";
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.valueLabel];
    [self.valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self);
        make.height.equalTo(@40);
    }];
    
    self.addBtn = [[UIButton alloc] init];
    [self.addBtn setImage:[UIImage imageNamed:@"bridge_cct_add"] forState:UIControlStateNormal];
    [self.addBtn addTarget:self action:@selector(addBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.addBtn];
    [self.addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.valueLabel.mas_bottom).offset(10);
        make.width.height.equalTo(@44);
    }];
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.backgroundColor = LSRGB(16, 16, 16);
    self.titleLabel.layer.cornerRadius = 20;
    self.titleLabel.layer.masksToBounds = YES;
    self.titleLabel.text = @"HUE";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self);
        make.height.equalTo(@40);
    }];
    
    self.subBtn = [[UIButton alloc] init];
    [self.subBtn setImage:[UIImage imageNamed:@"bridge_cct_less"] forState:UIControlStateNormal];
    [self.subBtn addTarget:self action:@selector(subBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.subBtn];
    [self.subBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.titleLabel.mas_top).offset(-10);
        make.width.height.equalTo(@44);
    }];
    
    self.sliderView = [[UIView alloc] init];
    self.sliderView.backgroundColor = LSRGB(16, 16, 16);
    self.sliderView.layer.cornerRadius = 13;
    self.sliderView.layer.masksToBounds = YES;
    [self addSubview:self.sliderView];
    [self.sliderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.top.equalTo(self.addBtn.mas_bottom).offset(10);
        make.bottom.equalTo(self.subBtn.mas_top).offset(-10);
        make.width.equalTo(@26);
    }];
    
    self.thumbView = [[UIButton alloc] init];
    self.thumbView.backgroundColor = LSRGB(216, 216, 216);
    self.thumbView.layer.cornerRadius = RADIUS;
    self.thumbView.layer.borderColor = UIColor.whiteColor.CGColor;
    self.thumbView.layer.borderWidth = 2;
    [self addSubview:self.thumbView];
    
    self.valueView = [[UIView alloc] init];
    self.valueView.layer.cornerRadius = 13;
    self.valueView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    self.valueView.backgroundColor = LSRGB(90, 90, 90);
    [self insertSubview:self.valueView belowSubview:self.thumbView];
    

    UIPanGestureRecognizer *thumbPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureHandle:)];
    [self.thumbView addGestureRecognizer:thumbPanGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(sliderViewPanGesture:)];
    [self addGestureRecognizer:panGesture];
}

- (void)sliderViewPanGesture:(UIPanGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self];
   
    
    static CGFloat offsetY = 0.0;
    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint origin =  self.thumbView.frame.origin;
        offsetY = origin.y - location.y;
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:SEND_DATA_INTERVAL target:self selector:@selector(allowSendValue) userInfo:nil repeats:YES];
        }
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self.timer invalidate];
        self.timer = nil;
        self.allowSend = NO;
    }
    
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat y = location.y + offsetY;
        CGFloat x = self.sliderView.center.x;
        if (y <= CGRectGetMinY(self.sliderView.frame) + RADIUS) {
            y = CGRectGetMinY(self.sliderView.frame) + RADIUS;
        }
        
        if (y >= CGRectGetMaxY(self.sliderView.frame) - RADIUS) {
            y = CGRectGetMaxY(self.sliderView.frame) - RADIUS;
        }
        
        CGPoint center = CGPointMake(x, y);
        self.thumbView.center = center;
        
        CGPoint point = [self convertPoint:center toView:self.sliderView];
        CGFloat h = CGRectGetHeight(self.sliderView.frame) - point.y;
        CGRect rect = self.valueView.frame;
        rect.origin.x = CGRectGetMinX(self.sliderView.frame);
        rect.origin.y = CGRectGetMinY(self.thumbView.frame)+RADIUS;
        rect.size.height = h;
        self.valueView.frame = rect;
        
        CGFloat offset = (CGRectGetHeight(self.valueView.frame) - RADIUS) / (CGRectGetHeight(self.sliderView.frame) - RADIUS * 2);
        CGFloat value = offset * (self.maxValue - self.minValue) + self.minValue;
        
        [self setChangedValue:value];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(colorSliderView:didChangedValue:)]) {
            [self.delegate colorSliderView:self didChangedValue:value];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(colorSliderView:didOutputValue:)] && self.allowSend) {
            self.allowSend = NO;
            [self.delegate colorSliderView:self didOutputValue:value];
        }
    }
}

- (void)panGestureHandle:(UIPanGestureRecognizer *)sender {
    CGPoint location = [sender locationInView:self];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:SEND_DATA_INTERVAL target:self selector:@selector(allowSendValue) userInfo:nil repeats:YES];
        }
    }
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self.timer invalidate];
        self.timer = nil;
        self.allowSend = NO;
    }
    if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat y = location.y;
        CGFloat x = self.sliderView.center.x;
        if (y <= CGRectGetMinY(self.sliderView.frame) + RADIUS) {
            y = CGRectGetMinY(self.sliderView.frame) + RADIUS;
        }
        
        if (y >= CGRectGetMaxY(self.sliderView.frame) - RADIUS) {
            y = CGRectGetMaxY(self.sliderView.frame) - RADIUS;
        }
        
        CGPoint center = CGPointMake(x, y);
        self.thumbView.center = center;
        
        CGPoint point = [self convertPoint:center toView:self.sliderView];
        CGFloat h = CGRectGetHeight(self.sliderView.frame) - point.y;
        CGRect rect = self.valueView.frame;
        rect.origin.x = CGRectGetMinX(self.sliderView.frame);
        rect.origin.y = CGRectGetMinY(self.thumbView.frame)+RADIUS;
        rect.size.height = h;
        self.valueView.frame = rect;
        
        CGFloat offset = (CGRectGetHeight(self.valueView.frame) - RADIUS) / (CGRectGetHeight(self.sliderView.frame) - RADIUS * 2);
        CGFloat value = offset * (self.maxValue - self.minValue) + self.minValue;
        
        [self setChangedValue:value];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(colorSliderView:didChangedValue:)]) {
            [self.delegate colorSliderView:self didChangedValue:value];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(colorSliderView:didOutputValue:)] && self.allowSend) {
            self.allowSend = NO;
            [self.delegate colorSliderView:self didOutputValue:value];
        }
    }
}

- (void)addBtnAction {
    self.value += 1;
    if (self.value >= self.maxValue) {
        self.value = self.maxValue;
    }
    CGPoint point = [self locationWithValue:self.value];
    CGPoint location = [self.sliderView convertPoint:point toView:self];
    self.thumbView.center = location;
    self.valueView.frame = CGRectMake(CGRectGetMinX(self.sliderView.frame),
                                      location.y,
                                      self.sliderView.frame.size.width,
                                      self.sliderView.frame.size.height - point.y);
    [self setChangedValue:self.value];
}

- (void)subBtnAction {
    self.value -= 1;
    if (self.value <= self.minValue) {
        self.value = self.minValue;
    }
    CGPoint point = [self locationWithValue:self.value];
    CGPoint location = [self.sliderView convertPoint:point toView:self];
    self.thumbView.center = location;
    self.valueView.frame = CGRectMake(CGRectGetMinX(self.sliderView.frame),
                                      location.y,
                                      self.sliderView.frame.size.width,
                                      self.sliderView.frame.size.height - point.y);
    [self setChangedValue:self.value];
}

- (void)setChangedValue:(CGFloat)value {
     _value = value;
    switch (self.style) {
        case LSColorSliderStyleINT:
        {
            self.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", value,@"%"];
            break;
        }
        case LSColorSliderStyleHUE:
        {
            self.valueLabel.text = [NSString stringWithFormat:@"%.0f°", value];
            self.thumbView.backgroundColor = [UIColor colorWithHue:value/360.0 saturation:1 brightness:1 alpha:1];
            break;
        }
        case LSColorSliderStyleSAT:
        {
            self.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", value, @"%"];
            self.thumbView.backgroundColor = [self colorWithSAT:value];
            break;
        }
        case LSColorSliderStyleCCT:
        {
            self.valueLabel.text = [NSString stringWithFormat:@"%.0fK", value * 100];
            self.thumbView.backgroundColor = [self colorWithCCT:value];
            break;
        }
        case LSColorSliderStyleGM:
        {
            if (value < 10) {
                self.valueLabel.text = [NSString stringWithFormat:@"G%.1f",(10 - value)/10.0];
            } else if (value > 10) {
                self.valueLabel.text = [NSString stringWithFormat:@"M%.1f", (value - 10)/10.0];
            } else {
                self.valueLabel.text = @"0.0";
            }
            self.thumbView.backgroundColor = [self colorWithGM:value];
            break;
        }
        default:
            break;
    }
}

- (void)drawRect:(CGRect)rect {
   
    CGFloat x = self.sliderView.frame.origin.x - (RADIUS - self.sliderView.frame.size.width/2);
    CGFloat y = CGRectGetMaxY(self.sliderView.frame);
    self.thumbView.frame = CGRectMake(x, y - RADIUS * 2, RADIUS * 2, RADIUS * 2);
    self.valueView.frame = CGRectMake(x, y, self.sliderView.frame.size.width, 0);
    
    [self setDefaultWithStyle];
    
    if (self.value >= self.maxValue) {
        self.value = self.maxValue;
    }
    if (self.value <= self.minValue) {
        self.value = self.minValue;
    }
    
    CGPoint point = [self locationWithValue:self.value];
    CGPoint location = [self.sliderView convertPoint:point toView:self];
    self.thumbView.center = location;
    self.valueView.frame = CGRectMake(CGRectGetMinX(self.sliderView.frame),
                                      location.y,
                                      self.sliderView.frame.size.width,
                                      self.sliderView.frame.size.height - point.y);
    [self setChangedValue:self.value];
}

- (void)setDefaultWithStyle {
    
    switch (self.style) {
        case LSColorSliderStyleINT:
        {
            self.valueLabel.text = @"0%";
            self.titleLabel.text = @"INT";
            self.valueView.hidden = NO;
            self.minValue = 0;
            self.maxValue = 100;
            self.thumbView.backgroundColor = LSRGB(216, 216, 216);
            break;
        }
        case LSColorSliderStyleSAT:
        {
            self.valueLabel.text = @"0%";
            self.titleLabel.text = @"SAT";
            self.valueView.hidden = YES;
            self.minValue = 0;
            self.maxValue = 100;
            self.thumbView.backgroundColor = [self colorWithSAT:0];
            if (self.satColor) {
                NSArray * colors = @[(id)self.satColor.CGColor, (id)UIColor.whiteColor.CGColor];
                [self setGradient:colors];
            } else {
                [self setGradient:[self satColors]];
            }
            break;
        }
        case LSColorSliderStyleHUE:
        {
            self.valueLabel.text = @"0°";
            self.titleLabel.text = @"HUE";
            self.valueView.hidden = YES;
            self.minValue = 0;
            self.maxValue = 360;
            self.thumbView.backgroundColor = [UIColor colorWithHue:0 saturation:1 brightness:1 alpha:1];
            [self setGradient:[self hueColors]];
            break;
        }
        case LSColorSliderStyleGM:
        {
            self.valueLabel.text = @"G1.0";
            self.titleLabel.text = @"G/M";
            self.valueView.hidden = YES;
            self.minValue = 0;
            self.maxValue = 20;
            self.thumbView.backgroundColor = [self colorWithGM:0];
            [self setGradient:[self gmColors]];
            break;
        }
        case LSColorSliderStyleCCT:
        {
            self.valueLabel.text = @"1600K";
            self.titleLabel.text = @"CCT";
            self.valueView.hidden = YES;
            self.minValue = 16;
            self.maxValue = 100;
            self.thumbView.backgroundColor = [self colorWithCCT:16];
            [self setGradient:[self cctColors]];
            break;
        }
        default:
            break;
    }
}

- (CGPoint)locationWithValue:(CGFloat)value {
    CGFloat offset = (value - self.minValue)/(self.maxValue-self.minValue);
    CGFloat y = offset * (CGRectGetHeight(self.sliderView.frame) - RADIUS * 2);
    return CGPointMake(CGRectGetWidth(self.sliderView.frame)/2, (CGRectGetHeight(self.sliderView.frame) - RADIUS) - y);
}


- (void)allowSendValue {
    self.allowSend = YES;
}
#pragma mark - 设置渐变颜色
- (void)setGradient:(NSArray *)colors {
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.frame = self.sliderView.bounds;
    gradientLayer.colors = colors;
    gradientLayer.startPoint = CGPointMake(0, 0);
    gradientLayer.endPoint = CGPointMake(0, 1);
    gradientLayer.cornerRadius = 8;
    [self.sliderView.layer addSublayer:gradientLayer];
}

#pragma mark - 默认数据
- (NSArray *)hueColors {
    return @[(id)[UIColor colorWithRed:1.0 green:0 blue:0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:0 blue:128.0/255.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:0 blue:1.0 alpha:1.0].CGColor,
             (id)[UIColor colorWithRed:128.0/255.0 green:0 blue:1.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:0 green:0 blue:1.0 alpha:1.0].CGColor,
             (id)[UIColor colorWithRed:0 green:128.0/255.0 blue:1.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:0 green:1.0 blue:1.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:0 green:1.0 blue:128.0/255.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:0 green:1.0 blue:0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:128.0/255.0 green:1.0 blue:0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:1.0 blue:0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:128.0/255.0 blue:0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:0 blue:0 alpha:1].CGColor];
}

- (NSArray *)cctColors {
    return @[(id)[UIColor colorWithRed:128.0/255.0 green:228.0/255.0 blue:254.0/255.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:254.0/255.0 green:200.0/255.0 blue:64.0/255.0 alpha:1].CGColor];
}

- (NSArray *)gmColors {
    return @[(id)[UIColor colorWithRed:1.0 green:0 blue:207.0/255.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:0.0 green:1.0 blue:0 alpha:1].CGColor];
}

- (NSArray *)satColors {
    return @[(id)[UIColor colorWithRed:0 green:164.0/255.0 blue:1.0 alpha:1].CGColor,
             (id)[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1].CGColor];
}

- (UIColor *)colorWithSAT:(NSInteger)sat {
    CGFloat k = 1.0*(sat-self.minValue)/(self.maxValue - self.minValue);
    if (self.satColor) {
        RGB rgb = MSRGBColorComponents(self.satColor);
        CGFloat red = (255 - k * (255-rgb.red * 255))/255.0;;
        CGFloat green = (255 - k * (255-rgb.green * 255))/255.0;
        CGFloat blue =  (255 - k * (255-rgb.blue * 255))/255.0;
        return  [UIColor colorWithRed:red green:green blue:blue alpha:1];
    } else {
        CGFloat red = (255 - k * (255-0))/255.0;;
        CGFloat green = (255 - k * (255-164))/255.0;
        CGFloat blue =  1;
        return  [UIColor colorWithRed:red green:green blue:blue alpha:1];
    }
    
}

/// 16~100
- (UIColor *)colorWithCCT:(NSInteger)cct {
    if (cct < CCT_VALUE) {
        CGFloat k = 1.0*(cct-16)/(CCT_VALUE - 16);
        CGFloat red = (254 + k * (255-254))/255.0;
        CGFloat green = (200 + k * (255-200))/255.0;
        CGFloat blue = (64 + k * (255-64))/255.0;;
        return [UIColor colorWithRed:red green:green blue:blue alpha:1];
    } else {
        CGFloat k = 1.0*(cct - CCT_VALUE)/(100 - CCT_VALUE);
        CGFloat red = (255 - k * (255-128))/255.0;;
        CGFloat green = (255 - k * (255-228))/255.0;
        CGFloat blue =  1;
        return [UIColor colorWithRed:red green:green blue:blue alpha:1];
    }
}

- (UIColor *)colorWithGM:(NSInteger)gm {
    NSInteger center = (self.maxValue - self.minValue) / 2;
    if (gm < center) {
        CGFloat k = 1.0*(gm-self.minValue)/(center - self.minValue);
        CGFloat red = (0 + k * (255-0))/255.0;
        CGFloat green = (255 + k * (255-255))/255.0;
        CGFloat blue = (0 + k * (255-0))/255.0;;
        return  [UIColor colorWithRed:red green:green blue:blue alpha:1];
    } else {
        CGFloat k = 1.0*(gm - center)/(self.maxValue - center);
        CGFloat red = (255 - k * (255-255))/255.0;;
        CGFloat green = (255 - k * (255-0))/255.0;
        CGFloat blue =  (255 - k * (255-207))/255.0;;
        return  [UIColor colorWithRed:red green:green blue:blue alpha:1];
    }
}
@end
