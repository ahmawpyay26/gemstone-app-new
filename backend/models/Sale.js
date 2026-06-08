const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Sale = sequelize.define('Sale', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  invoice_number: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true
  },
  customer_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  sale_date: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  total_amount: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false
  },
  broker_id: {
    type: DataTypes.UUID,
    allowNull: true
  },
  broker_commission: {
    type: DataTypes.DECIMAL(15, 2),
    defaultValue: 0
  },
  payment_status: {
    type: DataTypes.ENUM('pending', 'paid', 'partial'),
    defaultValue: 'paid'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  tableName: 'sales',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Sale;
