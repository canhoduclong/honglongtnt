# App Store Assets

## Screenshots sẵn sàng tải lên

Tải 5 ảnh trong `upload-ready/iphone-6.7/` lên App Store Connect. Toàn bộ ảnh có
kích thước portrait `1284x2778`, nằm trong danh sách kích thước Apple chấp nhận:

- `01-dashboard.png`
- `02-orders.png`
- `03-inventory.png`
- `04-transfers.png`
- `05-reports.png`

Không tải thư mục `screenshots/iphone-6.9/` lên form hiện tại vì ảnh trong đó có
kích thước `1320x2868`, không thuộc các kích thước mà App Store Connect đang yêu cầu.

Apple cho phép tối đa 10 screenshot, nhưng không bắt buộc đủ 10 ảnh. Bộ 5 ảnh hiện
tại đã bao quát các tính năng chính và có thể dùng để gửi duyệt.

File `upload-ready/hoang-long-tnt-app-store-screenshots.zip` chứa cùng bộ 5 ảnh
để lưu trữ hoặc chuyển sang máy dùng App Store Connect.

Các ảnh là marketing mockup dựa trên giao diện và tính năng hiện có của ứng dụng.
Trước khi gửi duyệt, kiểm tra nội dung hiển thị phù hợp với bản build phát hành.

## Nội dung App Store

Nội dung có thể dán trực tiếp vào App Store Connect nằm trong
`APP_STORE_METADATA_VI.md`, gồm:

- Tên ứng dụng và phụ đề
- Promotional Text
- Mô tả
- Keywords
- What's New
- Support URL, Marketing URL và Privacy Policy URL
- App Review Information

## Files

- `APP_STORE_METADATA_VI.md`: Nội dung đề xuất để điền App Store Connect.
- `upload-ready/iphone-6.7/`: Bộ 5 screenshot đúng kích thước để tải lên.
- `upload-ready/hoang-long-tnt-app-store-screenshots.zip`: File nén của bộ screenshot.
- `source/store_screenshots.html`: Nguồn dựng screenshot.
- `source/marketing-background.png`: Nền marketing tạo bằng imagegen.
- `source/hl-logo.png`: Logo sử dụng trong screenshot.
