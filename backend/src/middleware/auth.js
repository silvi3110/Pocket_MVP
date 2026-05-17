const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token requerido' });
  }
  try {
    req.user = jwt.verify(header.slice(7), process.env.JWT_SECRET || 'pocket_hackathon_secret');
    next();
  } catch {
    return res.status(401).json({ error: 'Token inválido' });
  }
}

module.exports = { authMiddleware };
