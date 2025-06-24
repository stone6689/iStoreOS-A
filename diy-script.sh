#!/bin/bash

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

function merge_package() {
    # 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
    # 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
    if [[ $# -lt 3 ]]; then
        echo "Syntax error: [$#] [$*]" >&2
        return 1
    fi
    trap 'rm -rf "$tmpdir"' EXIT
    branch="$1" curl="$2" target_dir="$3" && shift 3
    rootdir="$PWD"
    localdir="$target_dir"
    [ -d "$localdir" ] || mkdir -p "$localdir"
    tmpdir="$(mktemp -d)" || exit 1
    git clone -b "$branch" --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
    cd "$tmpdir"
    git sparse-checkout init --cone
    git sparse-checkout set "$@"
    # 使用循环逐个移动文件夹
    for folder in "$@"; do
        mv -f "$folder" "$rootdir/$localdir"
    done
    cd "$rootdir"
}

# 更新 golang 1.24 版本
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# 必要的库
# git clone --depth=1 -b main https://github.com/linkease/istore-packages package/istore-packages
# git clone --depth=1 -b dev https://github.com/jjm2473/luci-app-diskman package/diskman
# git clone --depth=1 -b dev6 https://github.com/jjm2473/OpenAppFilter package/oaf
# git clone --depth=1 -b master https://github.com/linkease/nas-packages package/nas-packages
# git clone --depth=1 -b main https://github.com/linkease/nas-packages-luci package/nas-packages-luci
# git clone --depth=1 -b main https://github.com/jjm2473/openwrt-apps package/openwrt-apps

# 移除要替换的包
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box}
rm -rf package/diy/luci-app-ota

# 科学上网插件
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall
git clone --depth=1 https://github.com/nikkinikki-org/OpenWrt-nikki package/nikki
git clone https://github.com/sbwml/openwrt_helloworld package/helloworld

#OTA
git_sparse_clone main https://github.com/stone6689/op-ota luci-app-ota
git_sparse_clone main https://github.com/zijieKwok/github-ota fw_download_tool
git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
git clone https://github.com/sbwml/luci-app-mentohust package/mentohust

### 个性化设置
sed -i 's/iStoreOS/StoneOS/' package/istoreos-files/files/etc/board.d/10_system
sed -i 's/192.168.100.1/192.168.100.1/' package/istoreos-files/Makefile
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 加入作者信息
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='iStoreOS-$(date +%Y%m%d)'/g"  package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' By Stone'/g" package/base-files/files/etc/openwrt_release

# 更换默认背景
cp -f $GITHUB_WORKSPACE/images/bg1.jpg feeds/third/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg

# iStoreOS-settings
git clone --depth=1 -b main https://github.com/stone6689/default-settings package/default-settings

# 更新Feeds
./scripts/feeds update -a
./scripts/feeds install -a

# TTYD
# sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/root/usr/share/luci/menu.d/luci-app-passwall.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-homeproxy/root/usr/share/luci/menu.d/luci-app-homeproxy.json
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-openclash/root/usr/share/luci/menu.d/luci-app-openclash.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-nikki/root/usr/share/luci/menu.d/luci-app-nikki.json
# 调整PassWall到VPN菜单
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/controller/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/passwall/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/model/cbi/passwall/client/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/model/cbi/passwall/server/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/app_update/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/socks_auto_switch/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/global/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/haproxy/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/log/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/node_list/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/rule/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-passwall/luasrc/view/passwall/server/*.htm

# 调整OpenClash到VPN菜单
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-openclash/luasrc/controller/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-openclash/luasrc/model/cbi/openclash/*.lua
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-openclash/luasrc/view/openclash/*.htm
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-openclash/luasrc/*.lua

# 调整Nikki到VPN菜单
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-nikki/htdocs/luci-static/resources/tools/*.js
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-nikki/htdocs/luci-static/resources/view/nikki/*.js

# 调整HomeProxy到VPN菜单
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-homeproxy/htdocs/luci-static/resources/*.js
sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/*.js
