const AuditService = require('../services/audit.service');

/**
 * Middleware to automatically log API requests
 * Wraps the response to capture the result
 */
const auditMiddleware = (moduleName, actionType) => {
  return async (req, res, next) => {
    // Store original send function
    const originalSend = res.send;

    // Store request data for audit
    const auditData = {
      userId: req.user?.userId,
      userEmail: req.user?.email,
      userRole: req.user?.role,
      actionType,
      moduleName,
      ipAddress: req.ip || req.connection.remoteAddress,
      userAgent: req.get('user-agent'),
      description: `${actionType} operation on ${moduleName}`,
      metadata: {
        method: req.method,
        path: req.path,
        query: req.query,
        params: req.params
      }
    };

    // Override send to capture response
    res.send = function(data) {
      try {
        // Parse response
        let responseData = data;
        if (typeof data === 'string') {
          try {
            responseData = JSON.parse(data);
          } catch (e) {
            // Not JSON, keep as is
          }
        }

        // Determine status
        const statusCode = res.statusCode;
        auditData.status = statusCode >= 200 && statusCode < 300 ? 'SUCCESS' : 'FAILURE';
        if (statusCode >= 400) {
          auditData.errorMessage = responseData?.message || 'Operation failed';
        }

        // Log the audit event asynchronously (don't block response)
        AuditService.logAudit(auditData).catch(err => {
          console.error('Failed to log audit:', err);
        });
      } catch (error) {
        console.error('Error in audit middleware:', error);
      }

      // Call original send
      return originalSend.call(this, data);
    };

    next();
  };
};

/**
 * Middleware to log entity changes (before/after values)
 */
const auditEntityChangeMiddleware = (moduleName) => {
  return async (req, res, next) => {
    // Store original send function
    const originalSend = res.send;

    // Store request body for before values
    const beforeValue = req.body;

    // Override send to capture response
    res.send = function(data) {
      try {
        // Parse response
        let responseData = data;
        if (typeof data === 'string') {
          try {
            responseData = JSON.parse(data);
          } catch (e) {
            // Not JSON, keep as is
          }
        }

        // Only log on success
        if (res.statusCode >= 200 && res.statusCode < 300) {
          const auditData = {
            userId: req.user?.userId,
            userEmail: req.user?.email,
            userRole: req.user?.role,
            actionType: req.method === 'POST' ? 'CREATE' : req.method === 'PUT' ? 'UPDATE' : 'DELETE',
            moduleName,
            entityId: req.params.id || responseData?.data?.id,
            entityName: responseData?.data?.name || responseData?.data?.email,
            beforeValue: req.method !== 'POST' ? beforeValue : null,
            afterValue: responseData?.data || null,
            ipAddress: req.ip || req.connection.remoteAddress,
            userAgent: req.get('user-agent'),
            status: 'SUCCESS',
            description: `${req.method} operation on ${moduleName}`,
            metadata: {
              method: req.method,
              path: req.path,
              statusCode: res.statusCode
            }
          };

          // Log the audit event asynchronously
          AuditService.logAudit(auditData).catch(err => {
            console.error('Failed to log entity change audit:', err);
          });
        }
      } catch (error) {
        console.error('Error in entity change audit middleware:', error);
      }

      // Call original send
      return originalSend.call(this, data);
    };

    next();
  };
};

/**
 * Middleware to log login/logout events
 */
const auditAuthMiddleware = async (req, res, next) => {
  const originalSend = res.send;

  res.send = function(data) {
    try {
      let responseData = data;
      if (typeof data === 'string') {
        try {
          responseData = JSON.parse(data);
        } catch (e) {
          // Not JSON
        }
      }

      // Log login/logout
      if (res.statusCode >= 200 && res.statusCode < 300) {
        const auditData = {
          userId: responseData?.data?.user?.id || req.body?.email,
          userEmail: responseData?.data?.user?.email || req.body?.email,
          userRole: responseData?.data?.user?.role || 'unknown',
          actionType: req.path.includes('logout') ? 'LOGOUT' : 'LOGIN',
          moduleName: 'AUTH',
          ipAddress: req.ip || req.connection.remoteAddress,
          userAgent: req.get('user-agent'),
          status: 'SUCCESS',
          description: req.path.includes('logout') ? 'User logout' : 'User login',
          metadata: {
            method: req.method,
            path: req.path
          }
        };

        AuditService.logAudit(auditData).catch(err => {
          console.error('Failed to log auth audit:', err);
        });
      }
    } catch (error) {
      console.error('Error in auth audit middleware:', error);
    }

    return originalSend.call(this, data);
  };

  next();
};

module.exports = {
  auditMiddleware,
  auditEntityChangeMiddleware,
  auditAuthMiddleware
};
