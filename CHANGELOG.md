# Changelog

## 1.0.0 (2025-08-13)


### Features

* add configurable global winblend and make group_configs's winblend overridable ([#19](https://github.com/y3owk1n/notifier.nvim/issues/19)) ([54d3a3d](https://github.com/y3owk1n/notifier.nvim/commit/54d3a3dfa245177a21cdfe7b6c7bae940de1db7a))
* add configurable resize debounce ([#30](https://github.com/y3owk1n/notifier.nvim/issues/30)) ([e14ba0d](https://github.com/y3owk1n/notifier.nvim/commit/e14ba0d869e2e9b7b437a0220f50fa9fb517819a))
* add width configuration ([#28](https://github.com/y3owk1n/notifier.nvim/issues/28)) ([095316f](https://github.com/y3owk1n/notifier.nvim/commit/095316fcbca82bfe290129cab5ebaa827c5d67e7))
* allow `timeout` to be value `0`, and it will be sticky unless dismissed ([#12](https://github.com/y3owk1n/notifier.nvim/issues/12)) ([63d00de](https://github.com/y3owk1n/notifier.nvim/commit/63d00ded1958990266786dcbf0978b103613966e))
* **animation:** add enter animation ([#16](https://github.com/y3owk1n/notifier.nvim/issues/16)) ([0a753e5](https://github.com/y3owk1n/notifier.nvim/commit/0a753e5c9c4150b085ec53da53c0dc95e0e3c16c))
* **animation:** add simple fade out animation for notifications lines and window ([#13](https://github.com/y3owk1n/notifier.nvim/issues/13)) ([c0343d8](https://github.com/y3owk1n/notifier.nvim/commit/c0343d805ee691a45047f8086e3dd8cfb5a6dad1))
* **animation:** support animation for dismissal ([#17](https://github.com/y3owk1n/notifier.nvim/issues/17)) ([b85714f](https://github.com/y3owk1n/notifier.nvim/commit/b85714fceec663757cf14d83f8162d850782a632))
* **groups:** add more groups placement ([#18](https://github.com/y3owk1n/notifier.nvim/issues/18)) ([149e5c4](https://github.com/y3owk1n/notifier.nvim/commit/149e5c4a433674bd139722e5619b5c7314696d06))
* init project from my config ([#1](https://github.com/y3owk1n/notifier.nvim/issues/1)) ([724d7da](https://github.com/y3owk1n/notifier.nvim/commit/724d7dad476621322a4e5f9c27e49c44d95a4aea))


### Bug Fixes

* add pcall for some vim api ([#33](https://github.com/y3owk1n/notifier.nvim/issues/33)) ([b21c2b0](https://github.com/y3owk1n/notifier.nvim/commit/b21c2b0dbffc133d7a6cd6894a3a5a19b416e233))
* **animation:** respect animation set on user config ([#15](https://github.com/y3owk1n/notifier.nvim/issues/15)) ([652df07](https://github.com/y3owk1n/notifier.nvim/commit/652df073f1450923f0c5c5c59255b709ec077dd9))
* better default row for `center` and `bottom` groups ([#34](https://github.com/y3owk1n/notifier.nvim/issues/34)) ([93e51bd](https://github.com/y3owk1n/notifier.nvim/commit/93e51bd8eb1bc5cafcd610ab8badb018229e7abd))
* **ci:** move docs to its own workflow ([#8](https://github.com/y3owk1n/notifier.nvim/issues/8)) ([c7a3992](https://github.com/y3owk1n/notifier.nvim/commit/c7a39924fe29c1c0a007c62c4cd5bfb647d6994b))
* **config:** set default row to 0 for top-center ([#24](https://github.com/y3owk1n/notifier.nvim/issues/24)) ([4c7b5dd](https://github.com/y3owk1n/notifier.nvim/commit/4c7b5dd193a91be286ded443d6988da2b7452cad))
* **demo:** add a rainbow text to demo individual hls ([#36](https://github.com/y3owk1n/notifier.nvim/issues/36)) ([79cd28c](https://github.com/y3owk1n/notifier.nvim/commit/79cd28c0c54b00adf4d3645cb5e42cd44fffff3c))
* **demo:** do not timeout on step 2 to avoid flickering ([#35](https://github.com/y3owk1n/notifier.nvim/issues/35)) ([35c5b36](https://github.com/y3owk1n/notifier.nvim/commit/35c5b366f03af19bb4130d34a635e0af7804cf51))
* do not clear `State.groups` on dismiss ([#29](https://github.com/y3owk1n/notifier.nvim/issues/29)) ([ebc9237](https://github.com/y3owk1n/notifier.nvim/commit/ebc923790d2a8d888c594edd9f6c8351b4a3e7a6))
* **doc:** update doc annotation and avoid label duplication ([#11](https://github.com/y3owk1n/notifier.nvim/issues/11)) ([c6e8b56](https://github.com/y3owk1n/notifier.nvim/commit/c6e8b5632e55c700844df7ea94827c162b29269b))
* ensure set notifications to `_expired=true` when dismissing ([#32](https://github.com/y3owk1n/notifier.nvim/issues/32)) ([ee27251](https://github.com/y3owk1n/notifier.nvim/commit/ee272516c587410d08d392305647b276a544d0f8))
* **healthcheck:** wrong import of modules ([#10](https://github.com/y3owk1n/notifier.nvim/issues/10)) ([f57e1dc](https://github.com/y3owk1n/notifier.nvim/commit/f57e1dc4ad326a6b33e1f470864fbcc16106d9c0))
* improve formatter detection and replacement ([#20](https://github.com/y3owk1n/notifier.nvim/issues/20)) ([dc12ee1](https://github.com/y3owk1n/notifier.nvim/commit/dc12ee10d2d83017efadce6569db452d48e74dd5))
* **notify:** ensure to reset expired flag when new notification comes in ([#5](https://github.com/y3owk1n/notifier.nvim/issues/5)) ([835c245](https://github.com/y3owk1n/notifier.nvim/commit/835c2450a9f05cd8f8b3a0e01d331431c6700bf0))
* only use previous msg if no msg passed ([#21](https://github.com/y3owk1n/notifier.nvim/issues/21)) ([b8f8344](https://github.com/y3owk1n/notifier.nvim/commit/b8f8344f48e948d5684aa368c3ea43619fdfefb4))
* refactor code for better maintainability and clarity ([#9](https://github.com/y3owk1n/notifier.nvim/issues/9)) ([bce4042](https://github.com/y3owk1n/notifier.nvim/commit/bce40426e67d855ab527fc8052ee6fe194751f8e))
* **setup:** ensure only single setup being called ([#4](https://github.com/y3owk1n/notifier.nvim/issues/4)) ([cfa39e1](https://github.com/y3owk1n/notifier.nvim/commit/cfa39e1e70da37f4957971079e525d71af5dcf7c))
* use function based for `row` and `col` configuration for better recalculation ([#31](https://github.com/y3owk1n/notifier.nvim/issues/31)) ([a509abd](https://github.com/y3owk1n/notifier.nvim/commit/a509abd9befd7147ef09b244647335c2cacb0d58))
