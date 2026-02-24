#!/bin/bash
# ==================================================
# V2Ray Manager - Installer Script
# نظام متكامل لإدارة V2Ray (X-UI) مع SSH والمنافذ
# ==================================================

# الألوان للتنسيق
R='\033[1;31m'     # أحمر
G='\033[1;32m'     # أخضر
Y='\033[1;33m'     # أصفر
B='\033[1;34m'     # أزرق
P='\033[1;35m'     # بنفسجي
C='\033[1;36m'     # سماوي
W='\033[1;37m'     # أبيض
NC='\033[0m'       # بدون لون

# التحقق من الصلاحيات
if [[ $EUID -ne 0 ]]; then
   echo -e "${R}❌ يجب تشغيل السكريبت بصلاحيات الروت (root)${NC}"
   exit 1
fi

# المسارات
INSTALL_DIR="/usr/local/v2ray"
MENU_SCRIPT="$INSTALL_DIR/menu.sh"
SSH_SCRIPT="$INSTALL_DIR/ssh.sh"
BIN_PATH="/usr/local/bin/v2ray"
DB_DIR="/etc/v2ray"
DB_FILE="$DB_DIR/ports.db"
LOG_FILE="/var/log/v2ray-install.log"

# ==================================================
# دوال مساعدة
# ==================================================
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

show_banner() {
    clear
    echo -e "${P}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${P}║     ${W}🚀 V2Ray Manager - نظام إدارة V2Ray المتكامل${P}        ║${NC}"
    echo -e "${P}║          ${C}نسخة كاملة - X-UI + SSH + منافذ${P}               ║${NC}"
    echo -e "${P}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_step() {
    echo -e "${B}[${G}✓${B}]${NC} $1"
}

show_error() {
    echo -e "${R}❌ $1${NC}"
    log "ERROR: $1"
}

show_success() {
    echo -e "${G}✅ $1${NC}"
    log "SUCCESS: $1"
}

show_warning() {
    echo -e "${Y}⚠️ $1${NC}"
}

# ==================================================
# التحقق من المتطلبات
# ==================================================
check_system() {
    show_step "${W}التحقق من النظام...${NC}"
    
    # التحقق من نظام التشغيل
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        show_error "لا يمكن التعرف على نظام التشغيل"
        exit 1
    fi
    
    echo -e "   • نظام التشغيل: ${C}$OS $VER${NC}"
    
    # التحقق من الإصدار
    if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
        show_error "النظام غير مدعوم. يستخدم Ubuntu أو Debian فقط"
        exit 1
    fi
    
    # التحقق من الإصدار
    if [[ "$OS" == "ubuntu" && ${VER%%.*} -lt 18 ]]; then
        show_error "Ubuntu 18.04 أو أحدث مطلوب"
        exit 1
    fi
    
    if [[ "$OS" == "debian" && ${VER%%.*} -lt 10 ]]; then
        show_error "Debian 10 أو أحدث مطلوب"
        exit 1
    fi
}

# ==================================================
# تحديث النظام
# ==================================================
update_system() {
    show_step "${W}تحديث النظام...${NC}"
    
    apt-get update -y > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        show_error "فشل تحديث النظام"
        exit 1
    fi
    
    apt-get upgrade -y > /dev/null 2>&1
    
    show_success "تم تحديث النظام"
}

# ==================================================
# تثبيت المتطلبات
# ==================================================
install_dependencies() {
    show_step "${W}تثبيت المتطلبات الأساسية...${NC}"
    
    # قائمة الحزم المطلوبة
    PACKAGES="curl wget ufw git unzip zip tar build-essential net-tools lsof jq sqlite3 certbot python3-certbot-nginx nginx screen htop iftop nload vnstat"
    
    apt-get install -y $PACKAGES > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        show_success "تم تثبيت جميع المتطلبات"
    else
        show_error "فشل تثبيت بعض المتطلبات"
        exit 1
    fi
}

# ==================================================
# إعداد SSH
# ==================================================
setup_ssh() {
    show_step "${W}إعداد SSH...${NC}"
    
    # نسخ احتياطي
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    
    # إعدادات SSH المحسنة
    cat > /etc/ssh/sshd_config << 'EOF'
# V2Ray Manager - SSH Configuration
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# مصادقة
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# أمان
LoginGraceTime 2m
MaxAuthTries 3
MaxSessions 10
MaxStartups 10:30:60

# Keep alive
ClientAliveInterval 60
ClientAliveCountMax 3
TCPKeepAlive yes

# بيئة
AcceptEnv LANG LC_*
X11Forwarding no
PrintMotd no

# Banner
Banner /etc/ssh/banner
EOF

    # إنشاء شعار SSH
    cat > /etc/ssh/banner << 'EOF'
╔══════════════════════════════════════════════════╗
║          🚀 V2Ray Manager - V2Ray Server        ║
║══════════════════════════════════════════════════║
║  • تم تجهيز السيرفر بنجام                        ║
║  • استخدم الأمر: v2ray                          ║
║  • X-UI Panel: http://IP:54321                  ║
║  • للدعم: https://t.me/hgmds2                          ║
╚══════════════════════════════════════════════════╝
EOF

    # إعادة تشغيل SSH
    systemctl restart sshd > /dev/null 2>&1 || systemctl restart ssh > /dev/null 2>&1
    
    show_success "تم إعداد SSH بنجاح"
}

# ==================================================
# إعداد الفايروول
# ==================================================
setup_firewall() {
    show_step "${W}إعداد الفايروول (UFW)...${NC}"
    
    # إعادة ضبط UFW
    ufw --force disable > /dev/null 2>&1
    ufw --force reset > /dev/null 2>&1
    
    # ضبط القواعد الافتراضية
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    
    # فتح المنافذ الأساسية
    ufw allow 22/tcp > /dev/null 2>&1        # SSH
    ufw allow 54321/tcp > /dev/null 2>&1     # X-UI Panel
    
    # منافذ V2Ray الشائعة
    V2RAY_PORTS="443 80 8080 8443 2053 2083 2087 2096 8880 9999"
    for port in $V2RAY_PORTS; do
        ufw allow $port/tcp > /dev/null 2>&1
        ufw allow $port/udp > /dev/null 2>&1
    done
    
    # تمكين UFW
    echo "y" | ufw --force enable > /dev/null 2>&1
    
    show_success "تم إعداد الفايروول وفتح المنافذ"
}

# ==================================================
# تثبيت X-UI
# ==================================================
install_xui() {
    show_step "${W}تثبيت X-UI Panel...${NC}"
    
    # تحميل وتثبيت X-UI
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # ضبط الإعدادات الافتراضية
        /usr/local/x-ui/x-ui setting -username admin -password admin123 -port 54321 > /dev/null 2>&1
        
        # حفظ معلومات الدخول
        cat > "$INSTALL_DIR/xui.info" << EOF
╔══════════════════════════════════════════╗
║     ✅ X-UI Panel - معلومات الدخول      ║
╠══════════════════════════════════════════╣
║                                         ║
║  الرابط: http://$(curl -s ifconfig.me):54321  ║
║  المستخدم: admin                        ║
║  كلمة المرور: admin123                   ║
║  المنفذ: 54321                          ║
║                                         ║
║  ⚠️  غير كلمة المرور بعد الدخول         ║
║                                         ║
╚══════════════════════════════════════════╝
EOF
        
        # إعادة تشغيل X-UI
        systemctl restart x-ui > /dev/null 2>&1
        
        show_success "تم تثبيت X-UI بنجاح"
    else
        show_error "فشل تثبيت X-UI"
        exit 1
    fi
}

# ==================================================
# إنشاء قاعدة البيانات
# ==================================================
create_database() {
    show_step "${W}إنشاء قاعدة بيانات المنافذ...${NC}"
    
    mkdir -p "$DB_DIR"
    
    cat > "$DB_FILE" << EOF
# V2Ray Manager - Ports Database
# التنسيق: port:protocol:description:status:date
443:tcp/udp:HTTPS - V2Ray TLS:active:$(date +%Y-%m-%d)
80:tcp/udp:HTTP - V2Ray :active:$(date +%Y-%m-%d)
54321:tcp:X-UI Panel:active:$(date +%Y-%m-%d)
22:tcp:SSH:active:$(date +%Y-%m-%d)
8080:tcp/udp:V2Ray WebSocket:active:$(date +%Y-%m-%d)
8443:tcp/udp:V2Ray gRPC:active:$(date +%Y-%m-%d)
2053:tcp/udp:V2Ray TLS:active:$(date +%Y-%m-%d)
2083:tcp/udp:V2Ray TLS:active:$(date +%Y-%m-%d)
2087:tcp/udp:V2Ray TLS:active:$(date +%Y-%m-%d)
2096:tcp/udp:V2Ray TLS:active:$(date +%Y-%m-%d)
8880:tcp/udp:V2Ray WebSocket:active:$(date +%Y-%m-%d)
EOF
    
    show_success "تم إنشاء قاعدة البيانات"
}

# ==================================================
# تحسين أداء النظام
# ==================================================
optimize_system() {
    show_step "${W}تحسين أداء النظام لـ V2Ray...${NC}"
    
    # تحسينات kernel
    cat >> /etc/sysctl.conf << EOF

# V2Ray Manager - Performance Optimizations
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
EOF

    sysctl -p > /dev/null 2>&1
    
    # زيادة حدود الملفات المفتوحة
    cat >> /etc/security/limits.conf << EOF

# V2Ray Manager - Limits
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

    show_success "تم تحسين أداء النظام"
}

# ==================================================
# إنشاء ملفات القوائم
# ==================================================
create_menu_files() {
    show_step "${W}إنشاء ملفات القوائم...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    
    # إنشاء ملف menu.sh (سيتم وضع المحتوى منفصلاً)
    cat > "$MENU_SCRIPT" << 'EOF'
#!/bin/bash
# سيتم وضع محتوى menu.sh هنا
# يرجى نسخ المحتوى من ملف menu.sh المرفق
echo -e "\033[1;31m❌ يرجى نسخ محتوى menu.sh إلى هذا الملف\033[0m"
sleep 3
EOF

    # إنشاء ملف ssh.sh (سيتم وضع المحتوى منفصلاً)
    cat > "$SSH_SCRIPT" << 'EOF'
#!/bin/bash
# سيتم وضع محتوى ssh.sh هنا
# يرجى نسخ المحتوى من ملف ssh.sh المرفق
echo -e "\033[1;31m❌ يرجى نسخ محتوى ssh.sh إلى هذا الملف\033[0m"
sleep 3
EOF

    chmod +x "$MENU_SCRIPT" "$SSH_SCRIPT"
    
    # إنشاء روابط سريعة
    ln -sf "$MENU_SCRIPT" "$BIN_PATH"
    ln -sf "$MENU_SCRIPT" "/usr/local/bin/v2ray-menu"
    ln -sf "$SSH_SCRIPT" "/usr/local/bin/ssh-manager"
    ln -sf "$INSTALL_DIR/xui.info" "/usr/local/bin/xui-info"
    
    show_success "تم إنشاء ملفات القوائم"
}

# ==================================================
# عرض معلومات التثبيت
# ==================================================
show_completion() {
    clear
    IP=$(curl -s ifconfig.me)
    
    echo -e "${G}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${G}║     ✅ تم التثبيت بنجاح - V2Ray Manager v2.0        ║${NC}"
    echo -e "${G}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${G}║${NC}                                                    ${G}║${NC}"
    echo -e "${G}║${NC}  ${W}📌 معلومات النظام:${NC}                               ${G}║${NC}"
    echo -e "${G}║${NC}  ─────────────────                             ${G}║${NC}"
    echo -e "${G}║${NC}  • IP السيرفر: ${C}$IP${NC}                      ${G}║${NC}"
    echo -e "${G}║${NC}  • منفذ SSH: ${G}22${NC}                                   ${G}║${NC}"
    echo -e "${G}║${NC}                                                    ${G}║${NC}"
    echo -e "${G}║${NC}  ${W}📌 X-UI Panel:${NC}                                   ${G}║${NC}"
    echo -e "${G}║${NC}  ─────────────────                             ${G}║${NC}"
    echo -e "${G}║${NC}  • الرابط: ${C}http://$IP:54321${NC}               ${G}║${NC}"
    echo -e "${G}║${NC}  • المستخدم: ${Y}admin${NC}                                ${G}║${NC}"
    echo -e "${G}║${NC}  • كلمة المرور: ${Y}admin123${NC}                           ${G}║${NC}"
    echo -e "${G}║${NC}                                                    ${G}║${NC}"
    echo -e "${G}║${NC}  ${W}📌 الأوامر المتاحة:${NC}                               ${G}║${NC}"
    echo -e "${G}║${NC}  ─────────────────                             ${G}║${NC}"
    echo -e "${G}║${NC}  • ${B}v2ray${NC}        - القائمة الرئيسية                 ${G}║${NC}"
    echo -e "${G}║${NC}  • ${B}ssh-manager${NC}   - إدارة SSH فقط                  ${G}║${NC}"
    echo -e "${G}║${NC}  • ${B}xui-info${NC}      - عرض معلومات X-UI               ${G}║${NC}"
    echo -e "${G}║${NC}                                                    ${G}║${NC}"
    echo -e "${G}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # حفظ المعلومات
    cat > /root/v2ray-info.txt << EOF
V2Ray Manager - Installation Information
========================================
IP Address: $IP
SSH Port: 22

X-UI Panel:
  URL: http://$IP:54321
  Username: admin
  Password: admin123
  Port: 54321

Commands:
  v2ray        - Main menu
  ssh-manager  - SSH management
  xui-info     - Show X-UI info
========================================
EOF
}

# ==================================================
# التثبيت الرئيسي
# ==================================================
main_install() {
    show_banner
    
    echo -e "${Y}⚠️  سيتم تثبيت V2Ray Manager بالإعدادات التالية:${NC}"
    echo "   • X-UI Panel (آخر إصدار)"
    echo "   • إعدادات SSH محسنة"
    echo "   • فتح المنافذ الأساسية"
    echo "   • تحسينات أداء V2Ray"
    echo "   • قاعدة بيانات للمنافذ"
    echo ""
    
    read -p "$(echo -e ${Y}"هل تريد المتابعة؟ (y/n): "${NC})" confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo -e "${R}❌ تم الإلغاء${NC}"
        exit 0
    fi
    
    echo ""
    
    # بدء التثبيت
    check_system
    update_system
    install_dependencies
    setup_ssh
    setup_firewall
    install_xui
    create_database
    optimize_system
    create_menu_files
    
    show_completion
    
    echo ""
    echo -e "${G}✅ تم التثبيت بنجاح!${NC}"
    echo -e "${C}📌 استخدم الأمر: v2ray لفتح القائمة الرئيسية${NC}"
    echo ""
    
    # حذف ملفات التثبيت المؤقتة
    rm -f /root/install.sh 2>/dev/null
}

# بدء التثبيت
main_install
