# ⚙️ Advanced Expense Allocation Engine

ဤ Engine သည် ကျောက်မျက် Lot များကို ခွဲထုတ်ရာတွင် ကုန်ကျစရိတ်များကို တိကျစွာ ခွဲဝေတွက်ချက်ရန် ဒီဇိုင်းထုတ်ထားခြင်း ဖြစ်သည်။

## ၁။ Mathematical Logic (တွက်ချက်မှု ပုံသေနည်းများ)

### က။ အလေးချိန်အလိုက် ခွဲဝေခြင်း (Proportional to Weight)
Lot တစ်ခုလုံး၏ ဝယ်ဈေးကို ကျောက်တစ်လုံးချင်းစီ၏ အလေးချိန်အချိုးဖြင့် ခွဲဝေသည်။
> `Stone Cost = (Stone Weight / Total Lot Weight) * Total Lot Price`

### ခ။ လက်ရွေးစင် (Premium) ကျောက်များအတွက် ခွဲဝေခြင်း
အချို့ကျောက်များသည် အခြားကျောက်များထက် အရည်အသွေး ပိုကောင်းပါက Manual အချိုးသတ်မှတ်နိုင်သည်။
> `Stone Cost = Total Lot Price * (Premium % / 100)`

### ဂ။ အလေအလွင့် (Waste) ကို ကိုင်တွယ်ခြင်း
Waste ဖြစ်သွားသော ကျောက်၏ တန်ဖိုးကို ကျန်ရှိသော ကျောက်များပေါ်သို့ ပြန်လည်ခွဲဝေခြင်း (သို့မဟုတ်) အရှုံးအဖြစ် သီးခြားပြသခြင်း။
> `Recalculated Cost = Original Stone Cost + (Waste Cost / Remaining Stones Count)`

---

## ၂။ Backend Calculation Service (Node.js)

```javascript
// backend/services/allocation.service.js
class AllocationEngine {
  /**
   * Calculate costs for split stones
   * @param {number} totalLotPrice - မူလ Lot ဝယ်ဈေး
   * @param {Array} stones - ခွဲထုတ်မည့် ကျောက်များစာရင်း [{weight, isPremium, manualPrice}]
   */
  static allocateCosts(totalLotPrice, stones) {
    const totalWeight = stones.reduce((sum, s) => sum + s.weight, 0);
    
    return stones.map(stone => {
      let allocatedPrice;
      if (stone.manualPrice) {
        allocatedPrice = stone.manualPrice;
      } else {
        // အလေးချိန်အလိုက် ခွဲဝေခြင်း
        allocatedPrice = (stone.weight / totalWeight) * totalLotPrice;
      }
      return { ...stone, allocatedPrice };
    });
  }
}
```

---

## ၃။ Database Flow (Data Integrity)

၁။ **Start Transaction**: စာရင်းအမှားအယွင်း မရှိစေရန် Transaction စတင်သည်။
၂။ **Deduct from Lot**: မူလ Lot ၏ လက်ကျန်အလေးချိန်နှင့် တန်ဖိုးကို နှုတ်သည်။
၃။ **Create Gemstones**: ခွဲထုတ်လိုက်သော ကျောက်များကို `gemstones` table တွင် အသစ်တည်ဆောက်ပြီး `lot_id` ချိတ်ဆက်သည်။
၄။ **Record Expenses**: ခွဲဝေလိုက်သော စရိတ်များကို `expenses` table တွင် `type = 'ALLOCATION'` ဖြင့် မှတ်တမ်းတင်သည်။
၅။ **Commit**: အားလုံးမှန်ကန်မှ Database တွင် အတည်ပြုသည်။

---

## ၄။ Flutter Implementation Strategy

- **Interactive Slider**: အသုံးပြုသူသည် ကျောက်တစ်လုံးချင်းစီ၏ တန်ဖိုးအချိုးကို Slider ဖြင့် အလွယ်တကူ ညှိနှိုင်းနိုင်သည်။
- **Real-time Preview**: တန်ဖိုးတစ်ခု ပြောင်းလိုက်တိုင်း ကျန်ရှိသော ကျောက်များ၏ တန်ဖိုးပြောင်းလဲမှုကို ချက်ချင်းမြင်ရမည်။
- **Validation Warning**: ခွဲဝေလိုက်သော ပေါင်းလဒ်သည် မူလ Lot တန်ဖိုးထက် ကျော်လွန်နေပါက သတိပေးချက်ပြမည်။

---

## ၅။ Profit/Loss Tracking (ရေရှည်ခြေရာခံခြင်း)

- **Cost Basis Persistence**: ကျောက်တစ်လုံးကို ရောင်းလိုက်သည့်အခါ ၎င်း၏ ခွဲဝေရရှိထားသော `allocatedPrice` ကို အခြေခံ၍ အမြတ်တွက်သည်။
- **Partial Sales Support**: Lot တစ်ခုလုံး မကုန်မချင်း အမြတ်အစွန်းကို `Realized Profit` (ရောင်းပြီးသား) နှင့် `Unrealized Profit` (လက်ကျန်ကျောက်များ၏ ခန့်မှန်းတန်ဖိုး) ဟု ခွဲခြားပြသမည်။
