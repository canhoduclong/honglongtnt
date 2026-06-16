from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / "screenshots" / "iphone-6.9"
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1320, 2868
TEAL, DARK, SLATE, WHITE = "#0D7A70", "#0F172A", "#64748B", "#FFFFFF"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)


def fit_bg():
    source = Image.open(ROOT / "marketing-background.png").convert("RGB")
    ratio = max(W / source.width, H / source.height)
    source = source.resize((int(source.width * ratio), int(source.height * ratio)))
    left = (source.width - W) // 2
    return source.crop((left, 0, left + W, H)).filter(ImageFilter.GaussianBlur(2))


def text(draw, xy, value, size, color=DARK, bold=False, anchor=None, spacing=8):
    draw.multiline_text(xy, value, font=font(size, bold), fill=color, anchor=anchor, spacing=spacing, align="center" if anchor == "ma" else "left")


def card(draw, box, fill=WHITE, outline="#E2E8F0", radius=28):
    draw.rounded_rectangle(box, radius, fill, outline, width=2)


def badge(draw, x, y, label, fill="#DCFCE7", color="#15803D"):
    width = max(125, len(label) * 15 + 32)
    draw.rounded_rectangle((x - width, y, x, y + 48), 24, fill)
    text(draw, (x - width / 2, y + 24), label, 20, color, True, "mm")


def base(title, subtitle, screen):
    image = fit_bg()
    overlay = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    od = ImageDraw.Draw(overlay)
    od.rectangle((0, 0, W, H), fill=(244, 252, 250, 172))
    image = Image.alpha_composite(image.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(image)
    logo = Image.open(ROOT / "hl-logo.png").convert("RGBA").resize((76, 76))
    image.alpha_composite(logo, (85, 76))
    text(draw, (185, 115), "HOÀNG LONG TNT", 30, "#5B2E24", True, "lm")
    text(draw, (W // 2, 250), title, 78, "#073F39", True, "ma", 2)
    text(draw, (W // 2, 465), subtitle, 32, "#47645F", False, "ma", 4)
    phone = (105, 650, 1215, 2710)
    draw.rounded_rectangle(phone, 94, "#17211F")
    inner = (127, 672, 1193, 2688)
    draw.rounded_rectangle(inner, 74, "#F6F8FB")
    draw.rounded_rectangle((495, 687, 825, 748), 31, "#111111")
    draw.rectangle((127, 748, 1193, 850), fill=WHITE)
    text(draw, (175, 810), screen, 35, DARK, True, "lm")
    text(draw, (1135, 810), "●  ☰", 26, TEAL, True, "rm")
    draw.rectangle((127, 2575, 1193, 2688), fill=WHITE)
    for x, label in zip((230, 500, 780, 1050), ("Trang chủ", "Đơn hàng", "Kho", "Tài khoản")):
        text(draw, (x, 2632), label, 20, TEAL if x == 230 else SLATE, x == 230, "mm")
    return image, draw


def metric(draw, x, y, value, label):
    card(draw, (x, y, x + 475, y + 240))
    draw.rounded_rectangle((x + 28, y + 28, x + 92, y + 92), 18, "#E5F7F2")
    text(draw, (x + 60, y + 60), "✓", 29, TEAL, True, "mm")
    text(draw, (x + 28, y + 132), value, 50, DARK, True)
    text(draw, (x + 28, y + 194), label, 23, SLATE)


def row(draw, y, number, name, detail, status, status_fill="#FEF3C7", status_color="#92400E"):
    card(draw, (165, y, 1155, y + 250))
    draw.ellipse((195, y + 38, 255, y + 98), fill="#F59E0B")
    text(draw, (225, y + 68), str(number), 25, WHITE, True, "mm")
    text(draw, (280, y + 45), name, 29, DARK, True)
    text(draw, (280, y + 88), detail, 21, SLATE)
    badge(draw, 1115, y + 38, status, status_fill, status_color)


slides = [
    ("Một ứng dụng\ncho toàn bộ vận hành", "Theo dõi công việc, đơn hàng và tiến độ theo từng vai trò.", "Dashboard"),
    ("Xử lý đơn hàng\nnhanh và rõ ràng", "Ưu tiên công việc và cập nhật trạng thái ngay trên điện thoại.", "Đơn cần đóng gói"),
    ("Tồn kho hợp nhất\ngiữa mọi kho", "Nắm rõ tồn đầu, nhập, xuất, book và available trong một màn hình.", "Tồn kho tổng hợp"),
    ("Điều chuyển và giao nhận\nkhông gián đoạn", "Phối hợp kho và shipper theo từng trạng thái bàn giao.", "Điều chuyển kho"),
    ("Báo cáo tức thời\nquyết định nhanh hơn", "Theo dõi hiệu suất và sản lượng mọi lúc, mọi nơi.", "Báo cáo vận hành"),
    ("Đăng nhập an toàn\nđầy đủ thông tin hỗ trợ", "Footer hiển thị liên hệ, chính sách bảo mật và copyright rõ ràng.", "Đăng nhập"),
]

for idx, (title, subtitle, screen) in enumerate(slides, 1):
    image, draw = base(title, subtitle, screen)
    if idx == 1:
        text(draw, (165, 910), "Xin chào,", 25, SLATE)
        text(draw, (165, 950), "Quản lý vận hành", 38, DARK, True)
        metric(draw, 165, 1040, "48", "Đơn hôm nay")
        metric(draw, 680, 1040, "12", "Đang đóng gói")
        metric(draw, 165, 1310, "26", "Đang giao hàng")
        metric(draw, 680, 1310, "97%", "Hoàn thành đúng hạn")
        text(draw, (165, 1615), "TIẾN ĐỘ CÔNG VIỆC", 28, "#5B2E24", True)
        card(draw, (165, 1680, 1155, 2370))
        for n, label, pct, y in ((1, "Đơn cần đóng gói", 75, 1740), (2, "Tiếp nhận hàng", 80, 1940), (3, "Điều chuyển kho", 100, 2140)):
            draw.ellipse((205, y, 265, y + 60), fill=TEAL)
            text(draw, (235, y + 30), str(n), 24, WHITE, True, "mm")
            text(draw, (295, y + 5), label, 27, DARK, True)
            text(draw, (1080, y + 8), f"{pct}%", 24, TEAL, True, "rm")
            draw.rounded_rectangle((295, y + 62, 1080, y + 80), 9, "#E5E7EB")
            draw.rounded_rectangle((295, y + 62, 295 + 785 * pct / 100, y + 80), 9, "#16A34A")
    elif idx == 2:
        row(draw, 930, 1, "Nguyễn Minh Anh", "#OD178132852286 · Hôm nay 08:32", "Đang đóng")
        row(draw, 1220, 2, "Trần Hoàng Nam", "#OD178132852445 · Hôm nay 09:10", "Chờ xử lý", "#DBEAFE", "#1D4ED8")
        row(draw, 1510, 3, "Công ty Minh Phát", "#OD178132852518 · Hôm nay 09:24", "Đã đóng", "#DCFCE7", "#15803D")
        card(draw, (165, 1800, 1155, 2320))
        text(draw, (205, 1850), "CHI TIẾT ĐƠN ƯU TIÊN #1", 26, "#5B2E24", True)
        for y, name, qty in ((1930, "Tôm sú size 20", "12 kg"), (2030, "Mực ống loại 1", "8 kg"), (2130, "Cá hồi phi lê", "15 kg")):
            draw.line((205, y + 70, 1115, y + 70), fill="#E5E7EB", width=2)
            text(draw, (205, y), name, 25)
            text(draw, (1115, y), qty, 25, TEAL, True, "ra")
    elif idx == 3:
        metric(draw, 165, 930, "2.886", "Tổng tồn cuối")
        metric(draw, 680, 930, "2.778", "Available")
        text(draw, (165, 1230), "CHI TIẾT TỒN KHO", 28, "#5B2E24", True)
        card(draw, (165, 1295, 1155, 2250))
        cols = [205, 650, 790, 930, 1095]
        for x, label in zip(cols, ("Sản phẩm", "Kho 1", "Kho 2", "Book", "Available")):
            text(draw, (x, 1360), label, 20, TEAL, True, "ra" if x != 205 else None)
        for i, vals in enumerate((("Tôm sú",420,315,35,700),("Mực ống",286,190,18,458),("Cá hồi",175,240,25,390),("Bạch tuộc",198,156,12,342),("Cua biển",120,95,8,207))):
            y = 1455 + i * 145
            draw.line((205, y + 80, 1115, y + 80), fill="#E5E7EB", width=2)
            text(draw, (205, y), vals[0], 25, DARK, True)
            for x, val, color in zip(cols[1:], vals[1:], (DARK,DARK,"#1D4ED8","#15803D")):
                text(draw, (x, y), str(val), 24, color, val in (vals[3], vals[4]), "ra")
    elif idx == 4:
        row(draw, 930, 1, "Phiếu #26 · 8 đơn", "Kho Long An  →  Kho Chiến Lược", "Chờ nhận")
        row(draw, 1220, 2, "Phiếu #25 · 16 đơn", "Kho Chiến Lược  →  Kho Long An", "Đang giao", "#DBEAFE", "#1D4ED8")
        row(draw, 1510, 3, "Phiếu #24 · 5 đơn", "Tiếp nhận lúc 10:42", "Hoàn tất", "#DCFCE7", "#15803D")
        text(draw, (165, 1835), "CẬP NHẬT THEO THỜI GIAN THỰC", 28, "#5B2E24", True)
        card(draw, (165, 1900, 1155, 2310))
        for n, label, value, y in (("✓","Kho nguồn bàn giao","08:30",1960),("✓","Shipper nhận hàng","09:05",2070),("3","Kho đích chờ tiếp nhận","Đang chờ",2180)):
            draw.ellipse((205,y,260,y+55),fill=TEAL)
            text(draw,(232,y+27),n,22,WHITE,True,"mm")
            text(draw,(290,y+4),label,25,DARK,True)
            text(draw,(1110,y+5),value,22,SLATE,False,"ra")
    elif idx == 5:
        metric(draw, 165, 930, "+18%", "Sản lượng tuần này")
        metric(draw, 680, 930, "96%", "Đơn hoàn thành")
        text(draw, (165, 1230), "SẢN LƯỢNG 7 NGÀY", 28, "#5B2E24", True)
        card(draw, (165, 1295, 1155, 1840))
        heights = (180,260,220,340,300,410,370)
        for i, h in enumerate(heights):
            x = 225 + i * 125
            draw.rounded_rectangle((x, 1760 - h, x + 70, 1760), 14, "#37B9A7")
        text(draw, (165, 1905), "TỔNG QUAN HÔM NAY", 28, "#5B2E24", True)
        card(draw, (165, 1970, 1155, 2390))
        for y, label, value in ((2025,"Đơn đã đóng gói","42"),(2120,"Đơn đang vận chuyển","26"),(2215,"Phiếu điều chuyển hoàn tất","12"),(2310,"Tồn kho khả dụng","2.778")):
            text(draw,(205,y),label,25)
            text(draw,(1115,y),value,26,TEAL,True,"ra")
    else:
        logo = Image.open(ROOT / "hl-logo.png").convert("RGBA").resize((130, 130))
        image.alpha_composite(logo, (595, 915))
        text(draw, (660, 1095), "Hoàng Long TNT", 38, "#083F3A", True, "ma")
        text(draw, (660, 1155), "Đăng nhập hệ thống vận hành", 25, SLATE, False, "ma")
        card(draw, (190, 1240, 1130, 2025), fill="#FFFFFF", outline="#FFFFFF", radius=34)
        draw.rounded_rectangle((240, 1305, 300, 1365), 16, "#E5F7F2")
        text(draw, (270, 1335), "✓", 28, TEAL, True, "mm")
        text(draw, (330, 1300), "Chào mừng trở lại", 29, DARK, True)
        text(draw, (330, 1344), "Sử dụng tài khoản được cấp", 23, SLATE)
        for y, label in ((1450, "Số điện thoại hoặc email"), (1585, "Mật khẩu")):
            draw.rounded_rectangle((240, y, 1080, y + 86), 18, "#F8FAFC", "#E2E8F0", width=2)
            text(draw, (280, y + 43), "•", 30, TEAL, True, "lm")
            text(draw, (335, y + 43), label, 24, "#475569", False, "lm")
        draw.rectangle((250, 1718, 286, 1754), fill="#FFFFFF", outline=TEAL, width=3)
        text(draw, (310, 1736), "Ghi nhớ đăng nhập", 23, DARK, False, "lm")
        draw.rounded_rectangle((240, 1820, 1080, 1905), 22, TEAL)
        text(draw, (660, 1862), "Đăng nhập", 27, WHITE, True, "mm")
        text(draw, (660, 2110), "Liên hệ hỗ trợ  ·  Chính sách bảo mật", 25, TEAL, True, "ma")
        text(draw, (660, 2160), "Copyright © 2026 Hoang Long TNT", 21, SLATE, True, "ma")
        card(draw, (190, 2240, 1130, 2415), fill="#ECFDF5", outline="#BBF7D0", radius=28)
        text(draw, (235, 2288), "Thông tin minh bạch cho người dùng", 27, "#065F46", True)
        text(draw, (235, 2340), "Có sẵn đường dẫn liên hệ hỗ trợ và chính sách quyền riêng tư trước khi đăng nhập.", 22, "#047857")
    image.convert("RGB").save(OUT / f"0{idx}.png", quality=96)
    print(OUT / f"0{idx}.png")
