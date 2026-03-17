const express = require('express');
const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
const cors = require('cors');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use(cors());

// Clave secreta para firmar los tokens (en producción debe ir en .env)
const JWT_SECRET = 'mitienda_secreto_super_seguro_2024';

// Conexion a MySQL
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',
  password: 'root1234',
  database: 'tienda_db'
});

// ---- MIDDLEWARE: verificar token ----
function verificarToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // formato: "Bearer TOKEN"

  if (!token) {
    return res.status(401).json({ exito: false, error: 'Acceso denegado. Inicia sesión.' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.usuario = decoded;
    next();
  } catch (e) {
    return res.status(403).json({ exito: false, error: 'Token inválido o expirado.' });
  }
}

// ---- LOGIN ----
app.post('/auth/login', async (req, res) => {
  try {
    const { email, contrasena } = req.body;
    if (!email || !contrasena)
      return res.status(400).json({ exito: false, error: 'Faltan datos' });

    const [rows] = await pool.query(
      'SELECT * FROM usuarios WHERE email = ? AND esta_activo = 1',
      [email.toLowerCase().trim()]
    );

    if (rows.length === 0)
      return res.status(401).json({ exito: false, error: 'Credenciales incorrectas' });

    const usuario = rows[0];
    const esCorrecta = await bcrypt.compare(contrasena, usuario.contrasena_hash);

    if (!esCorrecta)
      return res.status(401).json({ exito: false, error: 'Credenciales incorrectas' });

    // Generar token JWT (expira en 24 horas)
    const token = jwt.sign(
      { id: usuario.id, email: usuario.email, nombre: usuario.nombre },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.status(200).json({
      exito: true,
      mensaje: 'Login exitoso',
      token: token, // enviamos el token al cliente
      usuario: { id: usuario.id, email: usuario.email, nombre: usuario.nombre }
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ exito: false, error: 'Error interno' });
  }
});

// ---- REGISTRO ----
app.post('/auth/register', async (req, res) => {
  try {
    const { email, nombre, contrasena } = req.body;
    if (!email || !nombre || !contrasena)
      return res.status(400).json({ exito: false, error: 'Faltan datos' });

    const hash = await bcrypt.hash(contrasena, 12);
    await pool.query(
      'INSERT INTO usuarios (email, nombre, contrasena_hash) VALUES (?, ?, ?)',
      [email.toLowerCase().trim(), nombre, hash]
    );
    return res.status(201).json({ exito: true, mensaje: 'Usuario registrado' });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY')
      return res.status(409).json({ exito: false, error: 'El email ya existe' });
    return res.status(500).json({ exito: false, error: 'Error interno' });
  }
});

// ---- PRODUCTOS (protegido con JWT) ----
app.get('/products', verificarToken, async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM productos WHERE activo = 1');
    return res.status(200).json({ exito: true, productos: rows });
  } catch (e) {
    return res.status(500).json({ exito: false, error: 'Error al obtener productos' });
  }
});

app.listen(3000, '0.0.0.0', () => console.log('Servidor corriendo en http://localhost:3000'));