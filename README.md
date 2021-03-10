# LSColorSliderView

### Using
```
LSColorSliderView *colorSlider = [[LSColorSliderView alloc] initWithStyle:LSColorSliderStyleSAT];
colorSlider.value = 100;
colorSlider.satColor = UIColor.orangeColor;
[self.view addSubview:self.colorSlider];
[colorSlider mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(self.view);
    make.width.equalTo(@76);
    make.height.equalTo(@500);
}];
```

