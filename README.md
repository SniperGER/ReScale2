# Re:Scale 2
## Change your resolution safely (Team FESTIVAL, Free)

Have you ever wanted to change the screen resolution of your iPhone, iPad or iPod touch, but people told you to not mess with system files or your resolution as it could send your device into an actual boot loop? With Re:Scale 2 you can. It's safe to use and the resolution is only applied while you're jailbroken.

Re:Scale 2 supports every resolution of devices that run iOS 9 or later:

- iPhone 4s (3.5", @2x)
- iPhone 5/5s/5c/SE (4", @2x)
- iPhone 6/6s/7/8, SE 2020 (4.7", @2x)
- iPhone 6/6s/7/8 Plus (5.5", @3x)
- iPhone X/XS, 11 Pro (5.8", @3x)
- iPhone XR, 11 (6.1", @2x)
- iPhone XS Max, 11 Pro Max (6.5", @3x)
- iPhone 12/12 Pro (6.1", @3x)
- iPhone 12 mini (5.4", @3x)
- iPhone 12 Pro Max (6.7", @3x)
- iPad 2, iPad mini (9.7", @1x)
- iPad 3/4/5/6, Air 1/2, mini 2/3/4/5, Pro (9.7", @2x)
- iPad 7/8 (10.2", @2x)
- iPad Air 3, Pro (10.5", @2x)
- iPad Air 4 (10.9", @2x)
- iPad Pro (11", @2x)
- iPad Pro (12.9", @2x)

_Note: Not every resolution may be compatible with every version of iOS._

__What makes Re:Scale 2 different from tweaks like Upscale/Re:Scale 1, LittleBrother or SystemInfo?__

- Upscale (and Re:Scale 1) persisted the changed resolution in a file that is read by iOS even when not jailbroken, which could lead to a boot loop if an incompatible resolution is applied. Also, this tweak is hasn't really been updated since it released back in the days of iOS 8, so it only includes resolutions from iPhone 4s up to iPhone 6 Plus.
- LittleBrother was basically only supported from iOS 8 to iOS 10 and hasn't received any update ever since. It was a paid release, and only allowed the user to choose between 3 Display Zoom modes on iPhone 6 and 6s.
- System Info's resolution changing portion works similar to Upscale, only that the persisted change is reverted after applying a resolution, so you have to apply this resolution manually every time after reboot.

Re:Scale 2 works similar to LittleBrother as it hooks into the process responsible for doing "framebuffer magic" (aka `backboardd`). Instead of loading the resolution from `com.apple.iokit.IOMobileGraphicsFamily.plist`, the values are overriden by Re:Scale 2 at runtime, so the resolution is only applied while your jailbreak is active. Additionally, if you're running iOS 11 or later and get the "Red Status Bar" bug (`😳 rdar:45025538`), you can set an appropriate Status Bar right in the preferences pane.

__If you have set a higher resolution and your device is rebooted, it is recommended to rejailbreak with tweaks disabled ("Safe Mode" in checkra1n) and disable Re:Scale 2 using iCleaner before rejailbreaking again with tweaks enabled.__

---

__Currently known issues:__

- You may experience a higher battery drain when using a higher resolution.