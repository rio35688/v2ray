#!/bin/bash
# ==================================================
# V3Ray Manager - Installer
# ==================================================

C_RESET=$'\033[0m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_RED=$'\033[38;5;196m'
C_BLUE=$'\033[38;5;39m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ هذا السكريبت يحتاج صلاحيات الروت${C_RESET}"
   exit 1
fi

# المسارات
INSTALL_DIR="/usr/local/v3ray"
MENU_SCRIPT="$INSTALL_DIR/menu.sh"
BIN_PATH="/usr/local/bin/v3ray"

# التحقق من dependencies
check_deps() {
    echo -e "${C_BLUE}🔍 التحقق من المتطلبات...${C_RESET}"
    
    local deps=("curl" "wget" "sqlite3" "jq" "ufw")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            missing+=($dep)
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${C_YELLOW}📦 تثبيت الحزم المطلوبة: ${missing[*]}${C_RESET}"
        apt-get update > /dev/null 2>&1
        apt-get install -y ${missing[@]} > /dev/null 2>&1
    fi
    
    echo -e "${C_GREEN}✅ تم التحقق من المتطلبات${C_RESET}"
}

# إنشاء المجلدات
create_dirs() {
    echo -e "${C_BLUE}📁 إنشاء المجلدات...${C_RESET}"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "/etc/v3ray"
    mkdir -p "/var/log/v3ray"
    
    echo -e "${C_GREEN}✅ تم إنشاء المجلدات${C_RESET}"
}

# تحميل ملف القائمة
download_menu() {
    echo -e "${C_BLUE}📥 تحميل ملف القائمة...${C_RESET}"
    
    # هنا يمكنك وضع الرابط الخاص بالملف المستضاف
    # أو يمكننا نسخ الملف محلياً
    
    cat > "$MENU_SCRIPT" << 'EOF'
# سيتم وضع محتوى menu.sh هنا
EOF
    
    chmod +x "$MENU_SCRIPT"
    ln -sf "$MENU_SCRIPT" "$BIN_PATH"
    
    echo -e "${C_GREEN}✅ تم تحميل ملف القائمة${C_RESET}"
}

# إعداد خدمة SSH
setup_ssh() {
    echo -e "${C_BLUE}🔧 إعداد SSH...${C_RESET}"
    
    # نسخ احتياطي
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # تعديل إعدادات SSH
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' /etc/ssh/sshd_config
    sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 3/' /etc/ssh/sshd_config
    
    # إعادة تشغيل SSH
    systemctl restart sshd || systemctl restart ssh
    
    echo -e "${C_GREEN}✅ تم إعداد SSH${C_RESET}"
}

# فتح المنافذ في الفايروول
open_ports() {
    echo -e "${C_BLUE}🔥 فتح المنافذ في الفايروول...${C_RESET}"
    
    # منافذ SSH
    ufw allow 22/tcp > /dev/null 2>&1
    
    # منافذ X-UI الافتراضية
    ufw allow 54321/tcp > /dev/null 2>&1
    
    # منافذ V2Ray الشائعة
    local common_ports=(443 80 8080 8443 2053 2083 2087 2096 8880)
    for port in "${common_ports[@]}"; do
        ufw allow $port/tcp > /dev/null 2>&1
        ufw allow $port/udp > /dev/null 2>&1
    done
    
    # تمكين UFW
    echo "y" | ufw enable > /dev/null 2>&1
    
    echo -e "${C_GREEN}✅ تم فتح المنافذ${C_RESET}"
}

# تثبيت X-UI
install_xui() {
    echo -e "${C_BLUE}📦 تثبيت X-UI Panel...${C_RESET}"
    
    # سكريبت التثبيت الرسمي
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}✅ تم تثبيت X-UI${C_RESET}"
        
        # تغيير الإعدادات الافتراضية
        /usr/local/x-ui/x-ui setting -username admin -password admin123 2>/dev/null
        /usr/local/x-ui/x-ui setting -port 54321 2>/dev/null
        
        # إعادة التشغيل
        systemctl restart x-ui
        
        # حفظ معلومات الدخول
        cat > "$INSTALL_DIR/xui.info" << EOF
X-UI Login Information:
=======================
URL    : http://$(curl -s ifconfig.me):54321
Username: admin
Password: admin123
Port    : 54321
=======================
EOF
    else
        echo -e "${C_RED}❌ فشل تثبيت X-UI${C_RESET}"
    fi
}

# إنشاء banner SSH
create_ssh_banner() {
    echo -e "${C_BLUE}🎨 إنشاء شعار SSH...${C_RESET}"
    
    cat > /etc/ssh/banner << 'EOF'
╔════════════════════════════════════════════════╗
║            🚀 V3Ray Manager Server             ║
║         نظام إدارة خوادم V2Ray/X-UI            ║
╠════════════════════════════════════════════════╣
║ • تم تجهيز السيرفر بنجاح                       ║
║ • استخدم الأمر: v3ray                          ║
║ • X-UI Panel: http://IP:54321                  ║
║ • للدعم: @yourchannel                           ║
╚════════════════════════════════════════════════╝
EOF
    
    # تفعيل banner في SSH
    echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
    systemctl restart sshd || systemctl restart ssh
    
    echo -e "${C_GREEN}✅ تم إنشاء شعار SSH${C_RESET}"
}

# إنشاء قاعدة بيانات المنافذ
create_database() {
    echo -e "${C_BLUE}💾 إنشاء قاعدة البيانات...${C_RESET}"
    
    cat > "/etc/v3ray/ports.db" << EOF
# V3Ray Manager - Ports Database
# format: port:protocol:description:status
443:tcp:HTTPS:active
80:tcp:HTTP:active
54321:tcp:X-UI Panel:active
22:tcp:SSH:active
EOF
    
    echo -e "${C_GREEN}✅ تم إنشاء قاعدة البيانات${C_RESET}"
}

# عرض معلومات التثبيت
show_info() {
    clear
    echo "╔════════════════════════════════════════════════╗"
    echo "║     ✅ تم التثبيت بنجاح - V3Ray Manager       ║"
    echo "╠════════════════════════════════════════════════╣"
    echo "║                                                ║"
    echo "║  📌 معلومات الدخول:                           ║"
    echo "║  ─────────────────                             ║"
    echo "║  • SSH Port: 22                                ║"
    echo "║  • Root Login: مفعل                           ║"
    echo "║                                                ║"
    echo "║  📌 X-UI Panel:                                ║"
    echo "║  ─────────────────                             ║"
    echo "║  • URL: http://$(curl -s ifconfig.me):54321             ║"
    echo "║  • Username: admin                             ║"
    echo "║  • Password: admin123                          ║"
    echo "║                                                ║"
    echo "║  📌 أوامر النظام:                              ║"
    echo "║  ─────────────────                             ║"
    echo "║  • v3ray        - فتح القائمة الرئيسية        ║"
    echo "║  • v3ray-menu   - نفس الأمر                   ║"
    echo "║                                                ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""
}

# ==================================================
# التثبيت الرئيسي
# ==================================================
main_install() {
    clear
    echo "╔════════════════════════════════════════════════╗"
    echo "║     🚀 V3Ray Manager - Installation Script    ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""
    
    # التحقق من التثبيت السابق
    if [ -f "$BIN_PATH" ]; then
        echo -e "${C_YELLOW}⚠️ V3Ray Manager مثبت مسبقاً${C_RESET}"
        read -p "هل تريد إعادة التثبيت؟ (y/n): " reinstall
        if [[ "$reinstall" != "y" ]]; then
            echo -e "${C_RED}❌ تم الإلغاء${C_RESET}"
            exit 0
        fi
    fi
    
    # تنفيذ خطوات التثبيت
    check_deps
    create_dirs
    setup_ssh
    open_ports
    install_xui
    create_ssh_banner
    create_database
    
    # عرض المعلومات
    show_info
    
    echo -e "${C_GREEN}✅ تم التثبيت بنجاح! استخدم الأمر: v3ray${C_RESET}"
}

# ==================================================
# تنفيذ التثبيت
# ==================================================
main_install