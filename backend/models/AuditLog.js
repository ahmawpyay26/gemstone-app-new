const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const AuditLog = sequelize.define('AuditLog', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  // User information
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    index: true
  },
  user_email: {
    type: DataTypes.STRING(255),
    allowNull: false
  },
  user_role: {
    type: DataTypes.ENUM('owner', 'accountant', 'worker', 'broker'),
    allowNull: false
  },

  // Action information
  action_type: {
    type: DataTypes.ENUM(
      'LOGIN',
      'LOGOUT',
      'CREATE',
      'UPDATE',
      'DELETE',
      'VIEW',
      'EXPORT',
      'IMPORT'
    ),
    allowNull: false,
    index: true
  },

  // Module/Entity information
  module_name: {
    type: DataTypes.ENUM(
      'USER',
      'GEMSTONE',
      'LOT',
      'EXPENSE',
      'SALE',
      'REPORT',
      'SETTINGS',
      'AUTH'
    ),
    allowNull: false,
    index: true
  },

  // Entity information
  entity_id: {
    type: DataTypes.UUID,
    allowNull: true,
    index: true
  },
  entity_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },

  // Change data
  before_value: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Previous values before the change'
  },
  after_value: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'New values after the change'
  },

  // Additional context
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Human-readable description of the action'
  },
  ip_address: {
    type: DataTypes.STRING(45),
    allowNull: true,
    comment: 'IPv4 or IPv6 address'
  },
  user_agent: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Browser user agent'
  },

  // Status
  status: {
    type: DataTypes.ENUM('SUCCESS', 'FAILURE', 'PARTIAL'),
    defaultValue: 'SUCCESS',
    allowNull: false
  },
  error_message: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Error message if action failed'
  },

  // Metadata
  metadata: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Additional metadata for the action'
  }
}, {
  tableName: 'audit_logs',
  timestamps: true,
  underscored: true,
  indexes: [
    {
      fields: ['user_id', 'created_at'],
      name: 'idx_audit_user_date'
    },
    {
      fields: ['module_name', 'action_type', 'created_at'],
      name: 'idx_audit_module_action_date'
    },
    {
      fields: ['entity_id', 'module_name'],
      name: 'idx_audit_entity'
    },
    {
      fields: ['created_at'],
      name: 'idx_audit_date'
    }
  ],
  comment: 'Audit trail for tracking all system activities and changes'
});

module.exports = AuditLog;
