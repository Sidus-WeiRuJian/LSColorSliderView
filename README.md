# LSColorSliderView

### Using
#```
self.colorSlider = [[LSColorSliderView alloc] initWithStyle:LSColorSliderStyleSAT];
self.colorSlider.value = 120;
self.colorSlider.satColor = UIColor.orangeColor;
[self.view addSubview:self.colorSlider];
[self.colorSlider mas_makeConstraints:^(MASConstraintMaker *make) {
    make.center.equalTo(self.view);
    make.width.equalTo(@76);
    make.height.equalTo(@500);
}];
#```
