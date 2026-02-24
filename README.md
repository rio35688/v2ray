#!/bin/bash
# ==================================================
# V3Ray Lite - فقط X-UI والمنافذ
# ==================================================

C_RESET=$'\033[0m'
C_GREEN=$'\033[38;5;46m'
C_RED=$'\033[38;5;196m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'

# التحقق من الصلاحيات
if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ يشترط تشغيل السكريبت بصلاحيات الروت${C_RESET}"
   exit 1
fi

# القائمة الرئيسية
main_menu() {
    while true; do
        clear
        echo "╔════════════════════════════════════╗"
        echo "║     🚀 V3Ray Lite - X-UI Manager   ║"
        echo "╠════════════════════════════════════╣"
        echo "║                                    ║"
        echo "║  ${C_GREEN}[1]${C_RESET} تثبيت X-UI Panel              ║"
        echo "║  ${C_GREEN}[2]${C_RESET} تشغيل/إيقاف X-UI              ║"
        echo "║  ${C_GREEN}[3]${C_RESET} عرض معلومات X-UI              ║"
        echo "║  ${C_GREEN}[4]${C_RESET} فتح منفذ (UFW)                ║"
        echo "║  ${C_GREEN}[5]${C_RESET} عرض المنافذ المفتوحة          ║"
        echo "║  ${C_GREEN}[6]${C_RESET} إعدادات SSH                   ║"
        echo "║  ${C_RED}[0]${C_RESET} خروج                           ║"
        echo "║                                    ║"
        echo "╚════════════════════════════════════╝"
        echo ""
        read -p "اختر رقم الخيار: " choice
        
        case $choice in
            1) install_xui ;;
            2) manage_xui ;;
            3) show_xui_info ;;
            4) open_port ;;
            5) show_ports ;;
            6) ssh_settings ;;
            0) exit 0 ;;
            *) echo -e "${C_RED}خيار غير صحيح${C_RESET}"; sleep 2 ;;
        esac
    done
}

# دوال التثبيت والإدارة
install_xui() {
    echo -e "${C_BLUE}📦 جاري تثبيت X-UI Panel...${C_RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    echo -e "${C_GREEN}✅ تم التثبيت${C_RESET}"
    read -p "اضغط Enter للعودة"
}

manage_xui() {
    echo ""
    echo "1) تشغيل X-UI"
    echo "2) إيقاف X-UI"
    echo "3) إعادة تشغيل X-UI"
    echo "4) عرض الحالة"
    read -p "اختر: " sub
    case $sub in
        1) systemctl start x-ui ;;
        2) systemctl stop x-ui ;;
        3) systemctl restart x-ui ;;
        4) systemctl status x-ui ;;
    esac
    read -p "اضغط Enter للعودة"
}

open_port() {
    read -p "أدخل رقم المنفذ: " port
    ufw allow $port/tcp
    ufw allow $port/udp
    echo -e "${C_GREEN}✅ تم فتح المنفذ $port${C_RESET}"
    read -p "اضغط Enter للعودة"
}

show_ports() {
    echo -e "\n${C_BLUE}المنافذ المفتوحة:${C_RESET}"
    ss -tuln | grep LISTEN
    read -p "اضغط Enter للعودة"
}

ssh_settings() {
    echo ""
    echo "1) تغيير بورت SSH"
    echo "2) إعادة تشغيل SSH"
    echo "3) عرض حالة SSH"
    read -p "اختر: " sub
    case $sub in
        1)
            read -p "أدخل البورت الجديد: " port
            sed -i "s/^#Port 22/Port $port/" /etc/ssh/sshd_config
            systemctl restart sshd
            echo -e "${C_GREEN}✅ تم تغيير البورت إلى $port${C_RESET}"
            ;;
        2) systemctl restart sshd ;;
        3) systemctl status sshd ;;
    esac
    read -p "اضغط Enter للعودة"
}

# بدء البرنامج
main_menu
