// Các hằng số cấu hình phục vụ cho việc giả lập gỡ lỗi (Debug Simulation) của ứng dụng Remind Spend.

/// Danh sách tin nhắn biến động số dư ngân hàng giả lập mẫu để kiểm thử.
const smsPresets = [
  ('MB credit',      'Ban da nhan 100,000d tu ngan hang MB'),
  ('MB debit',       'chi 50,000d phi dich vu MB'),
  ('VCB credit',     'GD: +1,234,567 VND. So du: 10,000,000VND'),
  ('VCB debit',      'GD: -250,000 VND. So du: 9,750,000VND'),
  ('TCB credit',     'GD: +500,000 VND vao TK Techcombank'),
  ('BIDV credit',    'Tang 300,000 VND vao TK BIDV'),
  ('MoMo credit',    'Ban da nhan 75,000d tu Nguyen Van A qua MoMo'),
  ('ZaloPay credit', 'Ban da nhan 50,000d tu B qua ZaloPay'),
];
