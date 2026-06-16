from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
OUT = ROOT.parent / "upload-ready" / "ipad-13"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 2048, 2732
TEAL = "#0D7A70"
DARK = "#0F172A"
SLATE = "#64748B"
BROWN = "#5B2E24"
WHITE = "#FFFFFF"
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size, bold=False):
    return ImageFont.truetype(BOLD if bold else FONT, size)


def bg():
    source = Image.open(ROOT / "marketing-background.png").convert("RGB")
    ratio = max(W / source.width, H / source.height)
    source = source.resize((int(source.width * ratio), int(source.height * ratio)))
    left = (source.width - W) // 2
    top = (source.height - H) // 2
    source = source.crop((left, top, left + W, top + H)).filter(ImageFilter.GaussianBlur(2))
    overlay = Image.new("RGBA", (W, H), (246, 253, 250, 204))
    return Image.alpha_composite(source.convert("RGBA"), overlay)


def draw_text(draw, xy, value, size, color=DARK, bold=False, anchor=None, align="left", spacing=10):
    draw.multiline_text(
        xy,
        value,
        font=font(size, bold),
        fill=color,
        anchor=anchor,
        align=align,
        spacing=spacing,
    )


def card(draw, box, fill=WHITE, outline="#E2E8F0", radius=28):
    draw.rounded_rectangle(box, radius, fill, outline, width=2)


def badge(draw, box, label, fill="#DCFCE7", color="#15803D"):
    draw.rounded_rectangle(box, 22, fill)
    draw_text(draw, ((box[0] + box[2]) // 2, (box[1] + box[3]) // 2), label, 24, color, True, "mm", "center")


def frame(title, subtitle, screen):
    image = bg()
    draw = ImageDraw.Draw(image)
    logo = Image.open(ROOT / "hl-logo.png").convert("RGBA").resize((92, 92))
    image.alpha_composite(logo, (104, 88))
    draw_text(draw, (220, 134), "HOÀNG LONG TNT", 36, BROWN, True, "lm")
    draw_text(draw, (W // 2, 290), title, 76, "#073F39", True, "ma", "center", 8)
    draw_text(draw, (W // 2, 478), subtitle, 32, "#47645F", False, "ma", "center", 6)

    tablet = (120, 620, 1928, 2572)
    draw.rounded_rectangle(tablet, 74, "#17211F")
    inner = (148, 648, 1900, 2544)
    draw.rounded_rectangle(inner, 50, "#F6F8FB")

    draw.rectangle((148, 648, 1900, 776), fill=WHITE)
    draw_text(draw, (218, 714), screen, 38, DARK, True, "lm")
    draw_text(draw, (1830, 714), "●  ☰", 30, TEAL, True, "rm")
    draw.rectangle((148, 776, 482, 2544), fill="#ECFDF8")
    for i, label in enumerate(("Dashboard", "Đơn hàng", "Kho", "Giao nhận", "Báo cáo")):
        y = 860 + i * 112
        fill = TEAL if i == 0 else "#D7F3EC"
        color = WHITE if i == 0 else "#31534E"
        draw.rounded_rectangle((188, y, 442, y + 70), 22, fill)
        draw_text(draw, (315, y + 35), label, 24, color, True, "mm", "center")
    return image, draw


def metric(draw, box, value, label, icon="✓"):
    card(draw, box)
    x1, y1, x2, _ = box
    draw.rounded_rectangle((x1 + 28, y1 + 28, x1 + 92, y1 + 92), 18, "#E5F7F2")
    draw_text(draw, (x1 + 60, y1 + 60), icon, 30, TEAL, True, "mm", "center")
    draw_text(draw, (x1 + 28, y1 + 142), value, 50, DARK, True)
    draw_text(draw, (x1 + 28, y1 + 206), label, 24, SLATE)


def order_row(draw, y, number, name, detail, status, fill="#FEF3C7", color="#92400E"):
    card(draw, (542, y, 1824, y + 190))
    draw.ellipse((582, y + 42, 642, y + 102), fill="#F59E0B")
    draw_text(draw, (612, y + 72), str(number), 24, WHITE, True, "mm", "center")
    draw_text(draw, (682, y + 42), name, 30, DARK, True)
    draw_text(draw, (682, y + 86), detail, 22, SLATE)
    badge(draw, (1580, y + 44, 1780, y + 92), status, fill, color)


def slide_dashboard():
    image, draw = frame(
        "Vận hành iPad\nrõ ràng trên một màn hình",
        "Theo dõi đơn hàng, đóng gói, giao nhận và báo cáo theo từng vai trò.",
        "Dashboard vận hành",
    )
    metric(draw, (542, 850, 940, 1090), "48", "Đơn hôm nay", "✓")
    metric(draw, (980, 850, 1378, 1090), "12", "Đang đóng gói", "▣")
    metric(draw, (1418, 850, 1816, 1090), "97%", "Hoàn thành", "↗")
    card(draw, (542, 1140, 1816, 1580))
    draw_text(draw, (590, 1200), "TIẾN ĐỘ CÔNG VIỆC", 28, BROWN, True)
    for idx, (label, pct, y) in enumerate((("Đơn cần đóng gói", 75, 1280), ("Tiếp nhận hàng", 80, 1395), ("Điều chuyển kho", 100, 1510)), 1):
        draw.ellipse((590, y, 648, y + 58), fill=TEAL)
        draw_text(draw, (619, y + 29), str(idx), 22, WHITE, True, "mm", "center")
        draw_text(draw, (680, y + 4), label, 27, DARK, True)
        draw_text(draw, (1748, y + 4), f"{pct}%", 24, TEAL, True, "ra")
        draw.rounded_rectangle((680, y + 58, 1748, y + 76), 9, "#E5E7EB")
        draw.rounded_rectangle((680, y + 58, 680 + int(1068 * pct / 100), y + 76), 9, "#16A34A")
    card(draw, (542, 1630, 1816, 2328))
    draw_text(draw, (590, 1690), "TỔNG QUAN HÔM NAY", 28, BROWN, True)
    for y, label, value in ((1775, "Đơn mới cần xử lý", "18"), (1885, "Đang giao hàng", "26"), (1995, "Phiếu điều chuyển", "6"), (2105, "Tồn kho khả dụng", "2.778")):
        draw.line((590, y + 70, 1768, y + 70), fill="#E5E7EB", width=2)
        draw_text(draw, (590, y), label, 28, DARK)
        draw_text(draw, (1768, y), value, 30, TEAL, True, "ra")
    return image


def slide_orders():
    image, draw = frame(
        "Xử lý đơn hàng\nnhanh và chính xác",
        "Danh sách ưu tiên giúp sale, kho và đóng gói phối hợp không bỏ sót.",
        "Đơn cần đóng gói",
    )
    order_row(draw, 850, 1, "Nguyễn Minh Anh", "#OD178132852286 · Hôm nay 08:32", "Đang đóng")
    order_row(draw, 1085, 2, "Trần Hoàng Nam", "#OD178132852445 · Hôm nay 09:10", "Chờ xử lý", "#DBEAFE", "#1D4ED8")
    order_row(draw, 1320, 3, "Công ty Minh Phát", "#OD178132852518 · Hôm nay 09:24", "Đã đóng", "#DCFCE7", "#15803D")
    card(draw, (542, 1600, 1816, 2310))
    draw_text(draw, (590, 1660), "CHI TIẾT ĐƠN ƯU TIÊN #1", 28, BROWN, True)
    for y, name, qty in ((1750, "Tôm sú size 20", "12 kg"), (1858, "Mực ống loại 1", "8 kg"), (1966, "Cá hồi phi lê", "15 kg"), (2074, "Bạch tuộc", "6 kg")):
        draw.line((590, y + 70, 1768, y + 70), fill="#E5E7EB", width=2)
        draw_text(draw, (590, y), name, 28, DARK, True)
        draw_text(draw, (1768, y), qty, 28, TEAL, True, "ra")
    return image


def slide_inventory():
    image, draw = frame(
        "Tồn kho hợp nhất\ngiữa nhiều kho",
        "Theo dõi tồn đầu, nhập, xuất, book và available trên màn hình rộng.",
        "Tồn kho tổng hợp",
    )
    metric(draw, (542, 850, 940, 1090), "2.886", "Tổng tồn cuối", "▣")
    metric(draw, (980, 850, 1378, 1090), "2.778", "Available", "✓")
    metric(draw, (1418, 850, 1816, 1090), "108", "Đang book", "●")
    card(draw, (542, 1160, 1816, 2280))
    draw.rounded_rectangle((590, 1228, 1768, 1300), 18, TEAL)
    headers = ("Sản phẩm", "Kho 1", "Kho 2", "Book", "Available")
    xs = (620, 1120, 1300, 1480, 1725)
    for x, h in zip(xs, headers):
        draw_text(draw, (x, 1264), h, 22, WHITE, True, "rm" if x != 620 else "lm")
    rows = (("Tôm sú", 420, 315, 35, 700), ("Mực ống", 286, 190, 18, 458), ("Cá hồi", 175, 240, 25, 390), ("Bạch tuộc", 198, 156, 12, 342), ("Cua biển", 120, 95, 8, 207), ("Ghẹ xanh", 96, 88, 10, 174))
    for i, vals in enumerate(rows):
        y = 1368 + i * 130
        draw.line((590, y + 76, 1768, y + 76), fill="#E5E7EB", width=2)
        draw_text(draw, (620, y), vals[0], 28, DARK, True)
        for x, val, color in zip(xs[1:], vals[1:], (DARK, DARK, "#1D4ED8", "#15803D")):
            draw_text(draw, (x, y), str(val), 26, color, val in (vals[3], vals[4]), "ra")
    return image


def slide_transfers():
    image, draw = frame(
        "Điều chuyển và giao nhận\nkhông gián đoạn",
        "Theo dõi bàn giao kho, shipper và kho nhận bằng trạng thái rõ ràng.",
        "Điều chuyển kho",
    )
    order_row(draw, 850, 1, "Phiếu #26 · 8 đơn", "Kho Long An → Kho Chiến Lược", "Chờ nhận")
    order_row(draw, 1085, 2, "Phiếu #25 · 16 đơn", "Kho Chiến Lược → Kho Long An", "Đang giao", "#DBEAFE", "#1D4ED8")
    order_row(draw, 1320, 3, "Phiếu #24 · 5 đơn", "Tiếp nhận lúc 10:42", "Hoàn tất", "#DCFCE7", "#15803D")
    card(draw, (542, 1600, 1816, 2288))
    draw_text(draw, (590, 1660), "CẬP NHẬT THEO THỜI GIAN THỰC", 28, BROWN, True)
    for n, label, value, y in (("✓", "Kho nguồn bàn giao", "08:30", 1760), ("✓", "Shipper nhận hàng", "09:05", 1885), ("3", "Kho đích chờ tiếp nhận", "Đang chờ", 2010)):
        draw.ellipse((590, y, 650, y + 60), fill=TEAL)
        draw_text(draw, (620, y + 30), n, 23, WHITE, True, "mm", "center")
        draw_text(draw, (690, y + 6), label, 29, DARK, True)
        draw_text(draw, (1768, y + 6), value, 26, SLATE, False, "ra")
    return image


def slide_reports():
    image, draw = frame(
        "Báo cáo tức thời\nra quyết định nhanh hơn",
        "Theo dõi sản lượng, tiến độ và hiệu suất vận hành ngay trên iPad.",
        "Báo cáo vận hành",
    )
    metric(draw, (542, 850, 940, 1090), "+18%", "Sản lượng tuần", "↗")
    metric(draw, (980, 850, 1378, 1090), "96%", "Đơn hoàn thành", "✓")
    metric(draw, (1418, 850, 1816, 1090), "42", "Đã đóng gói", "▣")
    card(draw, (542, 1160, 1816, 1720))
    draw_text(draw, (590, 1220), "SẢN LƯỢNG 7 NGÀY", 28, BROWN, True)
    heights = (170, 250, 220, 340, 300, 420, 370)
    for i, h in enumerate(heights):
        x = 660 + i * 145
        draw.rounded_rectangle((x, 1640 - h, x + 80, 1640), 16, "#37B9A7")
        draw_text(draw, (x + 40, 1600 - h), str((32, 45, 40, 58, 52, 67, 61)[i]), 22, TEAL, True, "mm", "center")
    card(draw, (542, 1785, 1816, 2300))
    draw_text(draw, (590, 1845), "TỔNG QUAN HÔM NAY", 28, BROWN, True)
    for y, label, value in ((1935, "Đơn đã đóng gói", "42"), (2042, "Đơn đang vận chuyển", "26"), (2149, "Phiếu điều chuyển hoàn tất", "12")):
        draw.line((590, y + 70, 1768, y + 70), fill="#E5E7EB", width=2)
        draw_text(draw, (590, y), label, 28, DARK)
        draw_text(draw, (1768, y), value, 30, TEAL, True, "ra")
    return image


slides = [
    ("01-dashboard.png", slide_dashboard),
    ("02-orders.png", slide_orders),
    ("03-inventory.png", slide_inventory),
    ("04-transfers.png", slide_transfers),
    ("05-reports.png", slide_reports),
]

for filename, renderer in slides:
    path = OUT / filename
    renderer().convert("RGB").save(path, quality=96)
    print(path)
