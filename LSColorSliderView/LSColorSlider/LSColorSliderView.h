//
//  LSColorSliderView.h
//  LSColorSliderView
//
//  Created by Choshim.Wei on 2021/3/9.
//  Copyright © 2021 Sidus Link. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, LSColorSliderStyle) {
    LSColorSliderStyleINT = 0,
    LSColorSliderStyleSAT,
    LSColorSliderStyleHUE,
    LSColorSliderStyleGM,
    LSColorSliderStyleCCT
};


@class LSColorSliderView;
NS_ASSUME_NONNULL_BEGIN

@protocol LSColorSliderViewDelegate <NSObject>

@optional
- (void)colorSliderView:(LSColorSliderView *)colorSliderView didOutputValue:(CGFloat)value;
- (void)colorSliderView:(LSColorSliderView *)colorSliderView didChangedValue:(CGFloat)value;
@end

@interface LSColorSliderView : UIView

- (instancetype)initWithStyle:(LSColorSliderStyle)style;

@property (nonatomic, weak) id<LSColorSliderViewDelegate> delegate;

@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIColor *satColor;
@property (nonatomic, assign) CGFloat value;

@end

NS_ASSUME_NONNULL_END
