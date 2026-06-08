-- Gemstone Management System - Realistic Dummy Data (Myanmar Context)

-- 1. Workers
INSERT INTO workers (name, role, phone, daily_rate) VALUES
('U Kyaw', 'Master Cutter', '09123456789', 25000),
('Ko Hla', 'Polisher', '09987654321', 15000),
('Ma Su', 'Sorter', '09445566778', 12000);

-- 2. Brokers
INSERT INTO brokers (name, phone, commission_rate) VALUES
('U Myော်', '09778899001', 2.0),
('Daw Nu', '09665544332', 1.5);

-- 3. Lots (Bulk Purchase)
INSERT INTO lots (name, purchase_price, total_weight, origin, purchase_date) VALUES
('Mong Hsu Ruby Rough Lot #001', 5000000, 150.5, 'Mong Hsu', '2024-01-15'),
('Mogok Spinel Lot #002', 2500000, 80.0, 'Mogok', '2024-02-10');

-- 4. Gemstones (Individual & Split from Lots)
INSERT INTO gemstones (name, type, carat_weight, purchase_price, status, lot_id, qr_code) VALUES
('Mogok Pigeon Blood Ruby', 'Ruby', 2.5, 3500000, 'Available', NULL, 'QR-RB-001'),
('Royal Blue Sapphire', 'Sapphire', 4.2, 5000000, 'Processing', NULL, 'QR-SP-002'),
('Mong Hsu Split Stone A1', 'Ruby', 1.2, 450000, 'Available', 1, 'QR-LOT1-A1'),
('Mong Hsu Split Stone A2', 'Ruby', 0.8, 300000, 'Sold', 1, 'QR-LOT1-A2');

-- 5. Expenses
INSERT INTO expenses (gemstone_id, type, amount, description, date) VALUES
(1, 'Cutting', 50000, 'Master cutting fee for Pigeon Blood', '2024-01-20'),
(2, 'Polishing', 30000, 'Initial polishing for Sapphire', '2024-02-15'),
(1, 'Certification', 150000, 'GIA Certification fee', '2024-02-01');

-- 6. Sales
INSERT INTO sales (gemstone_id, sale_price, broker_id, commission_amount, sale_date, customer_name) VALUES
(4, 850000, 1, 17000, '2024-03-01', 'U Ba');

-- 7. Waste Stones
INSERT INTO waste_stones (lot_id, gemstone_id, weight, reason, loss_value) VALUES
(1, NULL, 5.5, 'Cracked during initial cutting', 50000);
