const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const SaleItem = sequelize.define('SaleItem', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  sale_id: {
    type: DataTypes.UUID,
    allowNull: false
  },
  gemstone_id: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true
  },
  sale_price: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: false
  }
}, {
  tableName: 'sale_items',
  timestamps: false,
  underscored: true
});

module.exports = SaleItem;
