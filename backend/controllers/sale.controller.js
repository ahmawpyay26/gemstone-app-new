const Sale = require('../models/Sale');
const SaleItem = require('../models/SaleItem');
const Gemstone = require('../models/Gemstone');
const sequelize = require('../config/database');

exports.createSale = async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { customer_name, broker_id, broker_commission, items } = req.body;
    
    let total_amount = 0;
    items.forEach(item => total_amount += parseFloat(item.sale_price));

    const sale = await Sale.create({
      invoice_number: `INV-${Date.now()}`,
      customer_name,
      total_amount,
      broker_id,
      broker_commission,
      created_by: req.user.userId
    }, { transaction: t });

    for (const item of items) {
      await SaleItem.create({
        sale_id: sale.id,
        gemstone_id: item.gemstone_id,
        sale_price: item.sale_price
      }, { transaction: t });

      // Update gemstone status to sold
      await Gemstone.update(
        { status: 'sold' },
        { where: { id: item.gemstone_id }, transaction: t }
      );
    }

    await t.commit();
    res.status(201).json({ status: 'success', data: sale });
  } catch (err) {
    await t.rollback();
    res.status(500).json({ status: 'error', message: err.message });
  }
};

exports.getAllSales = async (req, res) => {
  try {
    const sales = await Sale.findAll({ order: [['sale_date', 'DESC']] });
    res.status(200).json({ status: 'success', data: sales });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
};
