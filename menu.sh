#!/bin/bash
# ==================================================
# V3Ray Manager - Main Menu
# ==================================================

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_PURPLE=$'\033[38;5;135m'
C_CYAN=$'\033[38;5;51m'

# المسارات
DB_DIR="/etc/v3ray"
DB_FILE="$DB_DIR/ports.db"
INSTALL_DIR="/usr/local/v3ray"

if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ هذا السكريبت يحتاج صلاحيات الروت${C_RESET}"
   exit 1
fi

# ==================================================
# دوال مساعدة
# ==================================================
show_banner() {
    clear
    local uptime=$(uptime -p | sed 's/up //')
    local users=$(who | wc -l)
    local ip=$(curl -s ifconfig.me 2>/dev/null || echo "غير متوفر")
    
    echo -e "${C_PURPLE}╔══════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_PURPLE}║     ${C_BOLD}🚀 V3Ray Manager - نظام إدارة خوادم V2Ray/X-UI${C_RESET}${C_PURPLE}     ║${C_RESET}"
    echo -e "${C_PURPLE}╠══════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_PURPLE}║${C_RESET}  🖥️  IP: ${C_CYAN}$ip${C_RESET}"
    echo -e "${C_PURPLE}║${C_RESET}  ⏰ Uptime: ${C_YELLOW}$uptime${C_RESET}  |  👥 Users: ${C_GREEN}$users${C_RESET}"
    echo -e "${C_PURPLE}╚══════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

press_enter() {
    echo ""
    read -p "اضغط Enter للعودة..."
}

xui_status() {
    if systemctl is-active --quiet x-ui; then
        echo -e "${C_GREEN}✅ شغال${C_RESET}"
    else
        echo -e "${C_RED}❌ موقف${C_RESET}"
    fi
}

# ==================================================
# قائمة SSH
# ==================================================
ssh_menu() {
    while true; do
        show_banner
        echo -e "${C_BOLD}${C_PURPLE}📌 قائمة إدارة SSH${C_RESET}\n"
        
        echo -e "  ${C_GREEN}[1]${C_RESET} 📊 عرض حالة SSH"
        echo -e "  ${C_GREEN}[2]${C_RESET} 🔄 إعادة تشغيل SSH"
        echo -e "  ${C_GREEN}[3]${C_RESET} 🔑 تغيير بورت SSH"
        echo -e "  ${C_GREEN}[4]${C_RESET} 🚫 حظر/فك حظر مستخدم"
        echo -e "  ${C_GREEN}[5]${C_RESET} 📋 عرض المستخدمين النشطين"
        echo -e "  ${C_GREEN}[6]${C_RESET} 🎨 تغيير شعار SSH (Banner)"
        echo -e "  ${C_GREEN}[7]${C_RESET} 🔒 تفعيل/تعطيل دخول الروت"
        echo -e "  ${C_RED}[0]${C_RESET} 🔙 رجوع"
        echo ""
        read -p "اختر: " choice
        
        case $choice in
            1)
                echo -e "\n${C_BLUE}🔍 حالة خدمة SSH:${C_RESET}"
                systemctl status sshd --no-pager -l 2>/dev/null || systemctl status ssh --no-pager -l
                press_enter
                ;;
            2)
                echo -e "\n${C_BLUE}🔄 إعادة تشغيل SSH...${C_RESET}"
                systemctl restart sshd 2>/dev/null || systemctl restart ssh
                echo -e "${C_GREEN}✅ تمت إعادة التشغيل${C_RESET}"
                press_enter
                ;;
            3)
                echo -e "\n${C_YELLOW}⚠️  تحذير: تغيير البورت قد يقطع اتصالك الحالي${C_RESET}"
                read -p "أدخل رقم البورت الجديد: " new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
                    sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config
                    sed -i "s/^Port [0-9]*/Port $new_port/" /etc/ssh/sshd_config
                    
                    # فتح البورت في الفايروول
                    ufw allow $new_port/tcp > /dev/null 2>&1
                    
                    systemctl restart sshd 2>/dev/null || systemctl restart ssh
                    echo -e "${C_GREEN}✅ تم تغيير البورت إلى $new_port${C_RESET}"
                    echo -e "${C_YELLOW}⚠️  تأكد من فتح البورت في الفايروول إذا كان مغلقاً${C_RESET}"
                else
                    echo -e "${C_RED}❌ بورت غير صالح${C_RESET}"
                fi
                press_enter
                ;;
            4)
                echo -e "\n${C_BLUE}🚫 حظر/فك حظر مستخدم${C_RESET}"
                read -p "اسم المستخدم: " username
                if id "$username" &>/dev/null; then
                    echo -e "1) حظر المستخدم"
                    echo -e "2) فك حظر المستخدم"
                    read -p "اختر: " block_choice
                    case $block_choice in
                        1)
                            passwd -l "$username"
                            echo -e "${C_GREEN}✅ تم حظر $username${C_RESET}"
                            ;;
                        2)
                            passwd -u "$username"
                            echo -e "${C_GREEN}✅ تم فك الحظر عن $username${C_RESET}"
                            ;;
                    esac
                else
                    echo -e "${C_RED}❌ المستخدم غير موجود${C_RESET}"
                fi
                press_enter
                ;;
            5)
                echo -e "\n${C_BLUE}📋 المستخدمين النشطين:${C_RESET}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                who | awk '{print "👤 " $1 "  |  من " $5 "  |  منذ " $3 " " $4}'
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "\nإجمالي المتصلين: ${C_GREEN}$(who | wc -l)${C_RESET}"
                press_enter
                ;;
            6)
                echo -e "\n${C_BLUE}🎨 شعار SSH الحالي:${C_RESET}"
                if [ -f /etc/ssh/banner ]; then
                    cat /etc/ssh/banner
                else
                    echo -e "${C_YELLOW}لا يوجد شعار حالياً${C_RESET}"
                fi
                echo ""
                echo -e "1) تغيير الشعار"
                echo -e "2) إلغاء الشعار"
                read -p "اختر: " banner_choice
                case $banner_choice in
                    1)
                        echo -e "${C_YELLOW}أدخل النص الجديد (Ctrl+D للحفظ):${C_RESET}"
                        cat > /etc/ssh/banner
                        sed -i '/^Banner/d' /etc/ssh/sshd_config
                        echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
                        systemctl restart sshd 2>/dev/null || systemctl restart ssh
                        echo -e "${C_GREEN}✅ تم تغيير الشعار${C_RESET}"
                        ;;
                    2)
                        rm -f /etc/ssh/banner
                        sed -i '/^Banner/d' /etc/ssh/sshd_config
                        systemctl restart sshd 2>/dev/null || systemctl restart ssh
                        echo -e "${C_GREEN}✅ تم إلغاء الشعار${C_RESET}"
                        ;;
                esac
                press_enter
                ;;
            7)
                echo -e "\n${C_BLUE}🔒 إعدادات دخول الروت${C_RESET}"
                if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
                    echo -e "الحالة: ${C_GREEN}مفعل${C_RESET}"
                    read -p "هل تريد تعطيل دخول الروت؟ (y/n): " disable_root
                    if [[ "$disable_root" == "y" ]]; then
                        sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
                        systemctl restart sshd 2>/dev/null || systemctl restart ssh
                        echo -e "${C_GREEN}✅ تم تعطيل دخول الروت${C_RESET}"
                    fi
                else
                    echo -e "الحالة: ${C_RED}معطل${C_RESET}"
                    read -p "هل تريد تفعيل دخول الروت؟ (y/n): " enable_root
                    if [[ "$enable_root" == "y" ]]; then
                        sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
                        systemctl restart sshd 2>/dev/null || systemctl restart ssh
                        echo -e "${C_GREEN}✅ تم تفعيل دخول الروت${C_RESET}"
                    fi
                fi
                press_enter
                ;;
            0) break ;;
            *) echo -e "${C_RED}❌ خيار غير صالح${C_RESET}"; sleep 1 ;;
        esac
    done
}

# ==================================================
# قائمة X-UI
# ==================================================
xui_menu() {
    while true; do
        show_banner
        echo -e "${C_BOLD}${C_PURPLE}📌 قائمة إدارة X-UI Panel${C_RESET}\n"
        
        local status=$(xui_status)
        echo -e "  حالة X-UI: $status\n"
        
        echo -e "  ${C_GREEN}[1]${C_RESET} ▶️ تشغيل X-UI"
        echo -e "  ${C_GREEN}[2]${C_RESET} ⏹️ إيقاف X-UI"
        echo -e "  ${C_GREEN}[3]${C_RESET} 🔄 إعادة تشغيل X-UI"
        echo -e "  ${C_GREEN}[4]${C_RESET} 📊 عرض حالة X-UI"
        echo -e "  ${C_GREEN}[5]${C_RESET} 📝 عرض معلومات الدخول"
        echo -e "  ${C_GREEN}[6]${C_RESET} 🔑 تغيير بورت X-UI"
        echo -e "  ${C_GREEN}[7]${C_RESET} 🔑 تغيير كلمة المرور"
        echo -e "  ${C_RED}[0]${C_RESET} 🔙 رجوع"
        echo ""
        read -p "اختر: " choice
        
        case $choice in
            1) systemctl start x-ui; echo -e "${C_GREEN}✅ تم التشغيل${C_RESET}"; press_enter ;;
            2) systemctl stop x-ui; echo -e "${C_GREEN}✅ تم الإيقاف${C_RESET}"; press_enter ;;
            3) systemctl restart x-ui; echo -e "${C_GREEN}✅ تمت إعادة التشغيل${C_RESET}"; press_enter ;;
            4) systemctl status x-ui --no-pager; press_enter ;;
            5)
                if [ -f "$INSTALL_DIR/xui.info" ]; then
                    cat "$INSTALL_DIR/xui.info"
                else
                    local port=$(grep -oP '"port": \K\d+' /usr/local/x-ui/bin/config.json 2>/dev/null || echo "54321")
                    echo -e "\n${C_YELLOW}معلومات الدخول:${C_RESET}"
                    echo -e "  • الرابط: ${C_CYAN}http://$(curl -s ifconfig.me):$port${C_RESET}"
                    echo -e "  • المستخدم: ${C_CYAN}admin${C_RESET}"
                    echo -e "  • كلمة المرور: ${C_CYAN}admin123${C_RESET}"
                fi
                press_enter
                ;;
            6)
                read -p "أدخل رقم البورت الجديد: " new_port
                if [[ "$new_port" =~ ^[0-9]+$ ]]; then
                    /usr/local/x-ui/x-ui setting -port $new_port
                    ufw allow $new_port/tcp > /dev/null 2>&1
                    systemctl restart x-ui
                    echo -e "${C_GREEN}✅ تم تغيير البورت إلى $new_port${C_RESET}"
                fi
                press_enter
                ;;
            7)
                read -p "كلمة المرور الجديدة: " new_pass
                if [[ -n "$new_pass" ]]; then
                    /usr/local/x-ui/x-ui setting -password $new_pass
                    systemctl restart x-ui
                    echo -e "${C_GREEN}✅ تم تغيير كلمة المرور${C_RESET}"
                fi
                press_enter
                ;;
            0) break ;;
            *) echo -e "${C_RED}❌ خيار غير صالح${C_RESET}"; sleep 1 ;;
        esac
    done
}

# ==================================================
# قائمة المنافذ
# ==================================================
ports_menu() {
    while true; do
        show_banner
        echo -e "${C_BOLD}${C_PURPLE}📌 قائمة إدارة المنافذ${C_RESET}\n"
        
        echo -e "  ${C_GREEN}[1]${C_RESET} 📋 عرض المنافذ المفتوحة"
        echo -e "  ${C_GREEN}[2]${C_RESET} ➕ فتح منفذ جديد"
        echo -e "  ${C_GREEN}[3]${C_RESET} 🔒 إغلاق منفذ"
        echo -e "  ${C_GREEN}[4]${C_RESET} 🔍 فحص منفذ معين"
        echo -e "  ${C_RED}[0]${C_RESET} 🔙 رجوع"
        echo ""
        read -p "اختر: " choice
        
        case $choice in
            1)
                echo -e "\n${C_BLUE}🔌 المنافذ المفتوحة:${C_RESET}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                ss -tuln | grep LISTEN | awk '{print $5}' | cut -d: -f2 | sort -nu | while read port; do
                    if [[ -n "$port" ]]; then
                        local service=$(lsof -i :$port 2>/dev/null | tail -1 | awk '{print $1}')
                        service=${service:-"غير معروف"}
                        echo -e "  • ${C_CYAN}$port${C_RESET}  |  $service"
                    fi
                done
                press_enter
                ;;
            2)
                read -p "رقم المنفذ: " port
                read -p "البروتوكول (tcp/udp/both) [both]: " proto
                proto=${proto:-both}
                
                ufw allow $port/$proto 2>/dev/null
                echo -e "${C_GREEN}✅ تم فتح المنفذ $port/$proto${C_RESET}"
                
                # حفظ في قاعدة البيانات
                echo "$port:$proto:منفذ مفتوح:active" >> "$DB_FILE" 2>/dev/null
                press_enter
                ;;
            3)
                read -p "رقم المنفذ: " port
                read -p "البروتوكول (tcp/udp/both) [both]: " proto
                proto=${proto:-both}
                
                ufw delete allow $port/$proto 2>/dev/null
                echo -e "${C_GREEN}✅ تم إغلاق المنفذ $port/$proto${C_RESET}"
                press_enter
                ;;
            4)
                read -p "رقم المنفذ: " port
                if ss -tuln | grep -q ":$port "; then
                    local service=$(lsof -i :$port 2>/dev/null | tail -1 | awk '{print $1}')
                    echo -e "${C_GREEN}✅ المنفذ $port مفتوح - يستخدمه: ${service:-غير معروف}${C_RESET}"
                else
                    echo -e "${C_RED}❌ المنفذ $port مغلق${C_RESET}"
                fi
                press_enter
                ;;
            0) break ;;
            *) echo -e "${C_RED}❌ خيار غير صالح${C_RESET}"; sleep 1 ;;
        esac
    done
}

# ==================================================
# القائمة الرئيسية
# ==================================================
main_menu() {
    while true; do
        show_banner
        echo -e "${C_BOLD}${C_PURPLE}📌 القائمة الرئيسية${C_RESET}\n"
        
        echo -e "  ${C_GREEN}[1]${C_RESET} 🔌 إدارة SSH"
        echo -e "  ${C_GREEN}[2]${C_RESET} 📦 إدارة X-UI Panel"
        echo -e "  ${C_GREEN}[3]${C_RESET} 🔓 إدارة المنافذ"
        echo -e "  ${C_GREEN}[4]${C_RESET} 📊 إحصائيات النظام"
        echo -e "  ${C_GREEN}[5]${C_RESET} 🔄 تحديث النظام"
        echo -e "  ${C_RED}[0]${C_RESET} 🚪 خروج"
        echo ""
        read -p "اختر: " choice
        
        case $choice in
            1) ssh_menu ;;
            2) xui_menu ;;
            3) ports_menu ;;
            4)
                echo -e "\n${C_BLUE}📊 إحصائيات النظام:${C_RESET}"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo -e "• الذاكرة المستخدمة: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
                echo -e "• المساحة المستخدمة: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
                echo -e "• متوسط التحميل: $(uptime | awk -F'load average:' '{print $2}')"
                echo -e "• وقت التشغيل: $(uptime -p | sed 's/up //')"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                press_enter
                ;;
            5)
                echo -e "\n${C_BLUE}🔄 تحديث النظام...${C_RESET}"
                apt-get update && apt-get upgrade -y
                echo -e "${C_GREEN}✅ تم التحديث${C_RESET}"
                press_enter
                ;;
            0)
                echo -e "\n${C_GREEN}مع السلامة! 👋${C_RESET}"
                exit 0
                ;;
            *) echo -e "${C_RED}❌ خيار غير صالح${C_RESET}"; sleep 1 ;;
        esac
    done
}

# ==================================================
# بدء التشغيل
# ==================================================
main_menu