#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 修改网络设置
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

#修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

echo '添加关机'
curl -fsSL  https://raw.githubusercontent.com/sirpdboy/other/master/patch/poweroff/poweroff.htm > ./feeds/luci/modules/luci-mod-admin-full/luasrc/view/admin_system/poweroff.htm 
curl -fsSL  https://raw.githubusercontent.com/sirpdboy/other/master/patch/poweroff/system.lua > ./feeds/luci/modules/luci-mod-admin-full/luasrc/controller/admin/system.lua

# 拉取仓库数据
git clone https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone https://github.com/vernesong/OpenClash package/OpenClash
git clone --depth=1 https://github.com/fw876/helloworld package/helloworld
git clone https://github.com/xiaorouji/openwrt-passwall package/passwall

# 设置主题
rm -rf feeds/luci/themes/luci-theme-bootstrap
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone -b 18.06 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
git clone -b 18.06 https://github.com/garypang13/luci-theme-edge package/luci-theme-edge
# 修改 argon 为默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 设置密码为空
sed -i '/CYXluq4wUazHjmCDBCqXF/d' package/lean/default-settings/files/zzz-default-settings

# 设置ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# 调整 x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}/g' package/lean/autocore/files/x86/autocore

# 去掉autocore-x86型号信息中的 CpuMark: xxxx Scores 显示
sed -i 's/ <%=luci.sys.exec("cat \/etc\/bench.log") or " "%>//g' package/lean/autocore/files/x86/index.htm

# 修改概览里时间显示为中文数字
sed -i 's/os.date()/os.date("%Y年%m月%d日") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")/g' package/lean/autocore/files/x86/index.htm

# 修改主机名字，把OpenWrt-j4125修改你喜欢的就行（不能纯数字或者使用中文）
sed -i '/uci commit system/i\uci set system.@system[0].hostname='OpenWrt-j4125'' package/lean/default-settings/files/zzz-default-settings

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

echo 'zzz-default-settings自定义'
# 网络配置信息，将从 zzz-default-settings 文件的第2行开始添加 
# 参考 https://github.com/coolsnowwolf/lede/blob/master/package/lean/default-settings/files/zzz-default-settings
# 先替换掉最后一行 exit 0 再追加自定义内容
sed -i '/.*exit 0*/c\# 自定义配置' package/lean/default-settings/files/zzz-default-settings
cat >> package/lean/default-settings/files/zzz-default-settings <<-EOF
#uci delete network.wan                                       # 删除wan口
#uci delete network.wan6                                      # 删除wan6口
#uci delete network.lan.type                                  # 关闭桥接选项(同下步互斥)
#uci set network.lan.type='bridge'                            # lan口桥接(单LAN口无需桥接,多LAN口必须桥接,同上步互斥)
#uci set network.lan.proto='static'                            # lan口静态IP
uci set network.lan.ipaddr='172.20.0.254'                     # IPv4 地址(openwrt后台地址)
uci set network.lan.netmask='255.255.0.0'                     # IPv4 子网掩码
uci set network.lan.gateway='172.20.0.1'                      # IPv4 网关
#uci set network.lan.broadcast='192.168.1.1'                  # IPv4 广播
uci set network.lan.dns='114.114.114.114 223.5.5.5 8.8.8.8'   # DNS(多个DNS要用空格分开)
#uci set network.lan.delegate='0'                             # 去掉LAN口使用内置的 IPv6 管理
#uci set network.lan.ifname='eth0'                            # 设置lan口物理接口为eth0
#uci set network.lan.ifname='eth0 eth1'                       # 设置lan口物理接口为eth0、eth1
#uci set network.lan.mtu='1492'                               # lan口mtu设置为1492
uci delete network.lan.ip6assign                             # 接口→LAN→IPv6 分配长度——关闭,恢复uci set network.lan.ip6assign='64'
uci commit network
uci delete dhcp.lan.ra                                        # 路由通告服务,设置为“已禁用”
uci delete dhcp.lan.ra_management                             # 路由通告服务,设置为“已禁用”
uci delete dhcp.lan.dhcpv6                                    # DHCPv6 服务,设置为“已禁用”
uci set dhcp.lan.ignore='1'                                   # 关闭DHCP功能
#uci set dhcp.@dnsmasq[0].filter_aaaa='1'                     # DHCP/DNS→高级设置→解析 IPv6 DNS 记录——禁止
#uci set dhcp.@dnsmasq[0].cachesize='0'                       # DHCP/DNS→高级设置→DNS 查询缓存的大小——设置为'0'
uci add dhcp domain
#uci set dhcp.@domain[0].name='openwrt'                       # 网络→主机名→主机目录——“openwrt”
#uci set dhcp.@domain[0].ip='192.168.123.5'                   # 对应IP解析——192.168.123.5
uci commit dhcp
uci delete firewall.@defaults[0].syn_flood                    # 防火墙→SYN-flood 防御——关闭;默认开启
uci set firewall.@defaults[0].fullcone='1'                    # 防火墙→FullCone-NAT——启用;默认关闭
uci commit firewall

exit 0
EOF

#make menuconfig
#然后：
#make defconfig
#./scripts/diffconfig.sh > seed.config
#cat seed.config


sed -i "9s/1.1.1.1/8.8.8.8/" package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config # 修改DNS为8.8.8.8
#sed -i "77s/^/        /" package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config # 代码前加空格
sed -i "s/option enabled '0'/option enabled '1'/g" package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config # 节点总开关（开启，默认关闭）
#sed -i "s/option start_delay '60'/option start_delay '6'/g" package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config
#sed -i "s/option when_chnroute_default_dns 'direct'/option chinadns_ng '1'/g" package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config
sed -i "s/option start_delay '60'/option start_delay '10'/" package/passwall/luci-app-passwall/root/usr/share/passwall/0_default_config

#取消掉feeds.conf.default文件里面的helloworld的#注释
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default  #使用源码自带ShadowSocksR Plus+出国软件
