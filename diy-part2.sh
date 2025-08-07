#!/bin/bash
#===============================================
# Description: DIY script
# File name: diy-script.sh
# Lisence: MIT
# Author: P3TERX
# Blog: https://p3terx.com
#===============================================

# enable rk3568 model adc keys
cp -f $GITHUB_WORKSPACE/configfiles/adc-keys.txt adc-keys.txt
! grep -q 'adc-keys {' package/boot/uboot-rk35xx/src/arch/arm/dts/rk3568-easepi.dts && sed -i '/\"rockchip,rk3568\";/r adc-keys.txt' package/boot/uboot-rk35xx/src/arch/arm/dts/rk3568-easepi.dts

# update ubus git HEAD
cp -f $GITHUB_WORKSPACE/configfiles/ubus_Makefile package/system/ubus/Makefile

# 近期istoreos网站文件服务器不稳定，临时增加一个自定义下载网址
sed -i "s/push @mirrors, 'https:\/\/mirror2.openwrt.org\/sources';/&\\npush @mirrors, 'https:\/\/github.com\/xiaomeng9597\/files\/releases\/download\/iStoreosFile';/g" scripts/download.pl


# 修改内核配置文件
sed -i "/.*CONFIG_ROCKCHIP_RGA2.*/d" target/linux/rockchip/rk35xx/config-5.10
# sed -i "/# CONFIG_ROCKCHIP_RGA2 is not set/d" target/linux/rockchip/rk35xx/config-5.10
# sed -i "/CONFIG_ROCKCHIP_RGA2_DEBUGGER=y/d" target/linux/rockchip/rk35xx/config-5.10
# sed -i "/CONFIG_ROCKCHIP_RGA2_DEBUG_FS=y/d" target/linux/rockchip/rk35xx/config-5.10
# sed -i "/CONFIG_ROCKCHIP_RGA2_PROC_FS=y/d" target/linux/rockchip/rk35xx/config-5.10




# 替换dts文件
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3566-jp-tvbox.dts target/linux/rockchip/dts/rk3568/rk3566-jp-tvbox.dts

cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3566-panther-x2.dts target/linux/rockchip/dts/rk3568/rk3566-panther-x2.dts

cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-dg-nas-lite-core.dtsi target/linux/rockchip/dts/rk3568/rk3568-dg-nas-lite-core.dtsi
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-dg-nas-lite.dts target/linux/rockchip/dts/rk3568/rk3568-dg-nas-lite.dts

cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-mrkaio-m68s-core.dtsi target/linux/rockchip/dts/rk3568/rk3568-mrkaio-m68s-core.dtsi
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-mrkaio-m68s.dts target/linux/rockchip/dts/rk3568/rk3568-mrkaio-m68s.dts
cp -f $GITHUB_WORKSPACE/configfiles/dts/rk3568-mrkaio-m68s-plus.dts target/linux/rockchip/dts/rk3568/rk3568-mrkaio-m68s-plus.dts



# 修改uhttpd配置文件，启用nginx
# sed -i "/.*uhttpd.*/d" .config
# sed -i '/.*\/etc\/init.d.*/d' package/network/services/uhttpd/Makefile
# sed -i '/.*.\/files\/uhttpd.init.*/d' package/network/services/uhttpd/Makefile
sed -i "s/:80/:81/g" package/network/services/uhttpd/files/uhttpd.config
sed -i "s/:443/:4443/g" package/network/services/uhttpd/files/uhttpd.config
cp -a $GITHUB_WORKSPACE/configfiles/etc/* package/base-files/files/etc/
# ls package/base-files/files/etc/




# 轮询检查ubus服务是否崩溃，崩溃就重启ubus服务，只针对rk3566机型，如黑豹X2和荐片TV盒子。
cp -f $GITHUB_WORKSPACE/configfiles/httpubus package/base-files/files/etc/init.d/httpubus
cp -f $GITHUB_WORKSPACE/configfiles/ubus-examine.sh package/base-files/files/bin/ubus-examine.sh
chmod 755 package/base-files/files/etc/init.d/httpubus
chmod 755 package/base-files/files/bin/ubus-examine.sh



# 集成黑豹X2和荐片TV盒子WiFi驱动，默认不启用WiFi
cp -a $GITHUB_WORKSPACE/configfiles/firmware/* package/firmware/
cp -f $GITHUB_WORKSPACE/configfiles/opwifi package/base-files/files/etc/init.d/opwifi
chmod 755 package/base-files/files/etc/init.d/opwifi
# sed -i "s/wireless.radio\${devidx}.disabled=1/wireless.radio\${devidx}.disabled=0/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh



# 集成CPU性能跑分脚本
cp -a $GITHUB_WORKSPACE/configfiles/coremark/* package/base-files/files/bin/
chmod 755 package/base-files/files/bin/coremark
chmod 755 package/base-files/files/bin/coremark.sh


# 定时限速插件
git clone --depth=1 https://github.com/sirpdboy/luci-app-eqosplus package/luci-app-eqosplus


# 添加imb3588
echo "
define Device/yx_imb3588
\$(call Device/rk3588)
  DEVICE_VENDOR := YX
  DEVICE_MODEL := IMB3588
  DEVICE_PACKAGES := kmod-r8125 kmod-nvme kmod-scsi-core kmod-hwmon-pwmfan kmod-thermal kmod-rkwifi-bcmdhd-pcie rkwifi-firmware-ap6275p
  SUPPORTED_DEVICES += yx,imb3588
  DEVICE_DTS := rk3588-yx-imb3588
endef
TARGET_DEVICES += yx_imb3588
" >>  target/linux/rockchip/image/rk35xx.mk

sed -i "s/armsom,sige7-v1|/yx,imb3588|armsom,sige7-v1|/g" target/linux/rockchip/rk35xx/base-files/etc/board.d/02_network

# 添加a588
echo "
define Device/dc_a588
\$(call Device/rk3588)
  DEVICE_VENDOR := DC
  DEVICE_MODEL := A588
  DEVICE_PACKAGES := kmod-r8125 kmod-nvme kmod-scsi-core kmod-hwmon-pwmfan kmod-thermal kmod-rkwifi-bcmdhd-pcie rkwifi-firmware-ap6275p
  SUPPORTED_DEVICES += dc,a588
  DEVICE_DTS := rk3588-dc-a588
endef
TARGET_DEVICES += dc_a588
" >>  target/linux/rockchip/image/rk35xx.mk

sed -i "s/armsom,sige7-v1|/yx,imb3588|dc,a588|armsom,sige7-v1|/g" target/linux/rockchip/rk35xx/base-files/etc/board.d/02_network

echo " 
CONFIG_TARGET_DEVICE_rockchip_rk35xx_DEVICE_yx_imb3588=y
CONFIG_TARGET_DEVICE_rockchip_rk35xx_DEVICE_dc-a588=y
" >>  .config

# 添加dts
cp -f $GITHUB_WORKSPACE/configfiles/rk3588-yx-imb3588.dts target/linux/rockchip/dts/rk3588/rk3588-yx-imb3588.dts
cp -f $GITHUB_WORKSPACE/configfiles/rk3588-dc-a588.dts target/linux/rockchip/dts/rk3588/rk3588-dc-a588.dts

#添加qmodem
git clone --depth=1 -b main https://github.com/FUjr/QModem package/modem
echo "
CONFIG_PACKAGE_luci-i18n-qmodem-zh-cn=y
CONFIG_PACKAGE_luci-app-qmodem=y
CONFIG_PACKAGE_luci-app-modem=n
CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_vendor-qmi-wwan=y
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_generic-qmi-wwan is not set
CONFIG_PACKAGE_luci-app-qmodem_USE_TOM_CUSTOMIZED_QUECTEL_CM=y
# CONFIG_PACKAGE_luci-app-qmodem_USING_QWRT_QUECTEL_CM_5G is not set
# CONFIG_PACKAGE_luci-app-qmodem_USING_NORMAL_QUECTEL_CM is not set
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ADD_PCI_SUPPORT is not set
# CONFIG_PACKAGE_luci-app-qmodem_INCLUDE_ADD_QFIREHOSE_SUPPORT is not set
CONFIG_PACKAGE_luci-app-qmodem-hc=y
CONFIG_PACKAGE_luci-app-qmodem-mwan=y
CONFIG_PACKAGE_luci-app-qmodem-sms=y
CONFIG_PACKAGE_luci-app-qmodem-ttl=y
" >> .config 

# 更换golong 1.24
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing-box*}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/v2ray-geodata
git clone https://github.com/sbwml/packages_lang_golang -b 24.x feeds/packages/lang/golang

# 科学上网插件
git clone --depth=1 -b master https://github.com/fw876/helloworld package/luci-app-ssr-plus
git clone --depth=1 -b main https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 -b main https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
git clone --depth=1 -b main https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2
git_sparse_clone dev https://github.com/vernesong/OpenClash luci-app-openclash

# 添加config
echo " 
#科学上网
CONFIG_PACKAGE_luci-app-passwall=y

#
# Configuration
#
#CONFIG_PACKAGE_luci-app-passwall_Iptables_Transparent_Proxy=y
#CONFIG_PACKAGE_luci-app-passwall_Nftables_Transparent_Proxy=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Haproxy=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Hysteria=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_NaiveProxy=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Client=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Rust_Server=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Client=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR_Libev_Server=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_SingBox=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan_Plus=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_tuic_client=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Geodata=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y
#CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray_Plugin=y
# end of Configuration

CONFIG_PACKAGE_luci-app-passwall2=y

#
# Configuration
#
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_IPv6_Nat=y
#CONFIG_PACKAGE_luci-app-passwall2_Iptables_Transparent_Proxy=y
#CONFIG_PACKAGE_luci-app-passwall2_Nftables_Transparent_Proxy=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Haproxy=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Hysteria=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_NaiveProxy=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Client=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Libev_Server=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Client=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Shadowsocks_Rust_Server=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Client=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_ShadowsocksR_Libev_Server=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_SingBox=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_tuic_client=y
#CONFIG_PACKAGE_luci-app-passwall2_INCLUDE_V2ray_Plugin=y
# end of Configuration

CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y
CONFIG_PACKAGE_luci-i18n-passwall2-zh-cn=y

CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_libustream-openssl=y
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_PACKAGE_libustream-wolfssl is not set
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Client=y
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Client is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client is not set
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Server=y
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Server is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_NONE_V2RAY is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_V2ray is not set
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ChinaDNS_NG=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_MosDNS=y
" >> .config
" >> .config
