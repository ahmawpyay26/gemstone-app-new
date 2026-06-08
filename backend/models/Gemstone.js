const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Gemstone = sequelize.define('Gemstone', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  qr_code: {
    type: DataTypes.STRING(100),
    allowNull: false,
    unique: true
  },
  type: {
    type: DataTypes.STRING(100),
    allowNull: false
  },
  carat_weight: {
    type: DataTypes.DECIMAL(10, 3),
    allowNull: false
  },
  cut: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  color: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  clarity: {
    type: DataTypes.STRING(50),
    allowNull: true
  },
  shape: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  dimensions: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  origin: {
    type: DataTypes.STRING(100),
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('raw', 'in_process', 'polished', 'sold', 'waste', 'damaged'),
    defaultValue: 'raw'
  },
  current_location: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  purchase_price: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: true
  },
  purchase_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  total_cost: {
    type: DataTypes.DECIMAL(15, 2),
    allowNull: true
  },
  lot_id: {
    type: DataTypes.UUID,
    allowNull: true
  },
  created_by: {
    type: DataTypes.UUID,
    allowNull: false
  }
}, {
  tableName: 'gemstones',
  timestamps: true,
  underscored: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at'
});

module.exports = Gemstone;
