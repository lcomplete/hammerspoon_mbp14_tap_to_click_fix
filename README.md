# fix macbook pro 14 command + tap issue

# update

monterey 12.5 had fixed this issue.

---

issue detail:

- [Tap-to-click issues on B9 and 10 (and now Monterey release)](https://forums.macrumors.com/threads/tap-to-click-issues-on-b9-and-10-and-now-monterey-release.2317279/)
- [macbook pro 14 寸 command + 轻点触摸板问题，历时 9 个月 apple 仍未解决](https://www.v2ex.com/t/862643)

# How To Use

- install hammerspoon
- click 「Open Config」 menu
- copy the code in init.lua to config
- move the `Spoons` directory to `.hammerspoon`
- Reload Config

# Known issues

- Hammerspoon `0.9.97` can't receive `getTouches()` event data after system sleep, should restart hammerspoon to make it work again.
