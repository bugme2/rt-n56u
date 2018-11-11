### 编译说明 ###

* 安装依赖包
```
sudo apt-get update
sudo apt-get install autoconf automake autopoint bison build-essential flex gawk gettext git gperf libtool pkg-config zlib1g-dev libgmp3-dev libmpc-dev libmpfr-dev texinfo python-docutils
```
* 克隆源码
```
cd /opt
git clone --depth=1 https://github.com/bugme2/rt-n56u.git
```
* 编译工具链
```
cd /opt/rt-n56u/toolchain-mipsel
sudo ./clean_sources
sudo ./build_toolchain
```

* 清理代码树并开始编译
```
cd /opt/rt-n56u/trunk
sudo ./clear_tree
sudo ./build_firmware k2p
#注：脚本第一个参数为路由型号
```
