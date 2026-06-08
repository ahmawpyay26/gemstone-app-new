const Expense = require('../models/Expense');
const Gemstone = require('../models/Gemstone');
const sequelize = require('../config/database');

exports.createExpense = async (req, res) => {
  const t = await sequelize.transaction();
  try {
    const { gemstone_id, amount } = req.body;
    
    const expense = await Expense.create({
      ...req.body,
      created_by: req.user.userId
    }, { transaction: t });

    // Update gemstone total cost
    const gemstone = await Gemstone.findByPk(gemstone_id, { transaction: t });
    if (gemstone) {
      await gemstone.update({
        total_cost: parseFloat(gemstone.total_cost || 0) + parseFloat(amount)
      }, { transaction: t });
    }

    await t.commit();
    res.status(201).json({ status: 'success', data: expense });
  } catch (err) {
    await t.rollback();
    res.status(500).json({ status: 'error', message: err.message });
  }
};

exports.getGemstoneExpenses = async (req, res) => {
  try {
    const expenses = await Expense.findAll({
      where: { gemstone_id: req.params.gemstoneId },
      order: [['expense_date', 'DESC']]
    });
    res.status(200).json({ status: 'success', data: expenses });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
};
