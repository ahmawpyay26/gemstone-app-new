const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Lot = sequelize.define('Lot', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  lot_number: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  total_carats: {
    type: DataTypes.DECIMAL(10, 3),
    allowNull: false
  },
  total_stones: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  purchase_price: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false
  },
  purchase_date: {
    type: DataTypes.DATE,
    allowNull: false
  },
  supplier_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('active', 'split', 'completed'),
    defaultValue: 'active'
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  tableName: 'lots',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Lot;
