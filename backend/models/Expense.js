const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Expense = sequelize.define('Expense', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  gemstone_id: {
    type: DataTypes.UUID,
    allowNull: false
  },
  expense_type: {
    type: DataTypes.STRING(100),
    allowNull: false // 'worker_cost', 'machine_oil', 'grinding_tool', etc.
  },
  amount: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  worker_id: {
    type: DataTypes.UUID,
    allowNull: true
  },
  machine_id: {
    type: DataTypes.UUID,
    allowNull: true
  },
  expense_date: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  tableName: 'expenses',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Expense;
