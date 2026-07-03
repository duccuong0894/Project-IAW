// Tra cứu thư tịch — hiển thị kết quả qua modal popup.
async function doSearch() {
  const query = document.getElementById('q').value;
  const r = await fetch(`/search?q=${encodeURIComponent(query)}`);
  const data = await r.json();

  showModal(data, { title: 'Kết quả tra cứu' });
}

// Trả về một dòng trạng thái đơn giản — không bao giờ lộ nội dung bản ghi
// hay chi tiết lỗi SQL.
function buildMessage(data) {
  if (data && data.error) {
    // Chi tiết lỗi SQL vẫn nằm trong response (tab Network) để enumerate cột.
    return '⚠ Kho lưu trữ gặp sự cố khi xử lý truy vấn tìm kiếm.';
  }

  const results = (data && data.results) || [];
  if (results.length === 0) {
    return 'Không tìm thấy thư tịch nào khớp với từ khoá.';
  }
  return `Tìm thấy ${results.length} thư tịch trong kho lưu trữ.`;
}
