# MiTienda - Aplicación Móvil de E-commerce

## Descripción General
MiTienda es una aplicación móvil de tienda online full-stack desarrollada como proyecto
de aprendizaje. Permite a los usuarios registrarse, iniciar sesión de forma segura,
explorar un catálogo de 12 productos con imágenes reales, agregar productos al carrito
de compras y gestionar su perfil personal.

---

## Arquitectura del Sistema

El proyecto sigue una arquitectura de tres capas:

    [App Flutter]  <-- HTTP/JWT -->  [Node.js + Express]  <-- SQL -->  [MySQL]
       Frontend                           Backend                   Base de Datos

| Capa          | Tecnologia        | Descripcion                            |
|---------------|-------------------|----------------------------------------|
| Frontend      | Flutter (Dart)    | Interfaz movil para Android            |
| Backend       | Node.js + Express | API REST con autenticacion JWT         |
| Base de Datos | MySQL 8.0         | Almacenamiento de usuarios y productos |

---

## Requisitos Previos

| Herramienta     | Version                          |
|-----------------|----------------------------------|
| Flutter SDK     | 3.x+                             |
| Android Studio  | Cualquiera con Flutter instalado |
| Node.js         | v18+                             |
| MySQL           | 8.0+                             |
| MySQL Workbench | 8.0+                             |

---

## Instalacion y Configuracion

### Paso 1 - Base de Datos
1. Abrir MySQL Workbench
2. Conectarse al servidor local (Local instance MySQL80)
3. Abrir un nuevo Query Tab
4. Ejecutar el archivo schema.sql completo
5. Verificar que se crearon las tablas usuarios y productos

### Paso 2 - Backend
1. Abrir PowerShell y navegar a la carpeta del backend:
   cd C:\Users\Usuario\Documents\tienda_backend

2. Instalar dependencias:
   npm install express bcrypt mysql2 dotenv cors jsonwebtoken

3. Abrir server.js y cambiar la contraseña de MySQL:
   password: 'tu_password'

4. Iniciar el servidor:
   node server.js

5. Verificar que aparece en consola:
   Servidor corriendo en http://localhost:3000

### Paso 3 - Aplicacion Movil
1. Abrir el proyecto tienda_app en Android Studio
2. En lib/main.dart verificar la URL del servidor:
    - Emulador Android: http://10.0.2.2:3000
    - Dispositivo fisico: http://192.168.2.31:3000
3. Seleccionar un emulador en el menu desplegable
4. Presionar el boton Run (triangulo verde)

---

## Estructura del Proyecto

    tienda_app/
      lib/
        main.dart                    Codigo completo de la app Flutter
      android/
        app/src/main/
          AndroidManifest.xml        Permisos de internet y configuracion

    tienda_backend/
      server.js                      Servidor Node.js con todos los endpoints
      package.json                   Dependencias del proyecto
      schema.sql                     Estructura completa de la base de datos

---

## Endpoints de la API

| Metodo | Ruta            | Descripcion                  | Autenticacion |
|--------|-----------------|------------------------------|---------------|
| POST   | /auth/login     | Iniciar sesion               | No requerida  |
| POST   | /auth/register  | Registrar nuevo usuario      | No requerida  |
| GET    | /products       | Obtener todos los productos  | JWT requerido |

---

## Credenciales de Prueba

- Email: test@tienda.com
- Contrasena: contrasena123

---

## Funcionalidades de la Aplicacion

- Login con autenticacion real contra base de datos MySQL
- Registro de nuevos usuarios desde la app
- Pantalla Home con catalogo de 12 productos en grid de 2 columnas
- Imagenes reales de productos cargadas desde Unsplash
- Pantalla de detalle por cada producto con descripcion completa
- Carrito de compras con contador en tiempo real
- Agregar y eliminar productos del carrito
- Total calculado automaticamente
- Pantalla de perfil con nombre y email del usuario
- Cerrar sesion con dialogo de confirmacion
- Validaciones de formulario en Login y Registro
- Manejo de errores y timeout de conexion

---

## Decisiones de Seguridad

| Aspecto             | Implementacion                                    |
|---------------------|---------------------------------------------------|
| Contrasenas         | Hasheadas con BCrypt (cost factor: 12)            |
| Almacenamiento      | NUNCA se guarda la contrasena original            |
| Autenticacion       | JWT (JSON Web Tokens) con expiracion de 24 horas |
| Endpoints           | /products protegido, solo accesible con JWT valido|
| Mensajes de error   | No revelan si el usuario existe o no              |
| Token expirado      | La app redirige automaticamente al Login          |

---

## Base de Datos

### Tabla usuarios
| Campo           | Tipo         | Descripcion                  |
|-----------------|--------------|------------------------------|
| id              | INT PK       | Identificador unico          |
| email           | VARCHAR(255) | Email unico del usuario      |
| nombre          | VARCHAR(100) | Nombre completo              |
| contrasena_hash | VARCHAR(255) | Hash BCrypt de la contrasena |
| fecha_creacion  | TIMESTAMP    | Fecha de registro            |
| esta_activo     | BOOLEAN      | Estado del usuario           |

### Tabla productos
| Campo           | Tipo          | Descripcion                  |
|-----------------|---------------|------------------------------|
| id              | INT PK        | Identificador unico          |
| nombre          | VARCHAR(200)  | Nombre del producto          |
| precio          | DECIMAL(10,2) | Precio del producto          |
| imagen_url      | TEXT          | URL de la imagen             |
| descripcion     | TEXT          | Descripcion del producto     |
| categoria       | VARCHAR(100)  | Categoria del producto       |
| calificacion    | DECIMAL(2,1)  | Calificacion del producto    |
| tiene_descuento | BOOLEAN       | Si tiene descuento activo    |
| activo          | BOOLEAN       | Si el producto esta activo   |

---

## Tecnologias Utilizadas

### Frontend
- Flutter 3.x
- Dart
- Paquete http 1.6.0 para peticiones HTTP

### Backend
- Node.js v24
- Express 4.x
- bcrypt (hashing de contrasenas)
- jsonwebtoken (autenticacion JWT)
- mysql2 (conexion a MySQL)
- cors (control de acceso)
- dotenv (variables de entorno)

---

## Autor
Proyecto desarrollado como entregable academico.
Curso: Desarrollo de Aplicaciones Moviles