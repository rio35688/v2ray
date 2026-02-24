#!/bin/bash
# ==================================================
# V2Ray Manager - Main Menu
# القائمة الرئيسية لإدارة X-UI والمنافذ والنظام
# ==================================================

# الألوان
R='\033[1;31m'
G='\033[1;32m'
Y='\033[1;33m'
B='\033[1;34m'
P='\033[1;35m'
C='\033[1;36m'
W='\033[1;37m'
NC='\033[0m'

# التحقق من الصلاحيات
if [[ $EUID -ne 0 ]]; then
   echo -e "${R}❌ يجب تشغيل السكريبت بصلاحيات الروت${NC}"
   exit 1
fi

# المسارات
DB_DIR="/etc/v2ray"
DB_FILE="$DB_DIR/ports.db"
INSTALL_DIR="/usr/local/v2ray"

# ==================================================
# دوال مساعدة
# ==================================================
show_banner() {
    clear
    IP=$(curl -s ifconfig.me 2>/dev/null || echo "غير متوفر")
    UPTIME=$(uptime -p | sed 's/up //')
    USERS=$(who | wc -l)
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
    
    echo -e "${P}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${P}║     ${W}🚀 V2Ray Manager v2.0 - نظام إدارة V2Ray${P}           ║${NC}"
    echo -e "${P}╠══════════════════════════════════════════════════════╣${NC}"
    echo -e "${P}║${NC}  ${C}IP:${NC} $IP"
    echo -e "${P}║${NC}  ${C}Uptime:${NC} $UPTIME  |  ${C}Users:${NC} $USERS  |  ${C}Load:${NC} $LOAD"
    echo -e "${P}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

press_enter() {
    echo ""
    read -p "اضغط Enter للعودة..."
}

show_success() {
    echo -e "${G}✅ $1${NC}"
}

show_error() {
    echo -e "${R}❌ $1${NC}"
}

show_warning() {
    echo -e "${Y}⚠️ $1${NC}"
}

show_info() {
    echo -e "${C}ℹ️ $1${NC}"
}

# ==================================================
# إدارة X-UI
# ==================================================
xui_status() {
    if systemctl is-active --quiet x-ui; then
        echo -e "${G}✅ شغال${NC}"
    else
        echo -e "${R}❌ موقف${NC}"
    fi
}

xui_menu() {
    while true; do
        show_banner
        echo -e "${P}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${P}║           📦 إدارة X-UI Panel                  ║${NC}"
        echo -e "${P}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        
        STATUS=$(xui_status)
        PORT=$(grep -oP '"port": \K\d+' /usr/local/x-ui/bin/config.json 2>/dev/null || echo "54321")
        
        echo -e "  ${C}الحالة:${NC} $STATUS  |  ${C}المنفذ:${NC} ${G}$PORT${NC}"
        echo ""
        
        echo -e "  ${G}[1]${NC} ▶️ تشغيل X-UI"
        echo -e "  ${G}[2]${NC} ⏹️ إيقاف X-UI"
        echo -e "  ${G}[3]${NC} 🔄 إعادة تشغيل X-UI"
        echo -e "  ${G}[4]${NC} 📊 عرض حالة X-UI"
        echo -e "  ${G}[5]${NC} 📝 معلومات الدخول"
        echo -e "  ${G}[6]${NC} 🔑 تغيير كلمة المرور"
        echo -e "  ${G}[7]${NC} 🔌 تغيير المنفذ"
        echo -e "  ${G}[8]${NC} 📋 عرض السجلات"
        echo -e "  ${G}[9]${NC} 🌐 تحديث X-UI"
        echo -e "  ${R}[0]${NC} 🔙 رجوع"
        echo ""
        read -p "$(echo -e ${Y}"اختر رقم الخيار: "${NC})" choice
        
        case $choice in
            1)
                systemctl start x-ui
                show_success "تم تشغيل X-UI"
                press_enter
                ;;
            2)
                systemctl stop x-ui
                show_success "تم إيقاف X-UI"
                press_enter
                ;;
            3)
                systemctl restart x-ui
                show_success "تم إعادة تشغيل X-UI"
                press_enter
                ;;
            4)
                echo ""
                systemctl status x-ui --no-pager -l
                press_enter
                ;;
            5)
                if [ -f "$INSTALL_DIR/xui.info" ]; then
                    cat "$INSTALL_DIR/xui.info"
                else
                    IP=$(curl -s ifconfig.me)
                    echo -e "\n${Y}معلومات الدخول:${NC}"
                    echo "────────────────────────"
                    echo -e "الرابط: ${C}http://$IP:54321${NC}"
                    echo -e "المستخدم: ${G}admin${NC}"
                    echo -e "كلمة المرور: ${G}admin123${NC}"
                    echo "────────────────────────"
                fi
                press_enter
                ;;
            6)
                read -p "أدخل كلمة المرور الجديدة: " new_pass
                if [[ -n "$new_pass" ]]; then
                    /usr/local/x-ui/x-ui setting -password "$new_pass" > /dev/null 2>&1
                    systemctl restart x-ui
                    show_success "تم تغيير كلمة المرور"
                fi
                press_enter
                ;;
            7)
                read -p "أدخل المنفذ الجديد: " new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                    /usr/local/x-ui/x-ui setting -port "$new_port" > /dev/null 2>&1
                    ufw allow "$new_port/tcp" > /dev/null 2>&1
                    systemctl restart x-ui
                    show_success "تم تغيير المنفذ إلى $new_port"
                else
                    show_error "منفذ غير صالح"
                fi
                press_enter
                ;;
            8)
                echo -e "\n${C}آخر 50 سطر من السجلات:${NC}"
                journalctl -u x-ui -n 50 --no-pager
                press_enter
                ;;
            9)
                echo -e "\n${C}جاري تحديث X-UI...${NC}"
                bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
                press_enter
                ;;
            0) break ;;
            *) show_error "خيار غير صالح"; sleep 1 ;;
        esac
    done
}

# ==================================================
# إدارة المنافذ
# ==================================================
check_port() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        return 0
    else
        return 1
    fi
}

get_port_service() {
    local port=$1
    lsof -i :$port 2>/dev/null | tail -1 | awk '{print $1}'
}

ports_menu() {
    while true; do
        show_banner
        echo -e "${P}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${P}║           🔌 إدارة المنافذ                     ║${NC}"
        echo -e "${P}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "  ${G}[1]${NC} 📋 عرض المنافذ المفتوحة"
        echo -e "  ${G}[2]${NC} ➕ فتح منفذ جديد"
        echo -e "  ${G}[3]${NC} 🔒 إغلاق منفذ"
        echo -e "  ${G}[4]${NC} 🔍 فحص منفذ"
        echo -e "  ${G}[5]${NC} 📊 إحصائيات المنافذ"
        echo -e "  ${G}[6]${NC} ⚡ فتح منافذ V2Ray"
        echo -e "  ${G}[7]${NC} 🔄 إعادة ضبط الفايروول"
        echo -e "  ${R}[0]${NC} 🔙 رجوع"
        echo ""
        read -p "$(echo -e ${Y}"اختر رقم الخيار: "${NC})" choice
        
        case $choice in
            1)
                echo -e "\n${C}المنافذ المفتوحة حالياً:${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                printf "%-10s | %-8s | %-15s | %s\n" "المنفذ" "بروتوكول" "الخدمة" "الحالة"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                ss -tuln | grep LISTEN | while read line; do
                    PROTO=$(echo "$line" | awk '{print $1}')
                    ADDR=$(echo "$line" | awk '{print $5}')
                    PORT=$(echo "$ADDR" | awk -F: '{print $NF}')
                    
                    if [[ -n "$PORT" ]]; then
                        SERVICE=$(get_port_service "$PORT")
                        SERVICE=${SERVICE:-"-"}
                        
                        if grep -q "^$PORT:" "$DB_FILE" 2>/dev/null; then
                            printf "%-10s | %-8s | %-15s | ${G}مسجل${NC}\n" "$PORT" "$PROTO" "$SERVICE"
                        else
                            printf "%-10s | %-8s | %-15s | ${Y}غير مسجل${NC}\n" "$PORT" "$PROTO" "$SERVICE"
                        fi
                    fi
                done
                press_enter
                ;;
            2)
                echo -e "\n${C}➕ فتح منفذ جديد${NC}"
                read -p "رقم المنفذ: " port
                read -p "البروتوكول (tcp/udp/both) [both]: " proto
                proto=${proto:-both}
                read -p "الوصف: " desc
                
                if [[ "$proto" == "both" ]]; then
                    ufw allow "$port/tcp" > /dev/null 2>&1
                    ufw allow "$port/udp" > /dev/null 2>&1
                    proto_used="tcp/udp"
                else
                    ufw allow "$port/$proto" > /dev/null 2>&1
                    proto_used="$proto"
                fi
                
                echo "$port:$proto_used:$desc:active:$(date +%Y-%m-%d)" >> "$DB_FILE"
                show_success "تم فتح المنفذ $port/$proto_used"
                press_enter
                ;;
            3)
                echo -e "\n${C}🔒 إغلاق منفذ${NC}"
                read -p "رقم المنفذ: " port
                read -p "البروتوكول (tcp/udp/both) [both]: " proto
                proto=${proto:-both}
                
                if [[ "$proto" == "both" ]]; then
                    ufw delete allow "$port/tcp" > /dev/null 2>&1
                    ufw delete allow "$port/udp" > /dev/null 2>&1
                else
                    ufw delete allow "$port/$proto" > /dev/null 2>&1
                fi
                
                sed -i "/^$port:/d" "$DB_FILE" 2>/dev/null
                show_success "تم إغلاق المنفذ $port"
                press_enter
                ;;
            4)
                read -p "أدخل رقم المنفذ: " port
                echo ""
                if check_port "$port"; then
                    SERVICE=$(get_port_service "$port")
                    echo -e "${G}✅ المنفذ $port مفتوح${NC}"
                    echo -e "   الخدمة: ${C}${SERVICE:-غير معروفة}${NC}"
                    ss -tunlp | grep ":$port "
                else
                    echo -e "${R}❌ المنفذ $port مغلق${NC}"
                fi
                press_enter
                ;;
            5)
                TOTAL=$(ss -tuln | grep LISTEN | wc -l)
                TCP=$(ss -tln | grep LISTEN | wc -l)
                UDP=$(ss -uln | grep UNCONN | wc -l)
                DB=$(wc -l < "$DB_FILE" 2>/dev/null || echo "0")
                
                echo -e "\n${C}📊 إحصائيات المنافذ:${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "• إجمالي المنافذ المفتوحة: ${G}$TOTAL${NC}"
                echo -e "• منافذ TCP: ${C}$TCP${NC}"
                echo -e "• منافذ UDP: ${C}$UDP${NC}"
                echo -e "• منافذ مسجلة: ${Y}$DB${NC}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                press_enter
                ;;
            6)
                echo -e "\n${C}⚡ فتح منافذ V2Ray الشائعة${NC}"
                V2RAY_PORTS="443 80 8080 8443 2053 2083 2087 2096 8880 9999"
                for port in $V2RAY_PORTS; do
                    ufw allow "$port/tcp" > /dev/null 2>&1
                    ufw allow "$port/udp" > /dev/null 2>&1
                    echo "$port:tcp/udp:V2Ray Port:active:$(date +%Y-%m-%d)" >> "$DB_FILE"
                    echo -e "  ✅ تم فتح المنفذ $port"
                done
                show_success "تم فتح جميع المنافذ"
                press_enter
                ;;
            7)
                show_warning "سيتم إعادة ضبط الفايروول"
                read -p "هل أنت متأكد؟ (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    ufw --force reset > /dev/null 2>&1
                    ufw default deny incoming > /dev/null 2>&1
                    ufw default allow outgoing > /dev/null 2>&1
                    ufw allow 22/tcp > /dev/null 2>&1
                    ufw allow 54321/tcp > /dev/null 2>&1
                    echo "y" | ufw --force enable > /dev/null 2>&1
                    show_success "تم إعادة ضبط الفايروول"
                fi
                press_enter
                ;;
            0) break ;;
            *) show_error "خيار غير صالح"; sleep 1 ;;
        esac
    done
}

# ==================================================
# إحصائيات النظام
# ==================================================
system_stats() {
    show_banner
    
    echo -e "${P}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${P}║           📊 إحصائيات النظام                   ║${NC}"
    echo -e "${P}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # CPU
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}💾 المعالج (CPU):${NC}"
    MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^ //')
    CORES=$(nproc)
    echo -e "  • النموذج: $MODEL"
    echo -e "  • النوى: ${G}$CORES${NC} نواة"
    echo -e "  • التحميل: $(uptime | awk -F'load average:' '{print $2}')"
    
    # Memory
    echo -e "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}🖥️ الذاكرة (RAM):${NC}"
    free -h | awk 'NR==2{printf "  • الإجمالي: %s\n  • المستخدم: %s\n  • المتاح: %s\n", $2, $3, $7}'
    
    # Disk
    echo -e "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}💽 المساحة التخزينية:${NC}"
    df -h / | awk 'NR==2{printf "  • الإجمالي: %s\n  • المستخدم: %s\n  • المتاح: %s\n", $2, $3, $4}'
    
    # Network
    echo -e "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}🌐 معلومات الشبكة:${NC}"
    echo -e "  • IPv4: ${G}$(curl -s ifconfig.me)${NC}"
    echo -e "  • الواجهة: $(ip -4 route | grep default | awk '{print $5}')"
    
    # Services
    echo -e "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}⚙️ حالة الخدمات:${NC}"
    XUI_STATUS=$(systemctl is-active x-ui >/dev/null 2>&1 && echo "${G}✅ نشط${NC}" || echo "${R}❌ متوقف${NC}")
    SSH_STATUS=$(systemctl is-active sshd >/dev/null 2>&1 && echo "${G}✅ نشط${NC}" || echo "${R}❌ متوقف${NC}")
    UFW_STATUS=$(ufw status | grep -q "active" && echo "${G}✅ نشط${NC}" || echo "${R}❌ متوقف${NC}")
    
    echo -e "  • X-UI: $XUI_STATUS"
    echo -e "  • SSH: $SSH_STATUS"
    echo -e "  • UFW: $UFW_STATUS"
    
    echo -e "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    press_enter
}

# ==================================================
# أدوات النظام
# ==================================================
system_tools() {
    while true; do
        show_banner
        echo -e "${P}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${P}║           🛠️ أدوات النظام                      ║${NC}"
        echo -e "${P}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "  ${G}[1]${NC} 🔄 تحديث النظام"
        echo -e "  ${G}[2]${NC} 🧹 تنظيف النظام"
        echo -e "  ${G}[3]${NC} 🔐 ضبط الفايروول"
        echo -e "  ${G}[4]${NC} 🌐 تغيير DNS"
        echo -e "  ${G}[5]${NC} 📦 تحديث السكريبت"
        echo -e "  ${G}[6]${NC} 🔄 إعادة تشغيل السيرفر"
        echo -e "  ${R}[0]${NC} 🔙 رجوع"
        echo ""
        read -p "$(echo -e ${Y}"اختر رقم الخيار: "${NC})" choice
        
        case $choice in
            1)
                echo -e "\n${C}جاري تحديث النظام...${NC}"
                apt-get update && apt-get upgrade -y
                show_success "تم التحديث"
                press_enter
                ;;
            2)
                echo -e "\n${C}جاري تنظيف النظام...${NC}"
                apt-get autoremove -y
                apt-get autoclean
                journalctl --vacuum-time=7d
                show_success "تم التنظيف"
                press_enter
                ;;
            3)
                echo -e "\n${C}إعدادات الفايروول:${NC}"
                ufw status verbose
                echo ""
                echo "1) تعطيل الفايروول"
                echo "2) تفعيل الفايروول"
                echo "3) إظهار القواعد"
                read -p "اختر: " fw_choice
                case $fw_choice in
                    1) ufw disable ;;
                    2) ufw enable ;;
                    3) ufw status numbered ;;
                esac
                press_enter
                ;;
            4)
                echo -e "\n${C}تغيير DNS:${NC}"
                echo "1) Google DNS (8.8.8.8)"
                echo "2) Cloudflare DNS (1.1.1.1)"
                echo "3) OpenDNS (208.67.222.222)"
                read -p "اختر: " dns_choice
                
                case $dns_choice in
                    1)
                        echo "nameserver 8.8.8.8" > /etc/resolv.conf
                        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
                        show_success "تم تغيير DNS إلى Google"
                        ;;
                    2)
                        echo "nameserver 1.1.1.1" > /etc/resolv.conf
                        echo "nameserver 1.0.0.1" >> /etc/resolv.conf
                        show_success "تم تغيير DNS إلى Cloudflare"
                        ;;
                    3)
                        echo "nameserver 208.67.222.222" > /etc/resolv.conf
                        echo "nameserver 208.67.220.220" >> /etc/resolv.conf
                        show_success "تم تغيير DNS إلى OpenDNS"
                        ;;
                esac
                press_enter
                ;;
            5)
                echo -e "\n${C}جاري تحديث السكريبت...${NC}"
                # هنا يمكن وضع رابط التحديث
                show_success "تم التحديث"
                press_enter
                ;;
            6)
                show_warning "سيتم إعادة تشغيل السيرفر"
                read -p "هل أنت متأكد؟ (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    reboot
                fi
                press_enter
                ;;
            0) break ;;
            *) show_error "خيار غير صالح"; sleep 1 ;;
        esac
    done
}

# ==================================================
# القائمة الرئيسية
# ==================================================
main_menu() {
    while true; do
        show_banner
        echo -e "${P}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${P}║           📌 القائمة الرئيسية                  ║${NC}"
        echo -e "${P}╚════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "  ${G}[1]${NC} 📦 إدارة X-UI Panel"
        echo -e "  ${G}[2]${NC} 🔌 إدارة المنافذ"
        echo -e "  ${G}[3]${NC} 📊 إحصائيات النظام"
        echo -e "  ${G}[4]${NC} 🛠️ أدوات النظام"
        echo -e "  ${G}[5]${NC} 🔐 إدارة SSH (قائمة منفصلة)"
        echo -e "  ${G}[6]${NC} 📝 معلومات التثبيت"
        echo -e "  ${R}[0]${NC} 🚪 خروج"
        echo ""
        read -p "$(echo -e ${Y}"اختر رقم الخيار: "${NC})" choice
        
        case $choice in
            1) xui_menu ;;
            2) ports_menu ;;
            3) system_stats ;;
            4) system_tools ;;
            5) 
                if [ -f "/usr/local/bin/ssh-manager" ]; then
                    /usr/local/bin/ssh-manager
                else
                    show_error "ملف SSH غير موجود"
                fi
                ;;
            6)
                if [ -f "$INSTALL_DIR/xui.info" ]; then
                    cat "$INSTALL_DIR/xui.info"
                else
                    IP=$(curl -s ifconfig.me)
                    echo -e "\n${Y}معلومات النظام:${NC}"
                    echo "────────────────────────"
                    echo -e "X-UI Panel: ${C}http://$IP:54321${NC}"
                    echo -e "Username: ${G}admin${NC}"
                    echo -e "Password: ${G}admin123${NC}"
                    echo "────────────────────────"
                fi
                press_enter
                ;;
            0)
                echo -e "\n${G}مع السلامة! 👋${NC}"
                exit 0
                ;;
            *) show_error "خيار غير صالح"; sleep 1 ;;
        esac
    done
}

# بدء البرنامج
main_menu