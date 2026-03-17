import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

const _baseUrl = 'http://192.168.2.31:3000';

// ---- VALIDACIONES ----
String? validarEmail(String email) {
  if (email.isEmpty) return 'El email es requerido';
  final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
  if (!regex.hasMatch(email)) return 'Ingresa un email válido (ej: usuario@gmail.com)';
  return null;
}

String? validarContrasena(String contrasena) {
  if (contrasena.isEmpty) return 'La contraseña es requerida';
  if (contrasena.length < 8) return 'La contraseña debe tener mínimo 8 caracteres';
  return null;
}

String? validarNombre(String nombre) {
  if (nombre.isEmpty) return 'El nombre es requerido';
  if (nombre.trim().length < 3) return 'El nombre debe tener mínimo 3 caracteres';
  return null;
}

// ---- SESION (guarda datos del usuario + token JWT) ----
class Sesion {
  static String? nombre;
  static String? email;
  static int? id;
  static String? token;

  static void iniciar({
    required int id,
    required String nombre,
    required String email,
    required String token,
  }) {
    Sesion.id = id;
    Sesion.nombre = nombre;
    Sesion.email = email;
    Sesion.token = token;
  }

  static void cerrar() {
    id = null;
    nombre = null;
    email = null;
    token = null;
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${Sesion.token}',
  };
}

// ---- CARRITO ----
class Carrito extends ChangeNotifier {
  final List<Producto> _items = [];

  List<Producto> get items => _items;
  int get totalItems => _items.length;
  double get total => _items.fold(0, (sum, p) => sum + p.precio);

  void agregar(Producto p) { _items.add(p); notifyListeners(); }
  void eliminar(int index) { _items.removeAt(index); notifyListeners(); }
  void vaciar() { _items.clear(); notifyListeners(); }
}

final carrito = Carrito();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiTienda',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}

// ---- MODELO PRODUCTO ----
class Producto {
  final int id;
  final String nombre;
  final double precio;
  final String imagenUrl;
  final String descripcion;
  final bool tieneDescuento;

  Producto({required this.id, required this.nombre, required this.precio,
    required this.imagenUrl, required this.descripcion, this.tieneDescuento = false});

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
    id: j['id'], nombre: j['nombre'],
    precio: double.parse(j['precio'].toString()),
    imagenUrl: j['imagen_url'] ?? '',
    descripcion: j['descripcion'] ?? '',
    tieneDescuento: j['tiene_descuento'] == 1,
  );
}

// ---- PANTALLA DE LOGIN ----
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _login() async {
    final errorEmail = validarEmail(_emailCtrl.text.trim());
    if (errorEmail != null) { setState(() => _error = errorEmail); return; }
    final errorPass = validarContrasena(_passCtrl.text);
    if (errorPass != null) { setState(() => _error = errorPass); return; }

    setState(() { _cargando = true; _error = null; });
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim(), 'contrasena': _passCtrl.text}),
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw Exception('tardó'));

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200 && data['exito'] == true) {
        Sesion.iniciar(
          id: data['usuario']['id'],
          nombre: data['usuario']['nombre'],
          email: data['usuario']['email'],
          token: data['token'],
        );
        carrito.vaciar();
        if (mounted) Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _error = data['error'] ?? 'Error al iniciar sesión');
      }
    } catch (e) {
      setState(() => _error = e.toString().contains('tardó')
          ? 'El servidor tardó demasiado. Intenta de nuevo.'
          : 'Error de conexión. ¿El servidor está activo?');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.store, size: 80, color: Colors.blue),
            const SizedBox(height: 8),
            const Text('MiTienda', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email',
                    prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _login,
                  child: _cargando
                      ? const CircularProgressIndicator()
                      : const Text('Iniciar Sesión', style: TextStyle(fontSize: 18)),
                )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('¿No tienes cuenta? Regístrate',
                  style: TextStyle(fontSize: 16)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---- PANTALLA DE REGISTRO ----
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;
  String? _exito;

  Future<void> _registrar() async {
    final errorNombre = validarNombre(_nombreCtrl.text);
    if (errorNombre != null) { setState(() => _error = errorNombre); return; }
    final errorEmail = validarEmail(_emailCtrl.text.trim());
    if (errorEmail != null) { setState(() => _error = errorEmail); return; }
    final errorPass = validarContrasena(_passCtrl.text);
    if (errorPass != null) { setState(() => _error = errorPass); return; }

    setState(() { _cargando = true; _error = null; _exito = null; });
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': _nombreCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'contrasena': _passCtrl.text,
        }),
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw Exception('tardó'));

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 201 && data['exito'] == true) {
        setState(() => _exito = '¡Registro exitoso! Ya puedes iniciar sesión.');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _error = data['error'] ?? 'Error al registrarse');
      }
    } catch (e) {
      setState(() => _error = e.toString().contains('tardó')
          ? 'El servidor tardó demasiado. Intenta de nuevo.'
          : 'Error de conexión. ¿El servidor está activo?');
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 8),
            const Text('Crear Cuenta', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email',
                    prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passCtrl, obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Contraseña (mínimo 8 caracteres)',
                    prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_exito != null) ...[
              const SizedBox(height: 8),
              Text(_exito!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: _cargando ? null : _registrar,
                  child: _cargando
                      ? const CircularProgressIndicator()
                      : const Text('Registrarse', style: TextStyle(fontSize: 18)),
                )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('¿Ya tienes cuenta? Inicia Sesión',
                  style: TextStyle(fontSize: 16)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---- PANTALLA HOME ----
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Producto> _productos = [];
  bool _cargando = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    carrito.addListener(() { if (mounted) setState(() {}); });
  }

  Future<void> _cargarProductos() async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/products'),
        headers: Sesion.headers,
      );
      final data = jsonDecode(resp.body);

      if (resp.statusCode == 401 || resp.statusCode == 403) {
        if (mounted) {
          Sesion.cerrar();
          carrito.vaciar();
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
        return;
      }

      if (data['exito'] == true) {
        setState(() {
          _productos = (data['productos'] as List)
              .map((j) => Producto.fromJson(j)).toList();
          _cargando = false;
          _errorCarga = null;
        });
      }
    } catch (e) {
      setState(() {
        _cargando = false;
        _errorCarga = 'Error al cargar productos';
      });
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Sesion.cerrar();
              carrito.vaciar();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiTienda', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
              ),
              if (carrito.totalItems > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Text('${carrito.totalItems}',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              if (value == 'perfil') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'cerrar') {
                _cerrarSesion();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'perfil',
                child: Row(children: const [
                  Icon(Icons.person_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Mi Perfil'),
                ]),
              ),
              PopupMenuItem(
                value: 'cerrar',
                child: Row(children: const [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _errorCarga != null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorCarga!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _cargando = true; _errorCarga = null; });
                _cargarProductos();
              },
              child: const Text('Reintentar'),
            ),
          ]))
          : GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8,
              mainAxisSpacing: 8, childAspectRatio: 0.75),
          itemCount: _productos.length,
          itemBuilder: (ctx, i) {
            final p = _productos[i];
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(producto: p))),
              child: Card(elevation: 4, child: Column(children: [
                Expanded(child: Image.network(p.imagenUrl,
                    fit: BoxFit.cover, width: double.infinity,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 60))),
                Padding(padding: const EdgeInsets.all(8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text('\$${p.precio.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.blue,
                                  fontWeight: FontWeight.bold)),
                          if (p.tieneDescuento)
                            const Text('DESCUENTO',
                                style: TextStyle(color: Colors.red, fontSize: 12)),
                        ])),
              ])),
            );
          }),
    );
  }
}

// ---- PANTALLA PERFIL ----
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              Sesion.nombre != null ? Sesion.nombre![0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 48, color: Colors.blue,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Text(Sesion.nombre ?? 'Sin nombre',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(Sesion.email ?? 'Sin email',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Nombre'),
              subtitle: Text(Sesion.nombre ?? '-'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Email'),
              subtitle: Text(Sesion.email ?? '-'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.blue),
              title: const Text('Productos en carrito'),
              subtitle: Text('${carrito.totalItems} productos'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security, color: Colors.green),
              title: const Text('Sesión'),
              subtitle: const Text('Autenticado con JWT ✓'),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro que deseas cerrar sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Sesion.cerrar();
                          carrito.vaciar();
                          Navigator.pushAndRemoveUntil(context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (route) => false);
                        },
                        child: const Text('Cerrar Sesión',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Cerrar Sesión',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---- PANTALLA DETALLE ----
class ProductDetailScreen extends StatefulWidget {
  final Producto producto;
  const ProductDetailScreen({super.key, required this.producto});
  @override State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _agregado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.producto.nombre)),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Image.network(widget.producto.imagenUrl, height: 300,
              width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(height: 300,
                  child: Center(child: Icon(Icons.image, size: 80)))),
          Padding(padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.producto.nombre,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('\$${widget.producto.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, color: Colors.blue,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(widget.producto.descripcion, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        carrito.agregar(widget.producto);
                        setState(() => _agregado = true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.producto.nombre} agregado al carrito'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Ver carrito',
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const CartScreen())),
                            ),
                          ),
                        );
                      },
                      icon: Icon(_agregado ? Icons.check : Icons.shopping_cart),
                      label: Text(_agregado ? '¡Agregado!' : 'Agregar al Carrito'),
                    )),
              ])),
        ]),
      ),
    );
  }
}

// ---- PANTALLA CARRITO ----
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    carrito.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (carrito.totalItems > 0)
            TextButton(
              onPressed: () { carrito.vaciar(); setState(() {}); },
              child: const Text('Vaciar', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: carrito.items.isEmpty
          ? const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Tu carrito está vacío',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ]))
          : Column(children: [
        Expanded(
          child: ListView.builder(
            itemCount: carrito.items.length,
            itemBuilder: (ctx, i) {
              final p = carrito.items[i];
              return ListTile(
                leading: SizedBox(
                  width: 56, height: 56,
                  child: Image.network(p.imagenUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image)),
                ),
                title: Text(p.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('\$${p.precio.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.blue)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => carrito.eliminar(i),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total (${carrito.totalItems} productos)',
                  style: const TextStyle(fontSize: 16)),
              Text('\$${carrito.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20,
                      fontWeight: FontWeight.bold, color: Colors.blue)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    carrito.vaciar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Compra realizada con éxito!')),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Finalizar Compra',
                      style: TextStyle(fontSize: 18)),
                )),
          ]),
        ),
      ]),
    );
  }
}