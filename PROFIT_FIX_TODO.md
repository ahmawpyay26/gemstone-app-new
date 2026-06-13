# Profit/Loss Capital Logic Fix

- [x] Fix `grossProfit()` double-counting bug in local_db.dart (capital = remaining inventory + sold goods cost, counted once)
- [x] Add `totalOriginalCapital()` = remaining inventory cost + sold goods cost (fixed pool)
- [x] Update Sales page summary cards: no loss bigger than capital; show remaining capital instead of loss
- [x] Update Dashboard: net profit 0 until sales >= original capital; remaining capital box
- [x] Update per-sale profit badge to reflect capital-recoupment logic
- [x] Commit and push to GitHub
