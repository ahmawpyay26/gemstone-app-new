const sequelize = require('../config/database');

exports.getProfitLossReport = async (req, res) => {
  try {
    const report = await sequelize.query(`
      SELECT 
        SUM(total_amount) as gross_sales,
        SUM(broker_commission) as total_commissions,
        (SELECT SUM(total_cost) FROM gemstones WHERE status = 'sold') as total_cost_of_goods,
        (SUM(total_amount) - SUM(broker_commission) - (SELECT SUM(total_cost) FROM gemstones WHERE status = 'sold')) as net_profit
      FROM sales
    `, { type: sequelize.QueryTypes.SELECT });

    res.status(200).json({ status: 'success', data: report[0] });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
};

exports.getInventorySummary = async (req, res) => {
  try {
    const summary = await sequelize.query(`
      SELECT status, COUNT(*) as count, SUM(carat_weight) as total_carats, SUM(total_cost) as total_value
      FROM gemstones
      GROUP BY status
    `, { type: sequelize.QueryTypes.SELECT });

    res.status(200).json({ status: 'success', data: summary });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
};
