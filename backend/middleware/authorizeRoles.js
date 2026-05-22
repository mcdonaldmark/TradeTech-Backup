const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: "Access denied" });
    }
    next();
  };
};

/*
 * ROLE CREATION RULES
 */
const rolePermissions = {
  user: ["user"],
  cashier: ["user"],
  manager: ["user", "cashier"],
  director: ["user", "cashier", "manager", "director"]
};

/*
 * Controls who can create what role
 */
const authorizeCreateRole = () => {
  return (req, res, next) => {
    const creatorRole = req.user.role;
    const targetRole = req.body.role;

    if (!creatorRole || !targetRole) {
      return res.status(400).json({ message: "Missing role information" });
    }

    const allowed = rolePermissions[creatorRole] || [];

    if (!allowed.includes(targetRole)) {
      return res.status(403).json({
        message: `${creatorRole} cannot create ${targetRole} accounts`
      });
    }

    next();
  };
};

module.exports = {
  authorizeRoles,
  authorizeCreateRole
};